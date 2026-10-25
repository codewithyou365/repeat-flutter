"""合成跑在 mlx-audio 上（Qwen3-TTS，苹果 GPU）。

为什么要它：Piper / kokoro 都是"先按某一门语言查音素表，再发声"，一个声音只认一种
语言——句子里夹一段日文或英文，就会被当成本语言的字硬拼，念出来是乱的。
Qwen3-TTS 是 LLM 直接从文字出声音，不经过音素表，一句话里中日英混着写也能念对。

和 [hf_tts] 的区别：那边是 transformers/torch 跑 CPU，这边是 MLX 跑 GPU，两个运行时
毫不相干，所以单开一个模块。和 [mlx_audio_asr] 是同一个包，但一个 stt 一个 tts，
加载入口和调用方式都不同。

只能在 Apple Silicon 上跑。别的平台会明确报错，不静默降级。
"""

import os
import re
import threading
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

_engines: Dict[str, Any] = {}
_lock = threading.Lock()


class MlxAudioTtsError(Exception):
    pass


# 平假名 + 片假名（含长音符 ー）。有假名就一定是日文；光有汉字分不出中日。
_KANA = re.compile(r"[\u3040-\u309f\u30a0-\u30ff\u31f0-\u31ff]")
_HAN = re.compile(r"[\u4e00-\u9fff]")
# 切分点：句读和引号。引号也切，是因为「ありがとう」这种引用最常见的就是夹在中文里
_CUT = re.compile(r"([「」『』“”\"。．！？!?，,；;：:\n]+)")


def split_ja(text: str) -> List[Tuple[str, str]]:
    """中日混排时按语言切段，返回 [(片段, lang_code)]；不需要切时返回整段 auto。

    为什么要切：实测 auto 模式下中英、日英混排都没问题，唯独**中日**混在一句里不行——
    音色的母语会压过去：中文音色把「ありがとう」念成"阿里嘎多"，日文音色念中文是乱码。
    同一个音色、把日文那段钉成 japanese 就念对了。

    只有"既有假名、又有不带假名的中文段"时才切。纯中文/中英/日英保持整段 auto，
    切开会多出段间停顿、丢掉整句的语调。不带假名的段落仍给 auto 而不是 chinese：
    钉成 chinese 会让里面夹的英文带口音。
    """
    pieces = [p for p in _CUT.split(text) if p]
    segs: List[Tuple[str, str]] = []
    lead = ""
    for p in pieces:
        if _CUT.fullmatch(p):
            # 标点挂到前一段尾巴上，不单独合成；开头的标点没有前一段，留给第一段
            if segs:
                segs[-1] = (segs[-1][0] + p, segs[-1][1])
            else:
                lead += p
            continue
        p, lead = lead + p, ""
        lang = "japanese" if _KANA.search(p) else ("auto" if _HAN.search(p) else "")
        if segs and (not lang or segs[-1][1] == lang):
            # 纯英文/数字的段不自带语言，跟着前一段走；同语言的相邻段并起来
            segs[-1] = (segs[-1][0] + p, segs[-1][1])
        else:
            segs.append((p, lang or "auto"))
    if len({l for _, l in segs}) < 2:
        return [(text, "auto")]
    return segs


class Qwen3Tts:
    def __init__(self, model_dir: str, cfg: Dict[str, Any], voices: List[str]):
        try:
            from mlx_audio.tts.utils import load_model
        except ImportError as e:
            raise MlxAudioTtsError(
                "Qwen3-TTS 要 mlx-audio（只支持 Apple Silicon），还没装。在 server/ai 下跑：\n"
                "  pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple"
            ) from e
        if not os.path.isdir(model_dir):
            raise MlxAudioTtsError(f"模型目录不在: {model_dir}")
        try:
            self._model = load_model(model_dir)
        except Exception as e:
            raise MlxAudioTtsError(
                f"加载失败（{e}）。文件可能不完整，重新跑 setup_mt.py --model qwen3tts"
            ) from e
        # 语言默认 auto，**别钉死**：钉成 chinese 的话句子里的英文/日文会带中文口音，
        # 混读正是要它自己逐段判断。中日混排另有切段处理，见 split_ja。
        self._language = cfg.get("language", "auto") or "auto"
        # 段与段之间垫一点静音，不然拼接处是硬切，听着像吞字
        self._gap = int(float(cfg.get("gapMs", 120)) / 1000 * int(self._model.sample_rate))
        self._instruct = cfg.get("instruct") or None
        # sid 是清单里 voices 的下标（和 sherpa 那边一致），这里换成模型认的音色名。
        # 清单写的名字模型不认（清单和权重对不上）时退回模型自己的第一个，不报错。
        self._supported = sorted(s.lower() for s in (self._model.get_supported_speakers() or []))
        self._voices = list(voices)
        self._rate = int(self._model.sample_rate)
        # MLX 的计算不是线程安全的，一次只合成一段
        self._lock = threading.Lock()

    def synthesize(self, text: str, sid: int = 0) -> Tuple[Optional[np.ndarray], int]:
        """返回 (float32 samples, sample_rate)。不支持调语速：模型本身没有这个参数。"""
        text = (text or "").strip()
        if not text:
            return None, 0
        voice = self._voices[sid].lower() if 0 <= sid < len(self._voices) else ""
        if voice not in self._supported:
            voice = self._supported[0] if self._supported else None
        segs = split_ja(text) if self._language == "auto" else [(text, self._language)]
        gap = np.zeros(self._gap, dtype=np.float32)
        parts: List[np.ndarray] = []
        with self._lock:
            try:
                for seg, lang in segs:
                    if parts:
                        parts.append(gap)
                    # 模型内部还会按换行再切，一行一个结果
                    parts += [np.asarray(r.audio, dtype=np.float32).reshape(-1)
                              for r in self._model.generate(text=seg, voice=voice,
                                                            instruct=self._instruct,
                                                            lang_code=lang,
                                                            verbose=False)]
            except Exception as e:
                raise MlxAudioTtsError(f"合成失败（{e}）") from e
        if not parts:
            return None, 0
        out = np.concatenate(parts)
        return (out, self._rate) if out.size else (None, 0)


def get(model_id: str, model_dir: str, cfg: Dict[str, Any], voices: List[str]) -> Qwen3Tts:
    e = _engines.get(model_id)
    if e is not None:
        return e
    with _lock:
        e = _engines.get(model_id)
        if e is None:
            e = Qwen3Tts(model_dir, cfg, voices)
            _engines[model_id] = e
        return e


def drop_cache(model_id: Optional[str] = None) -> None:
    with _lock:
        if model_id is None:
            _engines.clear()
        else:
            _engines.pop(model_id, None)
