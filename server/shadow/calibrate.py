"""校准 GOP -> 分数 的映射。

为什么必须校准：GOP 的绝对尺度取决于模型、录音通道和说话人母语。手机麦克风
的音频过了 AEC/NS/AGC，会系统性地比干净音频低分。所以 calib.py 里的默认
m/s **一定是没校准的**，开箱分数偏悲观。

用法一（自录，五分钟就能做完）：

    准备一个目录，里面成对放：
        good_01.wav  good_01.txt     <- 正常读
        bad_01.wav   bad_01.txt      <- 故意读错（漏音、读别的词、含糊）
    文件名里带 bad 的算"差"组，其余算"好"组。

    python calibrate.py ~/shadow-calib

    它会打印两组的逐音素 GOP 分位数，并给出建议的 m / s：
        m = 两组中位数的中点
        s = 两组间距的四分之一（让两组大致落在 logistic 的两端）

用法二（正经语料）：

    speechocean762 是公开的发音评测语料：5000 条中国人说的英语，
    音素/词/句三级人工 0-10 标注。HF 上 mispeech/speechocean762，约 500 MB。
    下下来解开后：

    python calibrate.py --corpus /path/to/speechocean762

    它会网格搜 m/s，最大化"我们的句子 accuracy"和"人工句子分"的 Pearson 相关，
    并把相关系数打出来。已发表的 GOP-CTC 基线大致在 0.55~0.65 PCC——
    低于 0.4 说明链路有问题（多半是 espeak 方言或词表切分对不上），
    不是调 m/s 能救的。
"""

import argparse
import glob
import os
import sys
from typing import List, Tuple

import numpy as np

import calib
import gop
import model as model_mod
import wav


def _collect(d: str, root: str) -> Tuple[List[float], List[float]]:
    """跑一遍目录，返回 (好组的逐音素 GOP, 差组的逐音素 GOP)。"""
    good: List[float] = []
    bad: List[float] = []
    files = sorted(glob.glob(os.path.join(d, "*.wav")))
    if not files:
        print(f"{d} 里没有 wav")
        return good, bad

    for f in files:
        txt = os.path.splitext(f)[0] + ".txt"
        if not os.path.exists(txt):
            print(f"  跳过 {os.path.basename(f)}：没有配套的 .txt")
            continue
        text = open(txt, encoding="utf-8").read().strip()
        try:
            samples, rate = wav.read(open(f, "rb").read())
            res = gop.score(samples, rate, text, root=root)
        except Exception as e:
            print(f"  跳过 {os.path.basename(f)}：{e}")
            continue
        gops = [p["gop"] for w in res["words"] for p in w["phones"]]
        tag = "bad" if "bad" in os.path.basename(f).lower() else "good"
        (bad if tag == "bad" else good).extend(gops)
        print(f"  {os.path.basename(f):28s} {tag:4s} 音素 {len(gops):3d} "
              f"GOP 中位数 {np.median(gops):+.2f}  总分 {res['overall']}")
    return good, bad


def _report(name: str, xs: List[float]) -> float:
    a = np.array(xs)
    qs = np.percentile(a, [5, 25, 50, 75, 95])
    print(f"{name:6s} n={len(a):5d}  "
          f"p5={qs[0]:+.2f} p25={qs[1]:+.2f} p50={qs[2]:+.2f} "
          f"p75={qs[3]:+.2f} p95={qs[4]:+.2f}")
    return float(qs[2])


def self_mode(d: str, root: str, apply: bool) -> int:
    gop.load(root, os.environ.get("REPEAT_SHADOW_DEVICE", "cpu"))
    good, bad = _collect(d, root)
    if not good:
        print("\n没有'好'组样本（文件名不含 bad 的），没法给建议。")
        return 1

    print()
    mg = _report("good", good)
    if not bad:
        print("\n没有'差'组样本。只能给一个粗略建议：把 m 设到好组的 p25 附近，")
        print(f"也就是 m ≈ {np.percentile(good, 25):.2f}，s 保持 0.9。")
        return 0
    mb = _report("bad", bad)

    if mg <= mb:
        print("\n好组的 GOP 中位数不比差组高——这不正常。先检查：")
        print("  1. espeak 方言对不对（en-us vs en-gb）")
        print("  2. 'bad' 的样本是不是其实读得没那么差")
        print("  3. /v1/score 的 unmappedPhones 是不是非空（词表切分失配）")
        return 1

    m = (mg + mb) / 2.0
    s = max((mg - mb) / 4.0, 0.2)
    print(f"\n建议：m = {m:.2f}   s = {s:.2f}")
    print(f"（当前：m = {calib.load()['m']}   s = {calib.load()['s']}）")
    print("\n这组值下两端会落在：")
    for label, v in (("好组中位", mg), ("差组中位", mb)):
        z = max(-60.0, min(60.0, (v - m) / s))
        print(f"  {label} GOP {v:+.2f} -> {100/(1+np.exp(-z)):.0f} 分")

    if apply:
        calib.save({"m": round(m, 2), "s": round(s, 2)})
        print(f"\n已写入 {calib.path()}")
    else:
        print("\n加 --apply 直接写进 calib.json，或者服务起着时热改：")
        print(f"  curl -X POST -d 'key=m&value={m:.2f}' localhost:8766/v1/calib")
        print(f"  curl -X POST -d 'key=s&value={s:.2f}' localhost:8766/v1/calib")
    return 0


