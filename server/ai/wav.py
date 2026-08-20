"""PCM16 wav 的读写。手机端对应实现见 lib/logic/ai/wav.dart。

只处理单声道 PCM16——手机传上来的录音固定是 16kHz/单声道/PCM16，
合成回去的也统一转成 PCM16，两端格式对齐，不引入 soundfile 之类的额外依赖。
"""

import io
import wave

import numpy as np


def read(data: bytes) -> tuple[np.ndarray, int]:
    """wav 字节 -> (float32 [-1,1], sample_rate)。多声道取第一条。"""
    with wave.open(io.BytesIO(data), "rb") as w:
        if w.getsampwidth() != 2:
            raise ValueError(f"only pcm16 wav is supported, got {w.getsampwidth() * 8} bit")
        rate = w.getframerate()
        channels = w.getnchannels()
        raw = w.readframes(w.getnframes())
    samples = np.frombuffer(raw, dtype="<i2").astype(np.float32) / 32768.0
    if channels > 1:
        samples = samples[::channels]
    return samples, rate


def write(samples: np.ndarray, rate: int) -> bytes:
    # nan_to_num 要在 clip 之前：np.clip 不管 NaN，NaN 会原样穿过去，
    # 而 NaN 转 int16 在 numpy 里是未定义行为（实测出来是 -32768 的爆音）。
    # TTS 在词典没覆盖的输入上确实会吐 NaN，见 kokoro 的 OOV 路径。
    pcm = np.clip(np.nan_to_num(samples, nan=0.0, posinf=1.0, neginf=-1.0), -1.0, 1.0)
    pcm = (pcm * 32767.0).astype("<i2")
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())
    return buf.getvalue()


def duration_ms(count: int, rate: int) -> int:
    return 0 if rate <= 0 else int(count * 1000 / rate)
