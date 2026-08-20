"""扫描线程数对各阶段的影响。

起因：默认 min(8, CPU核数)，但线程多不等于快——sherpa 的 TTS/ASR 和 CTranslate2
各有各的并行上限，过了拐点再加只会多花调度开销，甚至变慢（尤其 M 系列的能效核）。

    python bench_threads.py
    python bench_threads.py --threads 1,2,4,6,8,10
"""

import argparse
import os
import sys
import time

import catalog as cat

TEXT_ZH = "这个键盘的保护膜破了，我想换一个新的"
TEXT_EN = "The protective film on this keyboard is torn. I want a new one."


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--models", default=cat.DEFAULT_MODEL_ROOT)
    ap.add_argument("--threads", default="", help="逗号分隔，默认按核数铺开")
    ap.add_argument("--repeats", type=int, default=3)
    ap.add_argument("--wav", default="", help="拿真实录音测识别；不给就用 TTS 合一段")
    args = ap.parse_args()

    import numpy as np
    import engine
    import text_mt
    import wav as wavmod

    cl = cat.Catalog()
    root = args.models
    ncpu = os.cpu_count() or 8
    if args.threads:
        counts = [int(x) for x in args.threads.split(",") if x.strip()]
    else:
        counts = sorted({1, 2, 4, 6, 8, ncpu})
    counts = [c for c in counts if c >= 1]

    # 挑当前装好的模型
    def pick(role, prefer):
        for c in [prefer] + [m.id for m in cl.by_role(role)]:
            if cat.is_installed(root, c):
                return c
        return None

    asr = pick("asr", "paraformer-zh")
    tts = pick("tts", "kokoro-int8-multi-lang-v1_0")
    mt = next((m.id for m in cl.by_role("mt")
               if m.kind == "text" and cat.is_installed(root, m.id)), None)
    print(f"CPU {ncpu} 核   asr={asr}  mt={mt}  tts={tts}")
    print(f"线程数扫描: {counts}\n")

    # 准备一段音频
    if args.wav:
        audio, sr = wavmod.read(open(args.wav, "rb").read())
    else:
        t = engine.get_tts(cl, root, "vits-melo-tts-zh_en")
        s, rate = engine.synthesize(t, TEXT_ZH)
        n = int(s.size * 16000 / rate)
        audio = np.interp(np.linspace(0, s.size - 1, n), np.arange(s.size), s).astype(np.float32)
        engine.drop_cache()
    dur = wavmod.duration_ms(audio.size, 16000)
    print(f"测试音频 {dur} ms\n")

    def timed(fn):
        fn()                      # 预热，第一次含加载
        ts = [ ]
        for _ in range(args.repeats):
            t0 = time.time(); fn(); ts.append(int((time.time() - t0) * 1000))
        return min(ts)

    rows = []
    for n in counts:
        # num_threads() 每次都读环境变量；模型是按线程数构造的，所以必须清缓存重建
        os.environ["REPEAT_AI_THREADS"] = str(n)
        engine.drop_cache()
        text_mt.drop_cache()

        r_asr = engine.get_recognizer(cl, root, asr, "zh", "transcribe") if asr else None
        a = timed(lambda: engine.recognize(r_asr, audio)) if r_asr else 0

        m = 0
        if mt:
            e = cl.by_id(mt)
            tr = text_mt.get(mt, cat.model_dir(root, mt), e.cfg, n)
            m = timed(lambda: tr.translate(TEXT_ZH))

        t_ = 0
        if tts:
            inst = engine.get_tts(cl, root, tts)
            t_ = timed(lambda: engine.synthesize(inst, TEXT_EN, sid=5))
        rows.append((n, a, m, t_, a + m + t_))

    base = rows[0][4] if rows else 1
    print(f"{'线程':>4}  {'识别':>7}  {'翻译':>7}  {'合成':>7}  {'合计':>7}   相对最快")
    best = min(r[4] for r in rows)
    for n, a, m, t_, tot in rows:
        mark = "  <-- 最快" if tot == best else ""
        print(f"{n:>4}  {a:>6}ms  {m:>6}ms  {t_:>6}ms  {tot:>6}ms   {tot/best:.2f}x{mark}")
    print(f"\n实时率（合计/音频时长）最好 {best/dur:.2f}")
    print("设置：REPEAT_AI_THREADS=<n> ./run.sh")
    return 0


if __name__ == "__main__":
    sys.exit(main())
