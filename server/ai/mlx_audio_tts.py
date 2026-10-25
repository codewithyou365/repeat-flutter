"""合成跑在 mlx-audio 上（Qwen3-TTS / VoxCPM2 / OmniVoice，苹果 GPU）。

为什么要它：Piper / kokoro 都是"先按某一门语言查音素表，再发声"，一个声音只认一种
语言——句子里夹一段日文或英文，就会被当成本语言的字硬拼，念出来是乱的。
Qwen3-TTS 是 LLM 直接从文字出声音，不经过音素表，一句话里中日英混着写也能念对。

和 [hf_tts] 的区别：那边是 transformers/torch 跑 CPU，这边是 MLX 跑 GPU，两个运行时
毫不相干，所以单开一个模块。和 [mlx_audio_asr] 是同一个包，但一个 stt 一个 tts，
加载入口和调用方式都不同。

三个引擎按清单 cfg.engine 选：
- qwen3（默认）：自带 9 个音色，最快；但语气偏戏剧化，中日混排要切段（见 split_ja）。
- voxcpm2：克隆一段参考录音的声音，语气平稳、中日英混排不用切段就能念对。
- omnivoice：同样克隆参考录音，比 voxcpm2 快、小，日文略弱。

只能在 Apple Silicon 上跑。别的平台会明确报错，不静默降级。
"""

import os
import re
import threading
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

_engines: Dict[str, Any] = {}
_lock = threading.Lock()

# 随服务端一起发的参考录音（VoxCPM2 克隆用），文件名就是清单 voices 里的名字
VOICES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voices")


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


def _load(model_dir: str, setup_key: str):
    try:
        from mlx_audio.tts.utils import load_model
    except ImportError as e:
        raise MlxAudioTtsError(
            "这个 TTS 要 mlx-audio（只支持 Apple Silicon），还没装。在 server/ai 下跑：\n"
            "  pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple"
        ) from e
    if not os.path.isdir(model_dir):
        raise MlxAudioTtsError(f"模型目录不在: {model_dir}")
    try:
        return load_model(model_dir)
    except Exception as e:
        raise MlxAudioTtsError(
            f"加载失败（{e}）。文件可能不完整，重新跑 setup_mt.py --model {setup_key}"
        ) from e


class Qwen3Tts:
    def __init__(self, model_dir: str, cfg: Dict[str, Any], voices: List[str]):
        self._model = _load(model_dir, "qwen3tts")
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


class VoxCpm2Tts:
    """VoxCPM2：克隆 voices/ 下一段参考录音的声音来念。

    **必须给参考录音**：不给的话它每次随机出一个声音，而手机是按句分开请求的，
    一段话会变成好几个人在念。sid 选第几段录音（清单 voices 的下标）。

    推理步数默认压到 5（模型默认 10）：实测 4 句中日英混排在 5 步下全念对，
    实时率从 0.8 降到 0.45，才跟得上手机边取边播；10 步反而有一句念错，并不更准。
    """

    def __init__(self, model_dir: str, cfg: Dict[str, Any], voices: List[str]):
        self._model = _load(model_dir, "voxcpm2")
        self._steps = int(cfg.get("inferenceTimesteps", 5))
        self._refs = [os.path.join(VOICES_DIR, f"{v}.wav") for v in voices]
        missing = [p for p in self._refs if not os.path.exists(p)]
        if not self._refs or missing:
            raise MlxAudioTtsError(f"参考录音不在: {missing or VOICES_DIR}")
        self._rate = int(self._model.sample_rate)
        self._lock = threading.Lock()

    def synthesize(self, text: str, sid: int = 0) -> Tuple[Optional[np.ndarray], int]:
        """返回 (float32 samples, sample_rate)。不支持调语速。"""
        text = (text or "").strip()
        if not text:
            return None, 0
        ref = self._refs[sid] if 0 <= sid < len(self._refs) else self._refs[0]
        with self._lock:
            try:
                # 只给 ref_audio 是"克隆"；ref_text 它不用（那是 prompt_text 续写模式才要的）
                parts = [np.asarray(r.audio, dtype=np.float32).reshape(-1)
                         for r in self._model.generate(text=text, ref_audio=ref,
                                                       inference_timesteps=self._steps,
                                                       verbose=False)]
            except Exception as e:
                raise MlxAudioTtsError(f"合成失败（{e}）") from e
        if not parts:
            return None, 0
        out = np.concatenate(parts)
        return (out, self._rate) if out.size else (None, 0)


