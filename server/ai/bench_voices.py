"""把 TTS 模型的多个音色各合一句，摆在一起听。

起因：SeamlessM4T 的声音更自然，但它当 TTS 用要 2.9–4.5 秒、实时率 1.27（跟不上说话），
还得常驻 8.6 GB。而 kokoro 有 53 个音色，现在用的 sid=5 未必是好听的那个——
换一个是零成本的，值得先试。

    python bench_voices.py                      # 默认 kokoro，采样 8 个音色
    python bench_voices.py --all                # 全部 53 个（慢）
    python bench_voices.py --sids 0,5,10,20     # 只听这几个
    python bench_voices.py --model vits-melo-tts-zh_en
"""

import argparse
import os
import sys
import time

import catalog as cat

TEXT = "The weather is good today. Let's go to the park together."
OUT_DIR = "/tmp/bench_voices"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--models", default=cat.DEFAULT_MODEL_ROOT)
    ap.add_argument("--model", default="kokoro-int8-multi-lang-v1_0")
    ap.add_argument("--text", default=TEXT)
    ap.add_argument("--sids", default="", help="逗号分隔的音色 id；不给就均匀采样")
    ap.add_argument("--count", type=int, default=8, help="均匀采样几个")
    ap.add_argument("--all", action="store_true", help="全部音色")
    args = ap.parse_args()

    import engine
    import wav as wavmod

    cl = cat.Catalog()
    entry = cl.by_id(args.model)
    if entry is None:
        raise SystemExit(f"清单里没有 {args.model}")
    if not cat.is_installed(args.models, args.model):
        raise SystemExit(f"{args.model} 还没装")

    total = max(1, entry.speakers)
    if args.sids:
        sids = [int(x) for x in args.sids.split(",") if x.strip() != ""]
    elif args.all:
        sids = list(range(total))
    else:
        # 均匀铺开，别都挤在开头——相邻的音色往往很像
        step = max(1, total // args.count)
        sids = list(range(0, total, step))[:args.count]
    sids = [s for s in sids if 0 <= s < total]

    os.makedirs(OUT_DIR, exist_ok=True)
    tts = engine.get_tts(cl, args.models, args.model)
    print(f"{entry.name}  共 {total} 个音色，试听 {len(sids)} 个")
    print(f"文本: {args.text!r}\n")

    for sid in sids:
        t = time.time()
        out, rate = engine.synthesize(tts, args.text, sid=sid, speed=1.0)
        ms = int((time.time() - t) * 1000)
        if out is None:
            print(f"  sid={sid:<3d} 没合成出东西")
            continue
        dur = wavmod.duration_ms(out.size, rate)
        name = os.path.join(OUT_DIR, f"{args.model}_sid{sid:03d}.wav")
        with open(name, "wb") as f:
            f.write(wavmod.write(out, rate))
        # 实时率 >1 表示合成比说话还慢，连续录音时队列会堆
        print(f"  sid={sid:<3d} {ms:5d} ms  音频 {dur:5d} ms  实时率 {ms/dur:.2f}  {name}")

    print(f"\n都在 {OUT_DIR}/，挑好之后在网页「概览 → 当前生效 → 音色」里选。")
    print("对比参照：/tmp/bench_t2s_1136.wav 是 SeamlessM4T 合的同一句。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
