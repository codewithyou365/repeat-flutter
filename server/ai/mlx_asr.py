"""语音识别跑在 MLX 上（Apple Silicon 的 GPU）。

和 sherpa-onnx 那条路的区别：sherpa 是 CPU int8，这条是 GPU。对 large 级别的
whisper 来说差别很大——ONNX CPU 上 turbo 要 725ms，GPU 上应该快不少（未实测）。

为什么值得：现在的 paraformer 只要 23ms，但它是中文单语的；whisper-small 会
**把中文当英文解码**（实测出现过整段原文变英文），而 large-v3-turbo 的中文明显更准。

只能在 Apple Silicon 上跑。别的平台会明确报错，不静默降级。
"""

import os
import threading
from typing import Any, Dict, Optional

import numpy as np

_engines: Dict[str, Any] = {}
_lock = threading.Lock()


class MlxAsrError(Exception):
    pass


class MlxWhisper:
    def __init__(self, model_dir: str, cfg: Dict[str, Any]):
        try:
            import mlx_whisper  # noqa: F401
        except ImportError as e:
            raise MlxAsrError(
                "MLX 识别要 mlx-whisper（只支持 Apple Silicon），还没装。在 server/ai 下跑：\n"
                "  pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple"
            ) from e
        if not os.path.isdir(model_dir):
            raise MlxAsrError(f"模型目录不在: {model_dir}")
        self._dir = model_dir
        self._cfg = cfg
        # MLX 的计算不是线程安全的，识别本来也在全局锁里，串行没损失
        self._lock = threading.Lock()

    def recognize(self, samples: np.ndarray, language: str = "", task: str = "transcribe") -> str:
        import mlx_whisper
        # 空串表示自动判断——但**建议钉死**：whisper 猜错语种会把整段按另一门语言
        # 硬解，出来的原文完全不沾边，而且翻译再好也救不回来。
        kw: Dict[str, Any] = {"path_or_hf_repo": self._dir, "task": task}
        if language:
            kw["language"] = language
        with self._lock:
            try:
                r = mlx_whisper.transcribe(samples.astype(np.float32), **kw)
            except Exception as e:
                raise MlxAsrError(f"识别失败（{e}）") from e
        return (r.get("text") or "").strip()


def get(model_id: str, model_dir: str, cfg: Dict[str, Any]) -> MlxWhisper:
    e = _engines.get(model_id)
    if e is not None:
        return e
    with _lock:
        e = _engines.get(model_id)
        if e is None:
            e = MlxWhisper(model_dir, cfg)
            _engines[model_id] = e
        return e


def drop_cache(model_id: Optional[str] = None) -> None:
    with _lock:
        if model_id is None:
            _engines.clear()
        else:
            _engines.pop(model_id, None)