class OmniVoiceTts:
    """OmniVoice：和 VoxCPM2 一样克隆 voices/ 下的参考录音，sid 选第几段。

    比 VoxCPM2 快（16 步实时率约 0.36 对 0.48）、权重小一半，中英混排准；
    日文略弱一些（「ありがとう」夹在中文里容易念成"阿里嘎多"）。

    步数压到 16（模型默认 32）：实时率 0.74 → 0.36，准确率只差一句。
    参考录音在加载时就编码好缓存起来——它自己每次调用都会重新编码一遍。
    同名 .txt 是这段录音念的字，有就带上（帮它对齐音色），没有也能跑。
    """

    def __init__(self, model_dir: str, cfg: Dict[str, Any], voices: List[str]):
        self._model = _load(model_dir, "omnivoice")
        self._steps = int(cfg.get("numSteps", 16))
        paths = [os.path.join(VOICES_DIR, f"{v}.wav") for v in voices]
        missing = [p for p in paths if not os.path.exists(p)]
        if not paths or missing:
            raise MlxAudioTtsError(f"参考录音不在: {missing or VOICES_DIR}")
        from mlx_audio.tts.models.omnivoice.utils import create_voice_clone_prompt
        self._refs = []
        for p in paths:
            txt = os.path.splitext(p)[0] + ".txt"
            ref_text = open(txt, encoding="utf-8").read().strip() if os.path.exists(txt) else None
            tokens = create_voice_clone_prompt(p, tokenizer=self._model.audio_tokenizer,
                                               ref_text=ref_text)
            self._refs.append((tokens, ref_text))
        self._rate = int(self._model.sample_rate)
        self._lock = threading.Lock()

    def synthesize(self, text: str, sid: int = 0) -> Tuple[Optional[np.ndarray], int]:
        """返回 (float32 samples, sample_rate)。不支持调语速。"""
        text = (text or "").strip()
        if not text:
            return None, 0
        tokens, ref_text = self._refs[sid] if 0 <= sid < len(self._refs) else self._refs[0]
        with self._lock:
            try:
                parts = [np.asarray(r.audio, dtype=np.float32).reshape(-1)
                         for r in self._model.generate(text=text, ref_tokens=tokens,
                                                       ref_text=ref_text,
                                                       num_steps=self._steps,
                                                       verbose=False)]
            except Exception as e:
                raise MlxAudioTtsError(f"合成失败（{e}）") from e
        if not parts:
            return None, 0
        out = np.concatenate(parts)
        return (out, self._rate) if out.size else (None, 0)


_ENGINES = {"qwen3": Qwen3Tts, "voxcpm2": VoxCpm2Tts, "omnivoice": OmniVoiceTts}


def get(model_id: str, model_dir: str, cfg: Dict[str, Any], voices: List[str]):
    e = _engines.get(model_id)
    if e is not None:
        return e
    with _lock:
        e = _engines.get(model_id)
        if e is None:
            name = cfg.get("engine", "qwen3") or "qwen3"
            if name not in _ENGINES:
                raise MlxAudioTtsError(f"不认识的 engine: {name}（可选 {sorted(_ENGINES)}）")
            e = _ENGINES[name](model_dir, cfg, voices)
            _engines[model_id] = e
        return e


def drop_cache(model_id: Optional[str] = None) -> None:
    with _lock:
        if model_id is None:
            _engines.clear()
        else:
            _engines.pop(model_id, None)
