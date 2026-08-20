"""S2ST 基准测试：SeamlessM4T v2 vs 现在的链式方案。

**这是个一次性的测量脚本，不接进服务。** 目的是在改两边界面之前先回答三个问题：

  1. 一段话要多久？现在整条链是 4.2 秒（其中 kokoro 合成占 2.4 秒）。
     S2ST 是 2.3B 参数的模型，很可能更慢——而这轮需求的起点恰恰是"反应太慢"。
  2. 译文质量到底好多少？拿用户实际翻错的那句「这个键盘有霉斑」当靶子。
  3. 能不能在出语音的同时拿到译文文本？（拿不到就是拿不到，不猜，脚本会明确报告。）

    pip install -r requirements-s2st.txt -i https://mirrors.aliyun.com/pypi/simple
    python bench_s2st.py                 # 下模型（8.6 GB）+ 跑测试
    python bench_s2st.py --skip-chain    # 只测 S2ST，不跑对照组
"""

import argparse
import os
import resource
import sys
import time

import catalog as cat
import modelscope_dl as ms

REPO = "AI-ModelScope/seamless-m4t-v2-large"
MODEL_ID = "seamless-m4t-v2-large"

# 只要 HF transformers 那套。仓库里还有 fairseq2 的 .pt（seamlessM4T_v2_large.pt 8.6GB +
# m4t_v2_multitask_unity2.pt 10.9GB），那是另一套加载路径，白下 19.5 GB。
NEED = [
    "model-00001-of-00002.safetensors",
    "model-00002-of-00002.safetensors",
    "model.safetensors.index.json",
    "config.json",
    "generation_config.json",
    "tokenizer_config.json",
    "special_tokens_map.json",
    "added_tokens.json",
    "preprocessor_config.json",
    "sentencepiece.bpe.model",
    "tokenizer.model",
    "spm_char_lang38_tc.model",
]

# 第一句就是用户实际翻错的那句
CASES = [
    "这个键盘有霉斑",
    "今天天气很好，我们一起去公园散步吧。",
]

# T2S 用的英文。刻意用对照组翻出来的那两句，这样和 kokoro 的 bench_chain_*.wav
# 是同一段文本、可以直接对着听。
T2S_CASES = [
    "The keyboard is not moving at all.",
    "The weather is good today. Let's go to the park together.",
]

OUT_DIR = "/tmp"


def preflight(download_only: bool = False) -> None:
    """把缺的依赖一次列全，别让人装一个撞一个。

    分两组：下载只要 requests/numpy，推理才要 torch 那一坨。
    这样 --download-only 可以先把 8.6 GB 拉下来，装依赖和下模型并行进行。

    最常见的坑是拿系统 python3 跑，那边什么都没有。
    """
    here = os.path.dirname(os.path.abspath(__file__))
    # 不能拿 sys.executable 比路径：venv 里的 python 是符号链接，realpath 会解析到
    # Homebrew 那个真解释器。sys.prefix 才指向 venv 本身。
    in_venv = os.path.normpath(sys.prefix) == os.path.normpath(os.path.join(here, ".venv"))

    need = [("requests", "requirements.txt"), ("numpy", "requirements.txt")]
    if not download_only:
        need += [("torch", "requirements-s2st.txt"),
                 ("transformers", "requirements-s2st.txt"),
                 ("sentencepiece", "requirements-s2st.txt")]
    missing = []
    for mod, why in need:
        try:
            __import__(mod)
        except ImportError:
            missing.append((mod, why))
    if not missing:
        return

    print("缺这些依赖：")
    for mod, why in missing:
        print(f"  - {mod:14s} (来自 {why})")
    print()
    if not in_venv and os.path.exists(os.path.join(here, ".venv", "bin", "python")):
        print(f"你现在用的是 {sys.executable}，不是项目的 venv。改成：")
        print(f"  cd {here}")
        print("  source .venv/bin/activate")
    else:
        print(f"  cd {here}")
    print("  pip install -r requirements-s2st.txt -i https://mirrors.aliyun.com/pypi/simple")
    print("  python bench_s2st.py")
    raise SystemExit(1)


def rss_gb() -> float:
    # macOS 上 ru_maxrss 是字节，Linux 上是 KB
    v = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return v / (1 << 30) if sys.platform == "darwin" else v / (1 << 20)


def make_input(root: str, text: str):
    """用 MeloTTS 合一句中文当输入。

    别用 kokoro 合中文：它的 zh 词典不全，之前试过满屏 `Ignore OOV`，
    出来是噪音，whisper 听成 '(字'——白测一轮。
    """
    import numpy as np
    import engine
    import wav as wavmod

    tts = engine.get_tts(cat.Catalog(), root, "vits-melo-tts-zh_en")
    s, rate = engine.synthesize(tts, text)
    if s is None:
        raise SystemExit(f"合成输入失败（MeloTTS 装了吗？）: {text!r}")
    n = int(s.size * 16000 / rate)
    a16 = np.interp(np.linspace(0, s.size - 1, n), np.arange(s.size), s).astype(np.float32)
    return a16, wavmod.duration_ms(n, 16000)


