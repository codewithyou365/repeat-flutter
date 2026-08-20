"""文本 -> 音素，以及音素 -> 模型词表 id。

两件事都很容易"静默地错"，所以这个文件的注释密度偏高。

**为什么不用 Wav2Vec2Processor / Wav2Vec2PhonemeCTCTokenizer**：
那个 tokenizer 内部会用它自己的 espeak 配置**再跑一遍** g2p，配置和我们这边
对不齐时不会报错，只会给出错位的音素序列——正好制造我们最想避免的失配。
而且 transformers 5.x 这两个类的 API 变动大。词表就是个 392 项的 json，
自己解析确定性更高。
"""

import functools
import json
import os
import re
from typing import Dict, List, Tuple


class G2pError(Exception):
    """文本转音素失败。会被 server.py 转成 400。"""


# 词表里这些不是音素，选 GOP 的 max 时要排除，切分时也不能匹配到。
SPECIALS = {"<pad>", "<s>", "</s>", "<unk>", "|"}

_backends: Dict[str, object] = {}
_espeak_ready = False


def _ensure_espeak() -> None:
    """把 espeakng-loader 带的动态库指给 phonemizer。

    必须在构造 EspeakBackend **之前**做，否则 phonemizer 会去找系统 espeak-ng，
    在没 brew install 过的机器上直接抛 RuntimeError。
    """
    global _espeak_ready
    if _espeak_ready:
        return
    try:
        import espeakng_loader
        from phonemizer.backend.espeak.wrapper import EspeakWrapper
    except ImportError as e:
        raise G2pError(
            f"缺 {e.name}。跑：pip install -r requirements.txt "
            f"-i https://mirrors.aliyun.com/pypi/simple"
        ) from e

    EspeakWrapper.set_library(espeakng_loader.get_library_path())
    EspeakWrapper.set_data_path(espeakng_loader.get_data_path())
    _espeak_ready = True


def _backend(lang: str):
    if lang in _backends:
        return _backends[lang]
    _ensure_espeak()
    from phonemizer.backend import EspeakBackend

    try:
        b = EspeakBackend(
            lang,
            # 词表里根本没有 ˈ / ˌ，带上重音符号只会让后面的切分全部落空。
            with_stress=False,
            preserve_punctuation=False,
            # espeak 会给"看着像外语"的词打 (en) / (fr) 这种语言切换标记，
            # 不去掉的话它们会当成音素字符混进结果里。
            language_switch="remove-flags",
        )
    except RuntimeError as e:
        raise G2pError(f"espeak 不支持语言 {lang}：{e}") from e
    _backends[lang] = b
    return b


def espeak_version() -> str:
    try:
        _ensure_espeak()
        from phonemizer.backend.espeak.wrapper import EspeakWrapper
        return str(EspeakWrapper().version)
    except Exception:
        return ""


# 拆词：字母、数字、词内的撇号和连字符算词的一部分。
# 数字会被 espeak 展开成 "twenty twenty-four" 那样的多个词的音，
# 但它仍然是一个 token，作为一个词块整体着色——这是我们要的。
_WORD_RE = re.compile(r"[A-Za-z0-9’'-]+")


@functools.lru_cache(maxsize=512)
def phonemize_words(text: str, lang: str = "en-us") -> Tuple[Tuple[str, str], ...]:
    """('词面', 'IPA串') 的序列。

    **逐词传 list，不整句传再靠分隔符切**：espeak 会自己重新分块（phonemizer 里
    那套 words_mismatch 机制就是为此存在的），词分组错位会让每个词的颜色都归错，
    而且是静默出错，肉眼极难发现。传 list 进去是 1:1 对应，由构造保证。

    代价是丢了跨词上下文：'the' 永远是 ðə 不会在元音前变 ði，'read' 只会取一种读音。
    对短句跟读可以接受，真要改用整句模式的话在这里加分支。
    """
    words = _WORD_RE.findall(text or "")
    if not words:
        raise G2pError("这一条没有可跟读的文本")

    b = _backend(lang)
    try:
        ipa = b.phonemize(words, strip=True, njobs=1)
    except Exception as e:
        raise G2pError(f"espeak 转音素失败：{e}") from e

    out = []
    for w, p in zip(words, ipa):
        p = (p or "").strip()
        if p:
            out.append((w, p))
    if not out:
        raise G2pError("espeak 没能给出任何音素，检查文本语言是否和 lang 匹配")
    return tuple(out)