def corpus_mode(d: str, root: str, apply: bool) -> int:
    """用 speechocean762 拟合 m/s。"""
    import json

    meta = os.path.join(d, "resource", "scores.json")
    if not os.path.exists(meta):
        meta = os.path.join(d, "scores.json")
    if not os.path.exists(meta):
        print(f"找不到 scores.json（在 {d} 或 {d}/resource 下）")
        print("语料：https://huggingface.co/datasets/mispeech/speechocean762")
        return 1

    gop.load(root, os.environ.get("REPEAT_SHADOW_DEVICE", "cpu"))
    labels = json.load(open(meta, encoding="utf-8"))

    ours: List[float] = []
    human: List[float] = []
    raw_gops: List[List[float]] = []

    for i, (key, item) in enumerate(labels.items()):
        f = os.path.join(d, "WAVE", f"SPEAKER{key[:4]}", f"{key}.WAV")
        if not os.path.exists(f):
            continue
        try:
            samples, rate = wav.read(open(f, "rb").read())
            res = gop.score(samples, rate, item["text"], root=root)
        except Exception:
            continue
        raw_gops.append([p["gop"] for w in res["words"] for p in w["phones"]])
        human.append(float(item["accuracy"]))
        ours.append(res["accuracy"])
        if (i + 1) % 100 == 0:
            print(f"  跑了 {len(ours)} 条")
        if len(ours) >= 800:      # 够拟合了，全跑完太慢
            break

    if len(ours) < 30:
        print(f"只跑出 {len(ours)} 条，太少。检查 WAVE 目录结构。")
        return 1

    # 网格搜 m/s，最大化 accuracy 和人工分的 Pearson 相关。
    # 注意 accuracy 是逐音素分的加权平均，所以直接在 raw_gops 上重算更快。
    best = (None, None, -2.0)
    for m in np.arange(-5.0, 0.01, 0.1):
        for s in np.arange(0.3, 3.01, 0.1):
            pred = [float(np.mean(100.0 / (1.0 + np.exp(-np.clip((np.array(g) - m) / s, -60, 60)))))
                    for g in raw_gops]
            r = float(np.corrcoef(pred, human)[0, 1])
            if r > best[2]:
                best = (m, s, r)

    m, s, r = best
    print(f"\n跑了 {len(ours)} 条")
    print(f"最佳 m = {m:.2f}   s = {s:.2f}   Pearson r = {r:.3f}")
    print("\n参考：已发表的 GOP-CTC 基线大致 0.55~0.65。")
    if r < 0.4:
        print("低于 0.4 说明链路有问题（多半是 espeak 方言或词表切分失配），")
        print("不是调 m/s 能救的。先看 /v1/score 的 unmappedPhones。")
    if apply and m is not None:
        calib.save({"m": round(float(m), 2), "s": round(float(s), 2)})
        print(f"\n已写入 {calib.path()}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="校准 GOP -> 分数 的映射")
    ap.add_argument("dir", nargs="?", default="", help="自录样本目录（wav + 同名 txt）")
    ap.add_argument("--corpus", default="", help="speechocean762 解压后的目录")
    ap.add_argument("--models", default="", help="模型根目录")
    ap.add_argument("--apply", action="store_true", help="直接写进 calib.json")
    args = ap.parse_args()

    if not model_mod.is_installed(args.models):
        print("模型没装。跑：python install.py")
        return 1
    if args.corpus:
        return corpus_mode(args.corpus, args.models, args.apply)
    if args.dir:
        return self_mode(args.dir, args.models, args.apply)
    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
