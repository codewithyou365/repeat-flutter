"""发音评测引擎：强制对齐 + GOP。

思路和商用发音评测（Azure / 讯飞）是同一套：

  1. 参考文本 -> 音素序列（g2p.py）
  2. 音频 -> wav2vec2 的逐帧音素后验
  3. 把音素序列**强制对齐**到这些帧上（CTC Viterbi）
  4. 每个音素的 GOP = 它在自己那几帧上的后验，比这些帧上最强的那个音素差多少
  5. 逐音素分聚合成逐词分、句子分

第 4 步是全部的信息量所在：ASR 会"自动纠错"（发音再差也常常转对），
而 GOP 直接问"这一帧的声学证据有多支持你声称在读的这个音"。

**一个必须记住的性质：强制对齐永远会成功。** 喂它静音、咳嗽、或者一句完全
不相干的话，它照样返回一条完整的、看着挺像样的逐音素 GOP。所以 _gate() 里
那两道闸不是可选的锦上添花，是这个模块能不能用的前提。
"""

import itertools
import json
import math
import os
import threading
import time
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

import calib
import g2p
import model as model_mod

# log 域里代表"不可能"。用 -1e30 而不是 -inf：-inf 参与 argmax 时
# 全行都是 -inf 会退化成 argmax=0，而且 -inf + 有限数在某些 numpy
# 路径上会冒 RuntimeWarning。
NEG = -1e30


class ShadowError(Exception):
    """业务错误。server.py 会把它转成 400 {"error": ...}。"""


_model = None
_model_lock = threading.Lock()
_device = "cpu"
_frame_ms = 20.0
_blank = 0
_vocab: Dict[str, int] = {}
_phone_ids: Optional[np.ndarray] = None
_id_to_sym: Dict[int, str] = {}


# --------------------------------------------------------------------------
# 模型加载
# --------------------------------------------------------------------------

def _self_check_mps(m, torch) -> bool:
    """MPS 算得对不对，用一秒噪声实测一下。

    wav2vec2 的 group norm 和大一维卷积在 MPS 上历史性地算错过——不是崩，
    是安静地给出不同的数。发音评测全靠后验的细微差别，这种错误会直接变成
    莫名其妙的分数，而且没有任何报错指向它。所以宁可实测一次。
    """
    try:
        x = torch.randn(1, 16000)
        with torch.inference_mode():
            a = m.to("cpu")(x).logits
            b = m.to("mps")(x.to("mps")).logits.cpu()
        delta = float((a - b).abs().max())
        if delta > 1e-2:
            print(f"[shadow] MPS 自检不过（最大误差 {delta:.4f} > 1e-2），退回 CPU")
            m.to("cpu")
            return False
        print(f"[shadow] MPS 自检通过（最大误差 {delta:.5f}）")
        return True
    except Exception as e:
        print(f"[shadow] MPS 自检异常（{e}），退回 CPU")
        try:
            m.to("cpu")
        except Exception:
            pass
        return False


