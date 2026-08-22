"""语音识别跑在 mlx-audio 上（Qwen3-ASR，苹果 GPU）。

和 [mlx_asr] 的区别是**运行时不是一个包**：那边是 mlx-whisper，只认 whisper 的
权重布局；Qwen3-ASR 是 Qwen3-Omni 底座的 ASR，得用 mlx-audio 加载。两个包互不相干，
所以单开一个模块，而不是往 mlx_asr 里塞分支。

为什么要它：whisper 和 paraformer 都只见过普通话，四川话这类方言只能当"带口音的
普通话"硬认，出来的原文是病句——而译文再好也救不回一句本来就识别错的话。
Qwen3-ASR 官方支持 30 种语言 + 22 种中国方言（四川话在列），且自带语种判断，
普通话和方言混着说不用切档。

只能在 Apple Silicon 上跑。别的平台会明确报错，不静默降级。
"""

import os
import threading
from typing import Any, Dict, Optional

import numpy as np

_engines: Dict[str, Any] = {}
_lock = threading.Lock()

# mlx-audio 的 Qwen3-ASR 要的是**语言全名**（get_supported_languages() 返回
# ['chinese', 'english', ...]），不是我们内部用的 ISO 码。方言不在这张表里——
# 四川话仍然报 chinese，具体是哪种方言由模型自己判。
LANG_NAMES = {
    "zh": "chinese",
    "en": "english",
    "yue": "cantonese",
    "ja": "japanese",
    "ko": "korean",
    "de": "german",
    "es": "spanish",
    "fr": "french",
    "it": "italian",
    "pt": "portuguese",
    "ru": "russian",
}


class MlxAudioAsrError(Exception):
    pass


class Qwen3Asr:
    def __init__(self, model_dir: str, cfg: Dict[str, Any]):
        try:
            from mlx_audio.stt.utils import load_model
        except ImportError as e:
            raise MlxAudioAsrError(
                "Qwen3-ASR 要 mlx-audio（只支持 Apple Silicon），还没装。在 server/ai 下跑：\n"
                "  pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple"
            ) from e
        if not os.path.isdir(model_dir):
            raise MlxAudioAsrError(f"模型目录不在: {model_dir}")
        try:
            self._model = load_model(model_dir)
        except Exception as e:
            raise MlxAudioAsrError(
                f"加载失败（{e}）。文件可能不完整，重新跑 setup_mt.py --model qwen3asr"
            ) from e
        self._max_tokens = int(cfg.get("maxTokens", 512))
        # MLX 的计算不是线程安全的，识别本来也在全局锁里，串行没损失
        self._lock = threading.Lock()

    def recognize(self, samples: np.ndarray, language: str = "") -> str:
        # 直接喂 ndarray，不落临时 wav：mlx-audio 只在输入是**路径**时才去解码文件，
        # 是数组就按模型自己的采样率（Qwen3-ASR 是 16k）原样收，正好是我们这条链的格式。
        audio = np.asarray(samples, dtype=np.float32)
        # 空串表示自动判断。这里和 whisper 那条路的取舍不同：whisper 猜错语种会把
        # 整段按另一门语言硬解，所以建议钉死；Qwen3-ASR 的语种判断是它的卖点之一，
        # 而且钉成 chinese 也不影响它认方言，所以认不出来就交给它自己判。
        lang = LANG_NAMES.get(language, "") if language else ""
        kw: Dict[str, Any] = {"max_tokens": self._max_tokens, "verbose": False}
        if lang:
            kw["language"] = lang
        with self._lock:
            try:
                r = self._model.generate(audio, **kw)
            except Exception as e:
                raise MlxAudioAsrError(f"识别失败（{e}）") from e
        return (getattr(r, "text", "") or "").strip()


def get(model_id: str, model_dir: str, cfg: Dict[str, Any]) -> Qwen3Asr:
    e = _engines.get(model_id)
    if e is not None:
        return e
    with _lock:
        e = _engines.get(model_id)
        if e is None:
            e = Qwen3Asr(model_dir, cfg)
            _engines[model_id] = e
        return e


def drop_cache(model_id: Optional[str] = None) -> None:
    with _lock:
        if model_id is None:
            _engines.clear()
        else:
            _engines.pop(model_id, None)
