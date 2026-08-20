"""sherpa-onnx 模型的加载、缓存和推理。

和手机端 lib/logic/ai/infer_isolate.dart 的区别：
- 手机上 whisper 当识别又当翻译时要共用一个 recognizer、靠 setConfig 来回切 task，
  因为多一份 250MB 的 decoder 手机扛不住。Mac 上内存不是瓶颈，直接按
  (model_id, language, task) 各缓存一个实例，省掉那套容易出错的切换。
- numThreads 一律按机器核数覆盖。清单里写的 2 是照手机来的，在 M1 上是主要的浪费点。
"""

import contextlib
import os
import threading
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import sherpa_onnx

import catalog as cat

# 识别和翻译串行。sherpa 的 OfflineRecognizer 实例本身不是线程安全的，
# 而且这两步加起来才一百多毫秒，并行的收益不值那个复杂度。
_LOCK = threading.Lock()

# TTS 单独开池子。实测（bench_threads.py）合成占整段的 94%，而且几乎不吃线程：
# 4 线程 2608ms、8 线程 2490ms，给它 6 倍的核只快 1.3 倍。
# 与其让一个实例吃满核，不如开几个各分一部分核并行跑——两段的合成从
# 2×2490ms 变成约 2608ms，吞吐接近翻倍。录音是连续的，能不能排空队列看的是吞吐。
_TTS_POOL_SIZE = int(os.environ.get("REPEAT_AI_TTS_WORKERS") or 2)

_recognizers: Dict[Tuple[str, str, str], Any] = {}
_ttss: Dict[str, Any] = {}


def num_threads() -> int:
    return int(os.environ.get("REPEAT_AI_THREADS") or min(8, os.cpu_count() or 4))


def provider() -> str:
    return os.environ.get("REPEAT_AI_PROVIDER", "cpu")


class EngineError(Exception):
    pass


def _need(path: str, what: str) -> str:
    if not path or not os.path.exists(path):
        raise EngineError(f"{what} not found: {path}")
    return path


def _build_recognizer(entry: cat.ModelEntry, model_dir: str, language: str, task: str):
    cfg = cat.resolve_paths(entry.cfg, model_dir)
    model = cfg.get("model", {})
    tokens = _need(model.get("tokens", ""), "tokens")
    common = dict(num_threads=num_threads(), provider=provider(), debug=False)

    whisper = model.get("whisper") or {}
    if whisper:
        # 清单里 language 写死的（whisper-small.en）不许被覆盖，
        # 否则等于把这个单语模型废掉——和手机端 AiPipeline.withAsrLanguage 同一个道理。
        lang = whisper.get("language") or language or ""
        return sherpa_onnx.OfflineRecognizer.from_whisper(
            encoder=_need(whisper.get("encoder", ""), "whisper encoder"),
            decoder=_need(whisper.get("decoder", ""), "whisper decoder"),
            tokens=tokens,
            language=lang,
            task=task,
            decoding_method="greedy_search",
            **common,
        )

    sense = model.get("senseVoice") or {}
    if sense:
        return sherpa_onnx.OfflineRecognizer.from_sense_voice(
            model=_need(sense.get("model", ""), "sense-voice model"),
            tokens=tokens,
            language=sense.get("language") or language or "",
            use_itn=bool(sense.get("useInverseTextNormalization", True)),
            **common,
        )

    para = model.get("paraformer") or {}
    if para:
        return sherpa_onnx.OfflineRecognizer.from_paraformer(
            paraformer=_need(para.get("model", ""), "paraformer model"),
            tokens=tokens,
            decoding_method="greedy_search",
            **common,
        )

    raise EngineError(f"unsupported asr model type for {entry.id}")


def _build_tts(entry: cat.ModelEntry, model_dir: str, threads: Optional[int] = None):
    cfg = cat.resolve_paths(entry.cfg, model_dir)
    model = cfg.get("model", {})
    kwargs: Dict[str, Any] = dict(num_threads=threads or num_threads(),
                                  provider=provider(), debug=False)

    vits = model.get("vits") or {}
    if vits:
        kwargs["vits"] = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=_need(vits.get("model", ""), "vits model"),
            lexicon=vits.get("lexicon", "") or "",
            tokens=_need(vits.get("tokens", ""), "vits tokens"),
            data_dir=vits.get("dataDir", "") or "",
            dict_dir=vits.get("dictDir", "") or "",
        )

    kokoro = model.get("kokoro") or {}
    if kokoro:
        kk = getattr(sherpa_onnx, "OfflineTtsKokoroModelConfig", None)
        if kk is None:
            raise EngineError("this sherpa-onnx build has no kokoro support; upgrade it")
        kwargs["kokoro"] = kk(
            model=_need(kokoro.get("model", ""), "kokoro model"),
            voices=_need(kokoro.get("voices", ""), "kokoro voices"),
            tokens=_need(kokoro.get("tokens", ""), "kokoro tokens"),
            data_dir=_need(kokoro.get("dataDir", ""), "espeak-ng-data"),
            lexicon=kokoro.get("lexicon", "") or "",
        )

    if len(kwargs) == 3:
        raise EngineError(f"unsupported tts model type for {entry.id}")

    tts_cfg = sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(**kwargs),
        rule_fsts=cfg.get("ruleFsts", "") or "",
        # 清单里这个键名上游就拼错了（Senetences），照抄以保持两端一致
        max_num_sentences=int(cfg.get("maxNumSenetences", 1) or 1),
    )
    return sherpa_onnx.OfflineTts(tts_cfg)