class PhoneMapper:
    """把 espeak 的 IPA 串切成模型词表里的 token。

    词表里的音素 token 长度 1~4 个字符（tʃ dʒ aɪ oʊ iː ɜː 这类多字符符号），
    所以必须最长匹配，不能按字符切。
    """

    def __init__(self, vocab: Dict[str, int]):
        self.vocab = vocab
        self.phone_tokens = [t for t in vocab if t not in SPECIALS]
        if not self.phone_tokens:
            raise G2pError("词表里一个音素都没有，vocab.json 是不是坏了")
        self.maxlen = max(len(t) for t in self.phone_tokens)
        # 词表里出现过的全部字符。剥离集合从词表**反推**，不硬编码一张
        # "要去掉 ˈ ˌ ͡ ̩ ..." 的表——硬编码在换模型时会静默失配。
        self.charset = set("".join(self.phone_tokens))
        self.phone_ids = sorted(vocab[t] for t in self.phone_tokens)

    def strip_unknown(self, s: str) -> str:
        return "".join(c for c in s if c in self.charset)

    def split(self, ipa: str) -> Tuple[List[str], List[str]]:
        """IPA 串 -> (切出的 token 列表, 切不动的字符列表)。

        **用 DP 求全局最优切分，不能用贪心最长匹配。**

        实测踩到的坑：'bjuːɾɪfəl'（beautiful）里，词表同时有 'ju' 和 'uː'
        但没有 'juː'。贪心在 j 处会拿走更长的 'ju'，剩下一个孤零零的 'ː'
        谁也匹配不上，于是 beautiful 少了一个音、还多报一个 unmappedPhones。
        而模型自己解码出来的是 'b j uː ɾ ɪ f əl'——贪心切错了。

        目标函数：先让切不动的字符最少，再让 token 数最少。
        这样 'j'+'uː'（0 个切不动）就会赢过 'ju'+孤立的 'ː'（1 个切不动）。
        """
        s = self.strip_unknown(ipa)
        n = len(s)
        if n == 0:
            return [], []

        INF = float("inf")
        # best[i] = 从位置 i 到结尾的 (切不动字符数, token 数)
        best: List[Tuple[float, float]] = [(INF, INF)] * (n + 1)
        # take[i] = 在位置 i 吃掉几个字符；0 表示这个字符切不动，跳过
        take: List[int] = [0] * (n + 1)
        best[n] = (0.0, 0.0)

        for i in range(n - 1, -1, -1):
            # 选项 A：这个字符切不动，跳过它
            cand_bad, cand_tok = best[i + 1]
            bi, ti, ki = cand_bad + 1, cand_tok, 0
            # 选项 B：吃掉长度 L 的一个 token
            for L in range(1, min(self.maxlen, n - i) + 1):
                piece = s[i:i + L]
                if piece not in self.vocab or piece in SPECIALS:
                    continue
                nb, nt = best[i + L]
                if nb == INF:
                    continue
                if (nb, nt + 1) < (bi, ti):
                    bi, ti, ki = nb, nt + 1, L
            best[i], take[i] = (bi, ti), ki

        toks: List[str] = []
        bad: List[str] = []
        i = 0
        while i < n:
            k = take[i]
            if k == 0:
                # 切不动。**绝不塞 <unk>**：它没有有意义的后验质量，
                # 塞进对齐目标会同时污染路径和 GOP。记下来往前走一格，
                # 让失配以 unmappedPhones 的形式暴露出去，而不是默默扣分。
                bad.append(s[i])
                i += 1
            else:
                toks.append(s[i:i + k])
                i += k
        return toks, bad


@functools.lru_cache(maxsize=4)
def load_vocab(model_dir: str) -> Dict[str, int]:
    p = os.path.join(model_dir, "vocab.json")
    if not os.path.exists(p):
        raise G2pError(f"词表不在：{p}")
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def prepare(text: str, model_dir: str, lang: str = "en-us"):
    """跑完整条 文本 -> 对齐目标 的链路。

    返回 (phone_ids, word_of, words, phone_syms, unmapped)：
      phone_ids  每个音素在词表里的 id，就是强制对齐的目标序列 y
      word_of    每个音素属于第几个词，用来把逐音素分聚合回逐词分
      words      词面，给 UI 显示
      phone_syms 每个音素的 IPA 符号，给 UI 显示
      unmapped   切不动的字符，非空说明 espeak 和词表有失配
    """
    pairs = phonemize_words(text, lang)
    mapper = PhoneMapper(load_vocab(model_dir))

    phone_ids: List[int] = []
    word_of: List[int] = []
    phone_syms: List[str] = []
    words: List[str] = []
    unmapped: List[str] = []

    for w, ipa in pairs:
        toks, bad = mapper.split(ipa)
        unmapped.extend(bad)
        if not toks:
            # 整个词都切不出音素，跳过它——留着会让 word_of 指向一个
            # 永远拿不到分的空词，UI 上就是一个莫名其妙的灰块。
            continue
        wi = len(words)
        words.append(w)
        for t in toks:
            phone_ids.append(mapper.vocab[t])
            phone_syms.append(t)
            word_of.append(wi)

    if not phone_ids:
        raise G2pError("这段文本切不出任何模型认识的音素，检查语言是否匹配")

    return phone_ids, word_of, words, phone_syms, unmapped
