"""文本翻译（原文 -> 译文），跑在 CTranslate2 上。

和 whisper 的 translate 任务的**根本区别**：whisper 是拿着同一段音频再解码一遍，
识别得再准也帮不上译文；这里是拿识别出来的**文本**去翻，所以识别用准的模型，
收益会直接落到译文上。用户改过原文之后重翻，也只有这条路做得到。

用 CTranslate2 而不是 transformers 跑推理：依赖小、int8 快好几倍。
但**分词交给谁**要分情况，这里踩过一次大坑：

- Marian（opus-mt）：分词规则简单，用原始 sentencepiece 就行——但**必须自己补 `</s>`**。
  漏了它不报错，只是译文整个退化成打转（"each end on each keyboard on each…"）。
- NLLB：分词带语言标记、特殊 token 顺序还随 transformers 版本变过。这种别手搓，
  直接用 HF 的 tokenizer，正确性交给上游。
"""

import os
from typing import Any, Dict, List, Optional

_translators: Dict[str, Any] = {}


class TextMtError(Exception):
    pass


def _need(path: str, what: str) -> str:
    if not path or not os.path.exists(path):
        raise TextMtError(f"{what} not found: {path}")
    return path


def _ct2(model_dir: str, cfg: Dict[str, Any], num_threads: int):
    try:
        import ctranslate2
    except ImportError as e:
        raise TextMtError(
            "文本翻译需要 ctranslate2，还没装。"
            "在 server/ai 下跑：pip install -r requirements-mt.txt"
        ) from e
    d = _need(os.path.join(model_dir, cfg.get("ct2", "ct2")), "ct2 目录")
    try:
        return ctranslate2.Translator(d, device="cpu", inter_threads=1,
                                      intra_threads=num_threads)
    except RuntimeError as e:
        # 模型文件损坏/不完整（下了一半、转换中断）。这是"模型坏了去修"，
        # 不是"服务端挂了"——必须走 400，否则手机会误判成服务不可用去回退本地。
        raise TextMtError(
            f"翻译模型加载失败（{e}）。多半是文件不完整，"
            f"删掉 {model_dir} 重新跑 python setup_mt.py"
        ) from e


class _Base:
    def __init__(self, model_dir: str, cfg: Dict[str, Any], num_threads: int):
        self._t = _ct2(model_dir, cfg, num_threads)
        self._max_len = int(cfg.get("maxDecodingLength", 256))

    def _cap(self, n_tokens: int) -> int:
        """译文长度按原文长度封顶，别给退化循环无限空间。

        实测过一次：7 个字的原文译出几百个词，kokoro 花 27.7 秒念完，
        一段 1.9 秒的话总耗时 31.7 秒。3 倍余量对中译英够宽松（中文字比英文词密）。
        """
        return min(self._max_len, max(24, n_tokens * 3))

    def _run(self, source: List[str], target_prefix: Optional[List[str]] = None) -> List[str]:
        res = self._t.translate_batch(
            [source],
            max_decoding_length=self._cap(len(source)),
            beam_size=4,
            target_prefix=None if target_prefix is None else [target_prefix],
            # 温和的兜底。真正治本的是各自分词器里的特殊 token。
            # 不用 no_repeat_ngram_size：实测它会改动**正确**的译文，
            # 「很好很好非常好」本该是 "Good, good, good, good."，被它砍成三个。
            repetition_penalty=1.1,
        )
        return res[0].hypotheses[0] if res and res[0].hypotheses else []


class MarianSpmTranslator(_Base):
    """opus-mt 系列。原始 sentencepiece + 手动补 </s>。"""

    def __init__(self, model_dir: str, cfg: Dict[str, Any], num_threads: int):
        super().__init__(model_dir, cfg, num_threads)
        try:
            import sentencepiece
        except ImportError as e:
            raise TextMtError("缺 sentencepiece：pip install -r requirements-mt.txt") from e
        self._sp_src = sentencepiece.SentencePieceProcessor(
            model_file=_need(os.path.join(model_dir, cfg.get("spmSource", "source.spm")), "source.spm"))
        tgt = os.path.join(model_dir, cfg.get("spmTarget", "target.spm"))
        # Marian 的目标端有自己的 spm，解码回文本要用它；缺了就退回源端那个
        self._sp_tgt = (sentencepiece.SentencePieceProcessor(model_file=tgt)
                        if os.path.exists(tgt) else self._sp_src)

    def translate(self, text: str) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        # Marian 要求源序列末尾有 </s>。HF 的 MarianTokenizer 会自动补，而这里是拿
        # 原始 sentencepiece 编码的，必须自己补上。
        #
        # 漏了它的后果不是报错，是**译文完全退化**——encoder 看到一个"没结束"的句子，
        # decoder 就停不下来：「这个键盘有霉斑」译成
        #   "This keyboard with this keyboard with a carycided ecretsy this keyboardboard."
        # 补上之后是
        #   "There's a mold on this keyboard."
        # 一个 token 的差别。别删。
        source = self._sp_src.encode(text, out_type=str) + ["</s>"]
        if len(source) <= 1:
            return ""
        return self._sp_tgt.decode(self._run(source)).strip()


class HfTokenizerTranslator(_Base):
    """NLLB 之类分词规则复杂的模型：分词全交给 HF tokenizer。

    NLLB 的源序列要带语言标记，目标端要用语言标记当 target_prefix，
    而这些特殊 token 的顺序在 transformers 各版本间变过。手搓一次就够了
    （见上面 Marian 那个 </s> 的教训），这里让上游负责。
    """

    def __init__(self, model_dir: str, cfg: Dict[str, Any], num_threads: int):
        super().__init__(model_dir, cfg, num_threads)
        try:
            from transformers import AutoTokenizer
        except ImportError as e:
            raise TextMtError(
                "这个翻译模型的分词器要 transformers，还没装。"
                "在 server/ai 下跑：pip install -r requirements-mt.txt"
            ) from e
        self._tgt_lang = cfg.get("tgtLang", "eng_Latn")
        self._tok = AutoTokenizer.from_pretrained(
            model_dir, src_lang=cfg.get("srcLang", "zho_Hans"))

    def translate(self, text: str) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        source = self._tok.convert_ids_to_tokens(self._tok.encode(text))
        out = self._run(source, target_prefix=[self._tgt_lang])
        # 第一个 token 是我们自己塞进去的语言标记，去掉
        if out and out[0] == self._tgt_lang:
            out = out[1:]
        return self._tok.decode(self._tok.convert_tokens_to_ids(out),
                                skip_special_tokens=True).strip()


def _build(model_dir: str, cfg: Dict[str, Any], num_threads: int):
    kind = cfg.get("tokenizer", "marian-spm")
    if kind == "hf":
        return HfTokenizerTranslator(model_dir, cfg, num_threads)
    if kind == "marian-spm":
        return MarianSpmTranslator(model_dir, cfg, num_threads)
    raise TextMtError(f"不认识的分词器类型: {kind}")


def get(model_id: str, model_dir: str, cfg: Dict[str, Any], num_threads: int):
    t = _translators.get(model_id)
    if t is None:
        t = _build(model_dir, cfg, num_threads)
        _translators[model_id] = t
    return t


def drop_cache(model_id: Optional[str] = None) -> None:
    if model_id is None:
        _translators.clear()
    else:
        _translators.pop(model_id, None)


def installed() -> List[str]:
    return list(_translators)