def load(root: str = "", device: str = "cpu") -> None:
    """加载模型。双检锁，绝不在持锁的请求里重复加载。"""
    global _model, _device, _frame_ms, _blank, _vocab, _phone_ids, _id_to_sym
    if _model is not None:
        return
    with _model_lock:
        if _model is not None:
            return

        if not model_mod.is_installed(root):
            miss = model_mod.missing_files(root)
            raise ShadowError(
                f"模型没装。跑 python install.py 装它。缺：{', '.join(miss) or '.ok 标记'}"
            )

        try:
            import torch
            from transformers import Wav2Vec2ForCTC
        except ImportError as e:
            raise ShadowError(f"缺 {e.name}，装 requirements.txt") from e

        d = model_mod.model_dir(root)
        t0 = time.time()
        m = Wav2Vec2ForCTC.from_pretrained(d)
        m.eval()

        dev = "cpu"
        if device == "mps" and torch.backends.mps.is_available():
            if _self_check_mps(m, torch):
                dev = "mps"
        m.to(dev)

        # 帧长算出来而不是写死 20：一行代码同时是文档，换模型也不会错。
        stride = int(np.prod(m.config.conv_stride))
        _frame_ms = 1000.0 * stride / 16000.0
        # blank 取 config 的 pad_token_id，不要靠"找 <pad> 的 id"——
        # 两者在别的模型上不一定相等。
        _blank = int(m.config.pad_token_id or 0)

        with open(os.path.join(d, "vocab.json"), encoding="utf-8") as f:
            _vocab = json.load(f)
        # 真实音素的 id 集合。GOP 取 max 时只在这些上面取，
        # 排除 blank 和 <s>/</s>/<unk>（见 _score_phones 的注释）。
        _phone_ids = np.array(
            sorted(v for k, v in _vocab.items() if k not in g2p.SPECIALS),
            dtype=np.int64,
        )
        _id_to_sym = {v: k for k, v in _vocab.items()}

        _model = m
        _device = dev
        print(f"[shadow] 模型就绪：{d}")
        print(f"[shadow] device={dev} frameMs={_frame_ms} blank={_blank} "
              f"vocab={len(_vocab)} 音素={len(_phone_ids)} 加载耗时={time.time()-t0:.1f}s")


def is_loaded() -> bool:
    return _model is not None


def info() -> Dict[str, Any]:
    return {
        "device": _device,
        "frameMs": _frame_ms,
        "blank": _blank,
        "vocabSize": len(_vocab),
        "phoneCount": int(len(_phone_ids)) if _phone_ids is not None else 0,
    }


def drop() -> None:
    """卸载模型（删模型时用）。"""
    global _model
    with _model_lock:
        _model = None


# --------------------------------------------------------------------------
# 前向
# --------------------------------------------------------------------------

def _logprobs(samples: np.ndarray) -> np.ndarray:
    """音频 -> 逐帧 log 后验 [T, V]。"""
    import torch

    # preprocessor_config 里 do_normalize=True，且这个模型 feat_extract_norm="layer"。
    # 跳过这步会明显掉点——不是崩，是安静地变差。
    x = samples.astype(np.float32)
    x = (x - x.mean()) / math.sqrt(float(x.var()) + 1e-7)

    t = torch.from_numpy(x)[None].to(_device)
    with torch.inference_mode():
        logits = _model(t).logits[0]
    # float() 是必要的：MPS 上可能是 float16/bfloat16，log_softmax 在低精度下
    # 会把 GOP 的细微差别抹平，而 GOP 全靠这点差别。
    return torch.log_softmax(logits.float(), dim=-1).cpu().numpy()


# --------------------------------------------------------------------------
# CTC 强制对齐
# --------------------------------------------------------------------------

def forced_align(logp: np.ndarray, y: np.ndarray, blank: int) -> np.ndarray:
    """把音素序列 y 强制对齐到帧上，返回每帧走到了哪个状态。

    blank 增广目标 z = [b, y1, b, y2, ..., yP, b]，长度 S = 2P+1。
    取 max 而不是 sum：要的是最优路径，不是总似然。

        alpha[t,s] = logp[t, z[s]] + max( alpha[t-1, s],
                                          alpha[t-1, s-1],
                                          alpha[t-1, s-2]  当 z[s] 非 blank
                                                           且 z[s] != z[s-2] )

    50 fps 下 10 秒 = 500 帧 x ~81 状态，500 步向量化 numpy，1~3 ms。
    """
    T = logp.shape[0]
    P = len(y)
    S = 2 * P + 1

    z = np.full(S, blank, dtype=np.int64)
    z[1::2] = y

    # 只有非 blank、且和前一个音素不同的状态，才允许从 s-2 跳过来。
    # 相同音素之间必须夹一个 blank，否则 CTC 会把 "aa" 折叠成 "a"。
    skip = np.zeros(S, dtype=bool)
    if P > 1:
        skip[3::2] = (y[1:] != y[:-1])

    emit = logp[:, z]                      # [T, S] 预取发射概率
    alpha = np.full(S, NEG, dtype=np.float64)
    alpha[0] = emit[0, 0]
    if S > 1:
        alpha[1] = emit[0, 1]

    bp = np.zeros((T, S), dtype=np.int8)   # 回溯用：这一步往回退了几格
    idx = np.arange(S)

    for t in range(1, T):
        a1 = np.concatenate(([NEG], alpha[:-1]))
        a2 = np.where(skip, np.concatenate(([NEG, NEG], alpha[:-2])), NEG)
        cand = np.stack((alpha, a1, a2))
        arg = cand.argmax(0)
        bp[t] = arg
        alpha = cand[arg, idx] + emit[t]

    # 终点只能落在最后一个音素或它后面那个 blank 上。
    s = S - 1 if alpha[S - 1] >= alpha[S - 2] else S - 2
    path = np.empty(T, dtype=np.int64)
    for t in range(T - 1, -1, -1):
        path[t] = s
        s -= int(bp[t, s])
    return path


