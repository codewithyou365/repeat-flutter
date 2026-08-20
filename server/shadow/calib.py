"""打分的可调参数，存 ~/.repeat-shadow/calib.json。

为什么要有这么一个东西：GOP 的绝对尺度取决于模型、录音通道和说话人母语。
手机麦克风的音频过了 AEC/NS/AGC，会系统性地比干净音频低分。所以这套阈值
**开箱一定是没校准的**，必须能在不重启、不重新打包的前提下拧——手机拿在
手上就能调，否则每改一个数字要走一遍 gen.sh → dist.zip → 设备，没人受得了。

存放位置照 server/ai/selection.py 的做法，放在 models 目录**旁边**而不是里面，
这样删模型重下不会把校准结果一起删掉。
"""

import json
import os
import threading
from typing import Any, Dict

import model

_lock = threading.Lock()
_cache: Dict[str, Any] = {}

DEFAULTS: Dict[str, Any] = {
    # ---- GOP -> 0..100 的 logistic 压缩 ----
    # score = 100 / (1 + exp(-(gop - m) / s))
    # 默认值下：gop=0 -> 90, -1 -> 75, -2 -> 50, -3 -> 25, -5 -> 4
    "m": -2.0,
    "s": 0.9,
    # 压缩前加到原始 GOP 上的偏移，给"我这台手机麦克风偏小声"用。
    "gopOffset": 0.0,

    # ---- 三项的权重，加起来应当是 1 ----
    "wAccuracy": 0.60,
    "wCompleteness": 0.25,
    "wFluency": 0.15,

    # ---- 颜色阈值 ----
    "green": 80,
    "amber": 60,

    # ---- 流利度 ----
    # 目标语速（音素/秒）。英语母语者朗读大致 10~13。
    "targetPps": 11.0,
    # 容差因子：语速在 target/1.6 ~ target*1.6 之间不扣满分。
    "rateTol": 1.6,
    # 句中停顿超过这个毫秒数才算一次卡顿。
    "pauseMs": 300,
    # 每次卡顿扣几分。
    "pausePenalty": 6.0,
    # 语速偏离扣满时的分数。
    "ratePenaltyMax": 40.0,

    # ---- 防作弊闸门 ----
    # 音素错误率超过它就判定"读的根本不是这句"。
    # 强制对齐永远会成功，没有这道闸，咳嗽也能得 85 分。
    "perMismatch": 0.8,
    # 判定 mismatch 后 accuracy 的封顶值。
    "mismatchCap": 25.0,
    # 非 blank 帧占比低于它就认为没录到人声。
    #
    # 0.05 看着低得离谱，其实不是：CTC 的输出是**尖峰**的，即使一句话说得
    # 密不透风，绝大多数帧上 argmax 仍然是 blank。实测（见 README 排错一节）：
    #   纯静音 / 低噪 / 白噪  -> 0.000
    #   正常朗读的一句话      -> 0.19 ~ 0.27
    # 一开始按直觉写的 0.20 会把语速稍慢的真人录音判成"没录到人声"。
    # 静音那头干干净净是 0，所以往下放到 0.05，两边都留足余量。
    "minVoiced": 0.05,

    # ---- 输入限制 ----
    "maxSeconds": 30.0,
    # espeak 的方言。必须和参考 TTS 的口音一致：en-us 和 en-gb 光是
    # r 音色化就能差 10 分。
    "lang": "en-us",
}

# 这些键必须是整数，其余按浮点处理。
_INT_KEYS = {"green", "amber", "pauseMs"}
_STR_KEYS = {"lang"}


def path() -> str:
    # 和 server/ai/selection.py 一样：放在 models 目录旁边，不放里面。
    return os.path.join(os.path.dirname(os.path.abspath(model.model_root())), "calib.json")


def load() -> Dict[str, Any]:
    global _cache
    with _lock:
        if _cache:
            return dict(_cache)
        out = dict(DEFAULTS)
        p = path()
        if os.path.exists(p):
            try:
                with open(p, encoding="utf-8") as f:
                    saved = json.load(f)
                # 只认识 DEFAULTS 里有的键：老版本写下的、后来删掉的键
                # 直接忽略，不要让它们复活。
                for k, v in saved.items():
                    if k in DEFAULTS:
                        out[k] = v
            except Exception:
                # 文件坏了就用默认值，不要因为一个 json 语法错误起不来服务。
                pass
        _cache = out
        return dict(out)


def save(values: Dict[str, Any]) -> Dict[str, Any]:
    global _cache
    cur = load()
    cur.update(values)
    with _lock:
        _cache = cur
        p = path()
        os.makedirs(os.path.dirname(p), exist_ok=True)
        tmp = p + ".part"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(cur, f, ensure_ascii=False, indent=2)
        os.replace(tmp, p)
    return dict(cur)


def coerce(key: str, raw: str) -> Any:
    """把表单里的字符串转成这个键该有的类型。"""
    if key not in DEFAULTS:
        raise KeyError(key)
    if key in _STR_KEYS:
        return raw
    if key in _INT_KEYS:
        return int(float(raw))
    return float(raw)


def merged(overrides: Dict[str, Any] | None) -> Dict[str, Any]:
    """当次请求的参数覆盖。只影响本次打分，不落盘。"""
    c = load()
    if overrides:
        for k, v in overrides.items():
            if k in DEFAULTS:
                c[k] = v
    return c
