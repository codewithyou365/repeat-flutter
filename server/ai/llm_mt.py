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
import threading
from typing import Any, Dict, List, Optional

_engines: Dict[str, Any] = {}
_lock = threading.Lock()

# 让它只吐译文，不要解释、不要引号、不要"Translation:"前缀。
# 短句最容易被 LLM 当成聊天去回应，所以说得死一点。
SYSTEM = ("You are a professional translator. Translate the user's text into {lang}. "
          "Output ONLY the translation itself: no quotes, no explanations, no notes, "
          "no romanization. Keep the tone and register of the original. "
          "If the text is already in {lang}, output it unchanged.")

LANG_NAMES = {"en": "English", "zh": "Chinese", "ja": "Japanese", "ko": "Korean"}


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
        # MLX 的计算图和数组不是线程安全的，翻译又是最快的一档，串行没损失
        self._lock = threading.Lock()

    def _prompt(self, text: str) -> str:
        lang = LANG_NAMES.get(self._target, self._target)
        msgs = [{"role": "system", "content": SYSTEM.format(lang=lang)},
                {"role": "user", "content": text}]
        return self._tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True)

    def translate(self, text: str) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        from mlx_lm import generate
        prompt = self._prompt(text)
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
