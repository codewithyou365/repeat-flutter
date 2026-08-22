"""用 LLM 做翻译，跑在 MLX 上（Apple Silicon 的 GPU）。

为什么要它：NMT 小模型（opus-mt / NLLB-600M）会把**复合词拆成单字直译**，
而且不懂习语。实测：

    这个魔方非常有趣   NLLB -> "The devil is so funny."      魔方 拆成 魔+方
    你近视多少度啊     两个都 -> "How close do you look?"     近视 拆成 近+视

这类错误换更大的 NMT 收益有限——它们的训练目标就不是理解。LLM 是中文母语语料训出来的，
这两句基本不会错。

为什么用 MLX 而不是 torch/CT2：MLX 是苹果自家的框架，直接跑 GPU。这才是这台机器上
真正能用的"苹果加速"——当初试 CoreML 跑 int8 ONNX 是**负优化**（慢 5 倍，见 README），
那条路和这条完全不同。

代价：只能在 Apple Silicon 上跑。别的平台会明确报错，不会静默降级。
"""

import os
import re
import threading
from typing import Any, Dict, List, Optional

_engines: Dict[str, Any] = {}
_lock = threading.Lock()

# 让它只吐译文，不要解释、不要引号、不要"Translation:"前缀。
# 短句最容易被 LLM 当成聊天去回应，所以说得死一点。
SYSTEM = ("You are a professional translator. Translate the user's text into {lang}. "
          "Output ONLY the translation itself: no quotes, no explanations, no notes, "
          "no romanization. Keep the tone and register of the original. "
          "If the text is already in {lang}, output it unchanged.\n"
          "The input is speech-recognition output of casual spoken language: it has no "
          "punctuation, may be a sentence fragment, and may contain misheard words. "
          "Translate what the speaker most likely meant; never comment on it, never ask "
          "for clarification, never leave a word untranslated because it looks odd.\n"
          "The output MUST be entirely in {lang}. Never mix languages, and never copy "
          "characters from the source text into the output.")

LANG_NAMES = {"en": "English", "zh": "Chinese", "ja": "Japanese", "ko": "Korean"}

# 出口重试用的追加指令。第一遍夹了源语言字符时，把那一遍的产物摆出来再让它重来一次。
REPAIR = ("Your previous output still contained source-language characters: {bad}\n"
          "Rewrite it entirely in {lang}. Output only the rewritten translation.")

# 少量示例，只在译到英文时挂上。
#
# 为什么要它：这几句都是**口语短句**，最容易被 LLM 当成聊天去回应，或者半译半抄。
# 摆两三个例子比在 system 里多写两句管用得多——它锁的是"输出形状"，不是道理。
FEWSHOT_EN = [
    ("我要举高高", "Lift me up high!"),
    ("这个插孔好像是有问题", "This outlet seems to be faulty."),
    ("嗯那个啥先这样吧", "Um, whatever, let\'s leave it at that."),
]

# 翻译专用模型（腾讯混元 Hunyuan-MT / Hy-MT2）的 prompt。
#
# 它们**不吃 system role，也不吃 few-shot**：官方用法就是一条 user 消息，
# 指令和原文写在一起。给它套通用 LLM 那一套（FEWSHOT_EN 那种多轮对话）
# 只会让它跑偏——训练时就没见过那个形状。所以这里单开一条 style 分支，
# 而不是想办法把两种 prompt 揉成一个。
HUNYUAN_TMPL = "将以下文本翻译为{lang}，注意只需要输出翻译后的结果，不要额外解释：\n\n{text}"

# 混元的 prompt 是中文的，语言名也得用中文，写 "English" 它认得但不如中文稳
HUNYUAN_LANG = {"en": "英语", "zh": "中文", "ja": "日语", "ko": "韩语"}

# 夹了源语言字符时重来一遍。追加在同一条 user 消息后面——这类模型多轮对话
# 也没怎么训过，不如把要求一次说完。
HUNYUAN_REPAIR = "\n\n（注意：上一次的结果里夹着原文的字「{bad}」。整句都必须是{lang}。）"

# 中日韩统一表意文字 + 常用扩展 + 假名 + 谚文。译到英文时输出里出现这些就是没译干净。
_CJK = re.compile(r"[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uac00-\ud7af]")


def _leftover(s: str, target: str) -> str:
    """输出里残留的源语言字符。译到 CJK 语言时这个检查没意义，返回空。"""
    if target not in ("en",):
        return ""
    return "".join(dict.fromkeys(_CJK.findall(s)))


class LlmMtError(Exception):
    pass


