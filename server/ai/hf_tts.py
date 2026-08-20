"""把 SeamlessM4T v2 当纯 TTS 用（文本 -> 语音），跑在 transformers/torch 上。

为什么值得单独接一个重量级模型进来：用户实测觉得它的声音比 kokoro 自然得多。
**只用它的嘴，不用它的脑**——翻译仍然走 opus-mt/NLLB（几十到几百毫秒），
它只负责把译文念出来。

代价（bench_s2st.py 实测，长句）：
    kokoro          2576 ms   实时率 0.91
    SeamlessM4T     3598 ms   实时率 1.27

实时率 >1 意味着单实例跟不上说话速度，连续录会堆队列。所以这里允许并发调用——
torch 在算子里会放开 GIL，同一份权重可以被多个线程同时用，内存不翻倍
（这点和 sherpa 不同：sherpa 的实例不是线程安全的，只能各建一份）。
"""

import os
import threading
from typing import Any, Dict, Optional, Tuple

import numpy as np

_engines: Dict[str, Any] = {}
_lock = threading.Lock()


class HfTtsError(Exception):
    pass


class SeamlessTts:
    def __init__(self, model_dir: str, cfg: Dict[str, Any], num_threads: int, workers: int):
        try:
            import torch
            from transformers import AutoProcessor, SeamlessM4Tv2Model
        except ImportError as e:
            raise HfTtsError(
                "这个 TTS 要 torch + transformers，还没装。"
                "在 server/ai 下跑：pip install -r requirements-s2st.txt"
            ) from e
        self._torch = torch
        torch.set_num_threads(max(1, num_threads))
        self._proc = AutoProcessor.from_pretrained(model_dir)
        self._model = SeamlessM4Tv2Model.from_pretrained(model_dir, torch_dtype=torch.float32)
        self._model.eval()
        self._lang = cfg.get("tgtLang", "eng")
        # 分词单独一把锁。HF 的 Rust 快速分词器在设置 src_lang 时会**改写自己的
        # post-processor**，两个线程同时进来会炸 "RuntimeError: Already borrowed"。
        # 权重可以共享，分词器不行。好在分词是微秒级的，串行不影响吞吐。
        self._tok_lock = threading.Lock()
        self._rate = int(cfg.get("sampleRate", 0) or self._model.config.sampling_rate)
        # 限流而不是排他：权重共享，但同时跑太多只会互相抢核心
        self._sem = threading.Semaphore(max(1, workers))

    def synthesize(self, text: str) -> Tuple[Optional[np.ndarray], int]:
        text = (text or "").strip()
        if not text:
            return None, 0
        with self._tok_lock:
            inputs = self._proc(text=text, src_lang=self._lang, return_tensors="pt")
        with self._sem:
            with self._torch.inference_mode():
                out = self._model.generate(**inputs, tgt_lang=self._lang)
        wave = out.waveform if hasattr(out, "waveform") else out[0]
        arr = wave.cpu().numpy().squeeze().astype(np.float32)
        if arr.size == 0:
            return None, 0
        return arr, self._rate


def get(model_id: str, model_dir: str, cfg: Dict[str, Any],
        num_threads: int, workers: int) -> SeamlessTts:
    # 双重检查：加载要几秒、吃 9 GB，绝不能因为并发建两份
    e = _engines.get(model_id)
    if e is not None:
        return e
    with _lock:
        e = _engines.get(model_id)
        if e is None:
            e = SeamlessTts(model_dir, cfg, num_threads, workers)
            _engines[model_id] = e
        return e


def drop_cache(model_id: Optional[str] = None) -> None:
    with _lock:
        if model_id is None:
            _engines.clear()
        else:
            _engines.pop(model_id, None)