# --------------------------------------------------------------------------
# 编辑距离（带回溯）
# --------------------------------------------------------------------------

def _levenshtein(hyp: List[int], ref: List[int]) -> Tuple[int, int, int, List[str]]:
    """返回 (替换数, 删除数, 插入数, 每个参考音素的状态)。

    状态取值 'ok' / 'sub' / 'del'，长度和 ref 一致——逐词的"漏读"判定
    就是数某个词里有多少个 'del'。
    """
    n, m = len(ref), len(hyp)
    # d[i][j] = ref 前 i 个 和 hyp 前 j 个 的距离
    d = np.zeros((n + 1, m + 1), dtype=np.int32)
    d[:, 0] = np.arange(n + 1)
    d[0, :] = np.arange(m + 1)
    for i in range(1, n + 1):
        ri = ref[i - 1]
        for j in range(1, m + 1):
            cost = 0 if ri == hyp[j - 1] else 1
            d[i, j] = min(d[i - 1, j] + 1,        # 删除（参考里有，识别里没有）
                          d[i, j - 1] + 1,        # 插入（识别里多出来）
                          d[i - 1, j - 1] + cost)  # 匹配 / 替换

    status = ["ok"] * n
    subs = dels = ins = 0
    i, j = n, m
    while i > 0 or j > 0:
        if i > 0 and j > 0 and d[i, j] == d[i - 1, j - 1] + (0 if ref[i - 1] == hyp[j - 1] else 1):
            if ref[i - 1] != hyp[j - 1]:
                status[i - 1] = "sub"
                subs += 1
            i -= 1
            j -= 1
        elif i > 0 and d[i, j] == d[i - 1, j] + 1:
            status[i - 1] = "del"
            dels += 1
            i -= 1
        else:
            ins += 1
            j -= 1
    return subs, dels, ins, status


# --------------------------------------------------------------------------
# 打分
# --------------------------------------------------------------------------

def _sigmoid(z: float) -> float:
    # 防溢出：exp(710) 就 inf 了
    z = max(-60.0, min(60.0, z))
    return 1.0 / (1.0 + math.exp(-z))


def _squash(gop: float, c: Dict[str, Any]) -> float:
    """GOP -> 0..100。

    logistic 而不是分段线性：两端没有死区，颜色过渡也平滑。

    **要除以 gop=0 处的值做归一化**，否则满分够不着。GOP 的理论上界是 0
    （对齐音素在自己每一帧上都是 argmax），裸 logistic 在默认 m=-2 / s=0.9 下
    只给到 100*sigmoid(2.22) = 90 分。那样配置里的 star3=90 实际含义就变成了
    "声学上完美无瑕"，真人永远拿不到三星，而合成音也就刚好卡在 90。
    归一化之后 gop=0 就是 100 分，0..100 这个刻度才名副其实。
    """
    top = _sigmoid((0.0 - c["m"]) / max(c["s"], 1e-6))
    z = (gop + c["gopOffset"] - c["m"]) / max(c["s"], 1e-6)
    return min(100.0, 100.0 * _sigmoid(z) / max(top, 1e-6))