class MlxTranslator:
    def __init__(self, model_dir: str, cfg: Dict[str, Any]):
        try:
            from mlx_lm import load
        except ImportError as e:
            raise LlmMtError(
                "LLM 翻译要 mlx-lm（只支持 Apple Silicon），还没装。在 server/ai 下跑：\n"
                "  pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple"
            ) from e
        if not os.path.isdir(model_dir):
            raise LlmMtError(f"模型目录不在: {model_dir}")
        try:
            self._model, self._tok = load(model_dir)
        except Exception as e:
            raise LlmMtError(f"加载失败（{e}）。文件可能不完整，重新跑 setup_mt.py --model qwen") from e
        self._max_tokens = int(cfg.get("maxTokens", 256))
        self._target = cfg.get("tgtLang", "en")
        # prompt 的形状。通用 chat 模型和翻译专用模型的用法完全不同，见 HUNYUAN_TMPL。
        self._style = cfg.get("promptStyle", "chat")
        # MLX 的计算图和数组不是线程安全的，翻译又是最快的一档，串行没损失
        self._lock = threading.Lock()

    def _prompt(self, text: str, repair: Optional[str] = None) -> str:
        """一轮对话的完整 prompt。repair 非空表示这是重来一遍，把上一遍的产物摆进去。"""
        if self._style == "hunyuan-mt":
            return self._prompt_hunyuan(text, repair)
        lang = LANG_NAMES.get(self._target, self._target)
        msgs: List[Dict[str, str]] = [{"role": "system", "content": SYSTEM.format(lang=lang)}]
        if self._target == "en":
            for src, dst in FEWSHOT_EN:
                msgs.append({"role": "user", "content": src})
                msgs.append({"role": "assistant", "content": dst})
        msgs.append({"role": "user", "content": text})
        if repair is not None:
            msgs.append({"role": "assistant", "content": repair})
            msgs.append({"role": "user", "content": REPAIR.format(
                bad=_leftover(repair, self._target), lang=lang)})
        return self._tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True)

    def _prompt_hunyuan(self, text: str, repair: Optional[str]) -> str:
        lang = HUNYUAN_LANG.get(self._target, self._target)
        body = HUNYUAN_TMPL.format(lang=lang, text=text)
        if repair is not None:
            body += HUNYUAN_REPAIR.format(bad=_leftover(repair, self._target), lang=lang)
        msgs = [{"role": "user", "content": body}]
        return self._tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True)

    def translate(self, text: str) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        out = self._once(self._prompt(text))
        # 出口校验：夹了源语言字符就摆给它看，让它整句重来一遍。
        # 只重试一次——两遍都夹的话多半是输入本身就没法译（识别成了乱码），
        # 再转圈只是白等，把第二遍的结果交出去让用户在复核页改。
        if _leftover(out, self._target):
            out = self._once(self._prompt(text, repair=out)) or out
        return out

    def _once(self, prompt: str) -> str:
        from mlx_lm import generate
        with self._lock:
            # mlx-lm 的 generate 签名跨版本变过（sampler / temp 参数进出过好几轮）。
            # 挨个试比锁死一个版本强——装了新版也不该炸。
            out = None
            errs: List[str] = []
            for kwargs in (
                {"max_tokens": self._max_tokens, "verbose": False},
                {"max_tokens": self._max_tokens},
                {},
            ):
                try:
                    out = generate(self._model, self._tok, prompt=prompt, **kwargs)
                    break
                except TypeError as e:
                    errs.append(f"{kwargs}: {e}")
            if out is None:
                raise LlmMtError("mlx_lm.generate 签名不认识：\n  " + "\n  ".join(errs))
        return _clean(out)


def _clean(s: str) -> str:
    """LLM 偶尔还是会加壳，剥掉最常见的几种。"""
    s = (s or "").strip()
    for pre in ("Translation:", "翻译：", "译文：", "English:"):
        if s.lower().startswith(pre.lower()):
            s = s[len(pre):].strip()
    # 整句被引号包起来的情况（前后都有才剥，免得误伤句内引号）
    if len(s) >= 2 and s[0] in "\"'“「" and s[-1] in "\"'”」":
        s = s[1:-1].strip()
    return s.strip()


def get(model_id: str, model_dir: str, cfg: Dict[str, Any]) -> MlxTranslator:
    e = _engines.get(model_id)
    if e is not None:
        return e
    with _lock:
        e = _engines.get(model_id)
        if e is None:
            e = MlxTranslator(model_dir, cfg)
            _engines[model_id] = e
        return e


def drop_cache(model_id: Optional[str] = None) -> None:
    with _lock:
        if model_id is None:
            _engines.clear()
        else:
            _engines.pop(model_id, None)