def get_recognizer(cl: cat.Catalog, root: str, model_id: str, language: str, task: str):
    key = (model_id, language or "", task)
    r = _recognizers.get(key)
    if r is not None:
        return r
    entry = cl.by_id(model_id)
    if entry is None:
        raise EngineError(f"unknown model: {model_id}")
    d = cat.model_dir(root, model_id)
    if not cat.is_installed(root, model_id):
        raise EngineError(f"model not installed on server: {model_id}")
    r = _build_recognizer(entry, d, language, task)
    _recognizers[key] = r
    return r


def get_tts(cl: cat.Catalog, root: str, model_id: str):
    """单个 TTS 实例。给基准脚本和单元测试用；服务里走 [tts_pool]。"""
    t = _ttss.get(model_id)
    if t is not None:
        return t
    entry = cl.by_id(model_id)
    if entry is None:
        raise EngineError(f"unknown model: {model_id}")
    if not cat.is_installed(root, model_id):
        raise EngineError(f"model not installed on server: {model_id}")
    t = _build_tts(entry, cat.model_dir(root, model_id))
    _ttss[model_id] = t
    return t


class TtsPool:
    """几个 TTS 实例轮流用，每个分到一部分线程。

    实例是**懒建**的：只有并发真的上来了才建第二个，不然常驻两份模型是白占内存。
    """

    def __init__(self, cl: cat.Catalog, root: str, model_id: str, size: int):
        self._cl, self._root, self._id = cl, root, model_id
        self._size = max(1, size)
        # 每个实例分到的线程。总数不变，只是切开——单实例本来也用不满。
        self._threads = max(1, num_threads() // self._size)
        self._free: List[Any] = []
        self._built = 0
        self._cv = threading.Condition()

    def _make(self):
        entry = self._cl.by_id(self._id)
        if entry is None:
            raise EngineError(f"unknown model: {self._id}")
        if not cat.is_installed(self._root, self._id):
            raise EngineError(f"model not installed on server: {self._id}")
        return _build_tts(entry, cat.model_dir(self._root, self._id), self._threads)

    @contextlib.contextmanager
    def acquire(self):
        with self._cv:
            while True:
                if self._free:
                    inst = self._free.pop()
                    break
                if self._built < self._size:
                    self._built += 1
                    inst = None
                    break
                self._cv.wait()
        # 建实例放在锁外：kokoro 冷加载要一两秒，占着锁会把另一路也堵住
        if inst is None:
            try:
                inst = self._make()
            except Exception:
                with self._cv:
                    self._built -= 1
                    self._cv.notify()
                raise
        try:
            yield inst
        finally:
            with self._cv:
                self._free.append(inst)
                self._cv.notify()


_pools: Dict[str, TtsPool] = {}
_pool_lock = threading.Lock()


def tts_workers() -> int:
    return _TTS_POOL_SIZE


def tts_pool(cl: cat.Catalog, root: str, model_id: str) -> TtsPool:
    with _pool_lock:
        p = _pools.get(model_id)
        if p is None:
            p = TtsPool(cl, root, model_id, _TTS_POOL_SIZE)
            _pools[model_id] = p
        return p


def drop_cache(model_id: Optional[str] = None) -> None:
    """删/传模型后要把缓存里的实例丢掉，否则还指着旧文件。"""
    with _pool_lock:
        if model_id is None:
            _pools.clear()
        else:
            _pools.pop(model_id, None)
    if model_id is None:
        _recognizers.clear()
        _ttss.clear()
        return
    for k in [k for k in _recognizers if k[0] == model_id]:
        _recognizers.pop(k, None)
    _ttss.pop(model_id, None)


def recognize(recognizer, samples: np.ndarray, sample_rate: int = 16000) -> str:
    stream = recognizer.create_stream()
    stream.accept_waveform(sample_rate, samples)
    recognizer.decode_stream(stream)
    return stream.result.text.strip()


def synthesize(tts, text: str, sid: int = 0, speed: float = 1.0):
    """返回 (float32 samples, sample_rate)。文本为空返回 (None, 0)。"""
    if not text:
        return None, 0
    audio = tts.generate(text, sid=sid, speed=speed)
    samples = np.asarray(audio.samples, dtype=np.float32)
    if samples.size == 0:
        return None, 0
    return samples, int(audio.sample_rate)


def lock():
    return _LOCK