def _level(score: float, c: Dict[str, Any]) -> str:
    if score >= c["green"]:
        return "good"
    if score >= c["amber"]:
        return "fair"
    return "bad"


def score(samples: np.ndarray, rate: int, text: str,
          overrides: Optional[Dict[str, Any]] = None,
          root: str = "") -> Dict[str, Any]:
    """给一段录音按参考文本打分。"""
    t_all = time.time()
    c = calib.merged(overrides)

    if _model is None:
        raise ShadowError("模型还没加载好")
    if rate != 16000:
        raise ShadowError(f"采样率必须是 16000，收到 {rate}")
    if samples.size == 0:
        raise ShadowError("音频是空的")

    dur_s = samples.size / float(rate)
    if dur_s > c["maxSeconds"]:
        raise ShadowError(f"录音太长（{dur_s:.1f} 秒 > {c['maxSeconds']:.0f} 秒）")

    # ---- 1. 文本 -> 音素 ----
    t0 = time.time()
    d = model_mod.model_dir(root)
    phone_ids, word_of, words, phone_syms, unmapped = g2p.prepare(text, d, c["lang"])
    g2p_ms = int((time.time() - t0) * 1000)

    y = np.array(phone_ids, dtype=np.int64)
    P = len(y)

    # ---- 2. 前向 ----
    t0 = time.time()
    logp = _logprobs(samples)
    fwd_ms = int((time.time() - t0) * 1000)
    T = logp.shape[0]

    # 路径必须走完所有状态，所以帧数至少要有 2P+1，即每个音素 40ms。
    # 不挡的话对齐会给出一条垃圾路径，而且不会报错。
    if T < 2 * P + 1:
        need = (2 * P + 1) * _frame_ms / 1000.0
        raise ShadowError(
            f"录音太短，放不下这段文本（需要至少 {need:.1f} 秒，实际 {dur_s:.1f} 秒）"
        )

    # ---- 3. 无约束贪心解码（完整度 + 防作弊） ----
    pred = logp.argmax(axis=1)
    voiced = float((pred != _blank).mean())
    if voiced < c["minVoiced"]:
        raise ShadowError("没录到有效语音（几乎全是静音）")

    hyp = [int(k) for k, _ in itertools.groupby(pred) if int(k) != _blank]
    subs, dels, ins, status = _levenshtein(hyp, [int(v) for v in y])
    per = (subs + dels + ins) / max(P, 1)

    # ---- 4. 强制对齐 ----
    t0 = time.time()
    path = forced_align(logp, y, _blank)
    align_ms = int((time.time() - t0) * 1000)

    # ---- 5. 逐音素 GOP ----
    # max 只在真实音素上取，**排除 blank**。blank 在相当大比例的帧上主导后验，
    # 算进去会让所有 GOP 都极负、动态范围压平成一条线。
    best_any = logp[:, _phone_ids].max(axis=1)

    phones: List[Dict[str, Any]] = []
    for p in range(P):
        fr = np.flatnonzero(path == 2 * p + 1)
        if fr.size == 0:
            # 理论上不会发生：跳转只跨 blank，每个音素状态至少占一帧。
            # 真发生了说明对齐实现有 bug，给个最低分而不是崩。
            gop_v = -10.0
            st = en = 0
        else:
            gop_v = float(np.mean(logp[fr, y[p]] - best_any[fr]))
            st = int(fr[0] * _frame_ms)
            en = int((fr[-1] + 1) * _frame_ms)
        sc = _squash(gop_v, c)
        phones.append({
            "p": phone_syms[p],
            "start": st,
            "end": en,
            "gop": round(gop_v, 3),
            "score": int(round(sc)),
            "status": status[p],
            "_w": word_of[p],
            "_raw": sc,
        })

    # ---- 6. 聚合到词 ----
    out_words: List[Dict[str, Any]] = []
    missed: List[str] = []
    for wi, w in enumerate(words):
        ph = [x for x in phones if x["_w"] == wi]
        if not ph:
            continue
        # 词分取算术平均，不按时长加权：加权会让长元音淹没掉真正出错的塞音。
        wscore = sum(x["_raw"] for x in ph) / len(ph)
        ndel = sum(1 for x in ph if x["status"] == "del")
        is_missed = ndel > len(ph) / 2
        if is_missed:
            missed.append(w)
        out_words.append({
            "w": w,
            "start": ph[0]["start"],
            "end": ph[-1]["end"],
            "score": int(round(wscore)),
            "level": "bad" if is_missed else _level(wscore, c),
            "missed": is_missed,
            "phones": [{k: v for k, v in x.items() if not k.startswith("_")} for x in ph],
            "_n": len(ph),
            "_raw": wscore,
        })

    # 句子 accuracy 按音素数加权：6 音素的词比 1 音素的词更有分量。
    tot_n = sum(x["_n"] for x in out_words) or 1
    accuracy = sum(x["_raw"] * x["_n"] for x in out_words) / tot_n

    read = len(out_words) - len(missed)
    completeness = 100.0 * read / max(len(out_words), 1)

    # ---- 7. 防作弊闸：读的根本不是这句 ----
    mismatch = per > c["perMismatch"]
    if mismatch:
        accuracy = min(accuracy, c["mismatchCap"])

    # ---- 8. 流利度 ----
    nb = np.flatnonzero(path % 2 == 1)          # 非 blank 状态的帧
    if nb.size:
        speech_ms = int((nb[-1] - nb[0] + 1) * _frame_ms)
    else:
        speech_ms = 0

    pause_count = 0
    if nb.size > 1:
        # 句中（不含首尾静音）的 blank 连续段。词边界本来就允许短停，
        # 所以只数"落在同一个词内部"的停顿。
        blank_frames = path[nb[0]:nb[-1] + 1] % 2 == 0
        pause_frames = max(1, int(c["pauseMs"] / _frame_ms))
        run = 0
        for i, is_blank in enumerate(blank_frames):
            if is_blank:
                run += 1
                continue
            if run >= pause_frames:
                # 看这段停顿两边是不是同一个词——是的话才算卡顿。
                left = path[nb[0] + i - run - 1] if (nb[0] + i - run - 1) >= 0 else -1
                right = path[nb[0] + i]
                lp, rp = (int(left) - 1) // 2, (int(right) - 1) // 2
                if 0 <= lp < P and 0 <= rp < P and word_of[lp] == word_of[rp]:
                    pause_count += 1
            run = 0

    fluency = 100.0
    if speech_ms > 0:
        pps = P / (speech_ms / 1000.0)
        tol = max(c["rateTol"], 1.01)
        pen = c["ratePenaltyMax"] * min(abs(math.log(pps / c["targetPps"])) / math.log(tol), 1.0)
        fluency = 100.0 - c["pausePenalty"] * pause_count - pen
    else:
        pps = 0.0
    fluency = max(0.0, min(100.0, fluency))

    # ---- 9. 总分 ----
    overall = (c["wAccuracy"] * accuracy
               + c["wCompleteness"] * completeness
               + c["wFluency"] * fluency)

    for x in out_words:
        x.pop("_n", None)
        x.pop("_raw", None)

    return {
        "overall": int(round(overall)),
        "accuracy": int(round(accuracy)),
        "completeness": int(round(completeness)),
        "fluency": int(round(fluency)),
        "durationMs": int(dur_s * 1000),
        "speechMs": speech_ms,
        "degraded": False,
        "mismatch": mismatch,
        "words": out_words,
        "missedWords": missed,
        "insertions": ins,
        "substitutions": subs,
        "deletions": dels,
        "per": round(per, 3),
        "voiced": round(voiced, 3),
        "pps": round(pps, 1),
        "pauseCount": pause_count,
        "decoded": " ".join(_id_to_sym.get(k, "?") for k in hyp),
        "reference": " ".join(phone_syms),
        "unmappedPhones": sorted(set(unmapped)),
        "timing": {
            "g2pMs": g2p_ms, "forwardMs": fwd_ms, "alignMs": align_ms,
            "totalMs": int((time.time() - t_all) * 1000),
        },
    }