def bench_seamless(model_dir: str, cases, repeats: int, t2s_only: bool = False):
    import numpy as np
    import torch
    from transformers import AutoProcessor, SeamlessM4Tv2Model
    import wav as wavmod

    print(f"\n加载 SeamlessM4T v2（8.6 GB，第一次要一会儿）…")
    t0 = time.time()
    processor = AutoProcessor.from_pretrained(model_dir)
    model = SeamlessM4Tv2Model.from_pretrained(model_dir, torch_dtype=torch.float32)
    model.eval()
    print(f"  加载耗时 {time.time()-t0:.1f}s   峰值内存 {rss_gb():.1f} GB")

    root = cat.DEFAULT_MODEL_ROOT
    reported_text_with_speech = None

    for text, (audio, dur) in ({} if t2s_only else cases).items():
        print(f"\n=== 输入: {text!r}  ({dur} ms)")
        # transformers 4.5x 把 audios 改名成 audio，老名字会直接抛 ValueError。
        # 两个都试，省得为一个 kwarg 名去锁版本。
        try:
            inputs = processor(audio=audio, sampling_rate=16000, return_tensors="pt")
        except (TypeError, ValueError):
            inputs = processor(audios=audio, sampling_rate=16000, return_tensors="pt")

        # --- S2TT：只要译文文本
        ts = []
        out_txt = None
        for _ in range(repeats):
            t = time.time()
            with torch.inference_mode():
                out_txt = model.generate(**inputs, tgt_lang="eng", generate_speech=False)
            ts.append(int((time.time() - t) * 1000))
        ids = out_txt[0] if not hasattr(out_txt, "sequences") else out_txt.sequences
        s2tt = processor.decode(ids.tolist()[0], skip_special_tokens=True)
        print(f"  S2TT  {ts}  ms   -> {s2tt!r}")

        # --- S2ST：要译文语音
        ts = []
        out = None
        for _ in range(repeats):
            t = time.time()
            with torch.inference_mode():
                out = model.generate(**inputs, tgt_lang="eng")
            ts.append(int((time.time() - t) * 1000))

        # 能不能同时拿到文本？这是计划里明确的检查项，不猜。
        seq = getattr(out, "sequences", None)
        if reported_text_with_speech is None:
            reported_text_with_speech = seq is not None
            print(f"  [检查] generate(生成语音) 同时给文本 token: "
                  f"{'是' if seq is not None else '否 —— 要文本得再跑一次 S2TT'}")
        if seq is not None:
            try:
                print(f"         同步拿到的译文: {processor.decode(seq.tolist()[0], skip_special_tokens=True)!r}")
            except Exception as e:
                print(f"         (解码失败: {e})")

        wave = out.waveform if hasattr(out, "waveform") else out[0]
        arr = wave.cpu().numpy().squeeze().astype(np.float32)
        sr = int(model.config.sampling_rate)
        name = os.path.join(OUT_DIR, f"bench_s2st_{abs(hash(text)) % 10000}.wav")
        with open(name, "wb") as f:
            f.write(wavmod.write(arr, sr))
        print(f"  S2ST  {ts}  ms   -> {wavmod.duration_ms(arr.size, sr)} ms 语音  {name}")

    # --- T2S：只拿它当 TTS 用（文本 -> 语音）
    #
    # 为什么值得单独测：S2ST 和 S2TT 的差值只有 1 秒左右，说明"发声"这步很便宜，
    # 慢的是那 2.3B 参数的翻译。如果只借它的嘴、翻译交给 opus-mt（几十毫秒），
    # 整条链可能比现在的 kokoro 方案还快，而且声音更自然。
    print("\n=== T2S（只当 TTS 用：英文文本 -> 英文语音）")
    for en in T2S_CASES:
        ti = processor(text=en, src_lang="eng", return_tensors="pt")
        ts = []
        out = None
        for _ in range(repeats):
            t = time.time()
            with torch.inference_mode():
                out = model.generate(**ti, tgt_lang="eng")
            ts.append(int((time.time() - t) * 1000))
        wave = out.waveform if hasattr(out, "waveform") else out[0]
        arr = wave.cpu().numpy().squeeze().astype(np.float32)
        sr = int(model.config.sampling_rate)
        name = os.path.join(OUT_DIR, f"bench_t2s_{abs(hash(en)) % 10000}.wav")
        with open(name, "wb") as f:
            f.write(wavmod.write(arr, sr))
        print(f"  {ts} ms  -> {wavmod.duration_ms(arr.size, sr)} ms 语音  {name}")
        print(f"     {en!r}")

    print(f"\n峰值内存 {rss_gb():.1f} GB")


def bench_chain(root: str, cases, repeats: int):
    """对照组：现在服务里跑的那条链。"""
    import engine
    import wav as wavmod

    cl = cat.Catalog()
    picks = {}
    for role, prefer in (("asr", "paraformer-zh"), ("mt", "whisper-small-int8"),
                         ("tts", "kokoro-int8-multi-lang-v1_0")):
        cand = [prefer] + [m.id for m in cl.by_role(role)]
        picks[role] = next((c for c in cand if cat.is_installed(root, c)), None)
    if not all(picks.values()):
        print(f"\n对照组跳过：缺模型 {picks}")
        return
    print(f"\n=== 对照组（链式）asr={picks['asr']} mt={picks['mt']} tts={picks['tts']}")

    for text, (audio, dur) in cases.items():
        r_asr = engine.get_recognizer(cl, root, picks["asr"], "zh", "transcribe")
        r_mt = engine.get_recognizer(cl, root, picks["mt"], "zh", "translate")
        tts = engine.get_tts(cl, root, picks["tts"])
        stages = {"asr": [], "mt": [], "tts": []}
        src = dst = ""
        out = None
        rate = 0
        for _ in range(repeats):
            t = time.time(); src = engine.recognize(r_asr, audio); stages["asr"].append(int((time.time()-t)*1000))
            t = time.time(); dst = engine.recognize(r_mt, audio);  stages["mt"].append(int((time.time()-t)*1000))
            t = time.time(); out, rate = engine.synthesize(tts, dst); stages["tts"].append(int((time.time()-t)*1000))
        total = min(stages["asr"]) + min(stages["mt"]) + min(stages["tts"])
        print(f"\n  输入 {text!r} ({dur} ms)")
        print(f"    识别 {stages['asr']} ms -> {src!r}")
        print(f"    翻译 {stages['mt']} ms -> {dst!r}")
        print(f"    合成 {stages['tts']} ms")
        print(f"    热态合计约 {total} ms")
        if out is not None:
            name = os.path.join(OUT_DIR, f"bench_chain_{abs(hash(text)) % 10000}.wav")
            with open(name, "wb") as f:
                f.write(wavmod.write(out, rate))
            print(f"    语音 {name}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--models", default=cat.DEFAULT_MODEL_ROOT)
    ap.add_argument("--repeats", type=int, default=3, help="每种模式跑几次（取热态）")
    ap.add_argument("--skip-chain", action="store_true", help="不跑对照组")
    ap.add_argument("--t2s-only", action="store_true",
                    help="只测 T2S（把它当 TTS 用），跳过 S2TT/S2ST")
    ap.add_argument("--download-only", action="store_true", help="只下模型，不跑测试")
    ap.add_argument("--install", action="store_true",
                    help="下完后写 .ok，让它作为 TTS 出现在网页的可选列表里")
    args = ap.parse_args()

    preflight(args.download_only or args.install)

    d = cat.model_dir(args.models, MODEL_ID)
    print(f"== {MODEL_ID} -> {d}")
    print("1) 从 ModelScope 下载（绕过代理，只取 HF 那套，跳过 19.5 GB 的 fairseq2 权重）")
    sizes = dict(ms.file_list(REPO))
    want = sum(sizes.get(p, 0) for p in NEED)
    print(f"   需要 {want/2**30:.2f} GB / {len(NEED)} 个文件")
    ms.fetch(REPO, NEED, d, sizes=sizes)

    if args.install:
        # 写 .ok 它才算"装好"，网页才会把它列进 TTS 的下拉。
        # 校验交给 catalog.missing_files（按 cfg.require），别自己再列一遍。
        entry = cat.Catalog().by_id(MODEL_ID)
        missing = cat.missing_files(args.models, entry)
        if missing:
            raise SystemExit(f"!! 还缺：{missing}")
        with open(os.path.join(d, cat.OK_MARKER), "w"):
            pass
        print(f"\n已标记为装好。去网页「概览 → 当前生效 → 合成」把它选上。")
        print("注意：它只当 TTS 用，翻译仍走 mt 那一档。")
        return 0

    if args.download_only:
        return 0

    print("\n2) 准备输入（MeloTTS 合中文）")
    cases = {t: make_input(args.models, t) for t in CASES}

    if not args.skip_chain:
        bench_chain(args.models, cases, args.repeats)
    bench_seamless(d, cases, args.repeats, args.t2s_only)

    print("\n" + "=" * 60)
    print("判定门槛（计划里定的）：")
    print("  热态每段 <= 6 秒 且 译文明显更好  -> 继续做集成")
    print("  > 10 秒 或 质量没提升            -> 退回 opus-mt-zh-en（80MB，已写好）")
    print(f"语音都在 {OUT_DIR}/bench_*.wav，自己听一下语调自然不自然。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
