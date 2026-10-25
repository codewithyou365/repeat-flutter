"""装翻译 / 识别模型：从 ModelScope 下载，需要的话转成 CTranslate2 int8。

为什么从 ModelScope 拉：国内直连它是十几 MB/s，而 HuggingFace 走代理只有几十 KB/s。
**脚本会自己摘掉代理**再连（modelscope_dl 里 trust_env=False）。

为什么要转格式：CTranslate2 跑起来比 transformers 快好几倍、内存小得多。

    pip install -r requirements-mt.txt -i https://mirrors.aliyun.com/pypi/simple
    python setup_mt.py                          # 默认 opus-mt（小而快）
    python setup_mt.py --model nllb             # NLLB-600M（更准，慢几百 ms）
    python setup_mt.py --list
"""

import argparse
import os
import shutil
import subprocess
import sys

import catalog as cat
import modelscope_dl as ms

# 每个模型：ModelScope 仓库、要下哪些文件、转换后**留下**哪些（其余删掉省空间）
MODELS = {
    "opus-mt": {
        "id": "opus-mt-zh-en",
        "repo": "moxying/opus-mt-zh-en",
        # transformers 加载 Marian 要这些；权重最大，其余都是几 KB~1MB
        "need": ["pytorch_model.bin", "config.json", "generation_config.json",
                 "vocab.json", "source.spm", "target.spm", "tokenizer_config.json"],
        # 运行时只要两个 spm（分词是原始 sentencepiece + 手动补 </s>）
        "keep": ["source.spm", "target.spm"],
        "convert": True,
        "about": "约 80 MB，60ms 一句，日常够用",
    },
    "qwen": {
        "id": "qwen2.5-3b-instruct-mlx-4bit",
        "repo": "mlx-community/Qwen2.5-3B-Instruct-4bit",
        # 已经是 MLX 4bit 量化好的，**不用转换**，下下来直接能跑
        "need": None,          # None = 整个仓库都要
        "keep": None,
        "convert": False,
        "mlx": "mlx_lm",
        "about": "约 1.7 GB，跑苹果 GPU，复合词/习语最准",
    },
    "qwen7b": {
        "id": "qwen2.5-7b-instruct-mlx-4bit",
        "repo": "mlx-community/Qwen2.5-7B-Instruct-4bit",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_lm",
        "about": "约 4.3 GB，比 3B 更会遵循指令，跑苹果 GPU",
    },
    "hymt2": {
        "id": "hy-mt2-7b-mlx-8bit",
        "repo": "mlx-community/Hy-MT2-7B-8bit",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_lm",
        # 8bit 而不是 4bit：同一个模型，低比特量化最先掉的就是"别中英混着吐"
        # 这类指令遵循能力，而权重从 4.2 GB 涨到 8 GB 对 Mac 不算负担。
        "about": "约 8.0 GB，翻译专用模型（混元二代），口语和习语最稳，跑苹果 GPU",
    },
    "whisper-turbo": {
        "id": "whisper-large-v3-turbo-mlx",
        "repo": "mlx-community/whisper-large-v3-turbo",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_whisper",
        "about": "约 1.5 GB，识别跑苹果 GPU，中文比 small 准",
    },
    "whisper-large": {
        "id": "whisper-large-v3-mlx",
        "repo": "mlx-community/whisper-large-v3-mlx",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_whisper",
        "about": "约 2.9 GB，精度最高也最慢",
    },
    "qwen3asr": {
        "id": "qwen3-asr-1.7b-mlx-8bit",
        "repo": "mlx-community/Qwen3-ASR-1.7B-8bit",
        "need": None, "keep": None, "convert": False,
        # 运行时是 mlx-audio，不是 mlx-whisper——那几个 whisper 条目用不着这个包
        "mlx": "mlx_audio",
        "about": "约 2.3 GB，识别跑苹果 GPU，支持四川话等 22 种中国方言",
    },
    "qwen3tts": {
        "id": "qwen3-tts-0.6b-customvoice-mlx-bf16",
        # bf16 而不是 8bit：0.6B 量化只省 0.5 GB，不值得拿音质换
        "repo": "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-bf16",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_audio",
        "about": "约 2.5 GB，合成跑苹果 GPU，一句话里中日英混着也能念对",
    },
    "qwen3tts17": {
        "id": "qwen3-tts-1.7b-customvoice-mlx-8bit",
        "repo": "mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_audio",
        "about": "约 3.1 GB，0.6B 的大号，音质更好、慢一些",
    },
    "whisper-turbo-q4": {
        "id": "whisper-large-v3-turbo-q4-mlx",
        "repo": "mlx-community/whisper-large-v3-turbo-q4",
        "need": None, "keep": None, "convert": False,
        "mlx": "mlx_whisper",
        "about": "约 0.4 GB，4bit，中文可能掉精度",
    },
    "nllb": {
        "id": "nllb-200-distilled-600M",
        "repo": "facebook/nllb-200-distilled-600M",
        "need": ["pytorch_model.bin", "config.json", "generation_config.json",
                 "tokenizer.json", "tokenizer_config.json", "special_tokens_map.json",
                 "sentencepiece.bpe.model"],
        # 运行时分词交给 HF tokenizer，所以整套分词文件都要留
        "keep": ["tokenizer.json", "tokenizer_config.json", "special_tokens_map.json",
                 "sentencepiece.bpe.model"],
        "convert": True,
        "about": "约 620 MB，几百 ms 一句，复杂句式明显更准",
    },
}


def preflight(download_only: bool = False, which: str = "opus-mt") -> None:
    """把缺的依赖一次列全，别让人装一个撞一个。

    分两组：下载只要 requests，转换才要 ctranslate2/torch/transformers 那一坨。
    最常见的坑是拿系统 python3 跑，那边什么都没有。
    """
    here = os.path.dirname(os.path.abspath(__file__))
    # 不能拿 sys.executable 比路径：venv 里的 python 是符号链接，realpath 会解析到
    # Homebrew 那个真解释器。sys.prefix 才指向 venv 本身。
    in_venv = os.path.normpath(sys.prefix) == os.path.normpath(os.path.join(here, ".venv"))

    # 走 MLX 的模型在 MODELS 里自己声明要哪个包（mlx_lm / mlx_whisper），
    # 别在这儿维护一份模型名单——加一个模型就得改两处的写法迟早会漏。
    mlx_pkg = MODELS.get(which, {}).get("mlx")

    need = [("requests", "requirements.txt")]
    if not download_only:
        if mlx_pkg:
            # MLX 那条路和 CT2 完全无关，别让人白装 2GB 的 torch
            need += [("mlx", "requirements-llm.txt"), (mlx_pkg, "requirements-llm.txt")]
        else:
            need += [("ctranslate2", "requirements-mt.txt"),
                     ("transformers", "requirements-mt.txt"),
                     ("torch", "requirements-mt.txt"),
                     ("sentencepiece", "requirements-mt.txt")]
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
    req = "requirements-llm.txt" if mlx_pkg else "requirements-mt.txt"
    print(f"  pip install -r {req} -i https://mirrors.aliyun.com/pypi/simple")
    raise SystemExit(1)


def convert(src: str, dest_ct2: str) -> None:
    """用 ct2-transformers-converter 转成 int8。

    走子进程而不是 import：转换器是个命令行工具，而且它会把 torch 拉进来，
    跑完就随进程一起释放，不会赖在服务里占内存。
    """
    if os.path.isdir(dest_ct2) and os.listdir(dest_ct2):
        print("  ct2 目录已存在，跳过转换")
        return
    print("  转换中（几十秒到几分钟）…")
    tries = [[sys.executable, "-m", "ctranslate2.converters.transformers"]]
    alt = shutil.which("ct2-transformers-converter")
    if alt:
        tries.append([alt])
    last = None
    for base in tries:
        r = subprocess.run(base + ["--model", src, "--output_dir", dest_ct2,
                                   "--quantization", "int8", "--force"],
                           capture_output=True, text=True)
        if r.returncode == 0:
            print("  转换完成")
            return
        last = r
    tv = ""
    try:
        import transformers
        tv = transformers.__version__
    except Exception:
        pass
    hint = ""
    if tv and int(tv.split(".")[0]) >= 5:
        # ct2-transformers-converter 是按 transformers 4.x 写的，5.x 是大版本跨越
        hint = (f"\n\n你装的是 transformers {tv}。转换器按 4.x 写的，很可能不兼容。\n"
                f"试试临时降级（只影响转换）：\n"
                f"  pip install 'transformers<5' -i https://mirrors.aliyun.com/pypi/simple\n"
                f"  python setup_mt.py --model <同一个>\n"
                f"转完再装回去：pip install 'transformers=={tv}'")
    raise SystemExit(f"转换失败：\n{last.stdout[-2000:]}\n{last.stderr[-2000:]}{hint}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", default="opus-mt", choices=sorted(MODELS),
                    help="装哪个翻译模型")
    ap.add_argument("--models", default=cat.DEFAULT_MODEL_ROOT, help="模型目录")
    ap.add_argument("--list", action="store_true", help="列出可装的翻译模型")
    ap.add_argument("--download-only", action="store_true", help="只下载，不转换")
    ap.add_argument("--keep-src", action="store_true",
                    help="保留下载的原始权重（默认转换完就删）")
    args = ap.parse_args()

    if args.list:
        for k, m in MODELS.items():
            mark = "ok " if cat.is_installed(args.models, m["id"]) else "   "
            print(f"{mark}{k:10s} {m['id']:26s} {m['about']}")
        return 0

    preflight(args.download_only, args.model)
    spec = MODELS[args.model]
    mid = spec["id"]
    d = cat.model_dir(args.models, mid)
    raw = os.path.join(args.models, ".tmp", mid + "-hf")
    print(f"== {mid} -> {d}\n   {spec['about']}")

    print("1) 从 ModelScope 下载（绕过代理）")
    sizes = dict(ms.file_list(spec["repo"]))
    need = spec["need"] or list(sizes)
    print(f"   需要 {sum(sizes.get(p, 0) for p in need)/2**30:.2f} GB / {len(need)} 个文件")

    if not spec.get("convert", True):
        # 已经是目标格式（MLX 量化好的），直接下到模型目录，不经过 .tmp
        ms.fetch(spec["repo"], need, d, sizes=sizes)
        missing = cat.missing_files(args.models, cat.Catalog().by_id(mid))
        if missing:
            raise SystemExit(f"!! 还缺：{missing}")
        with open(os.path.join(d, cat.OK_MARKER), "w"):
            pass
        size = sum(os.path.getsize(os.path.join(r, f))
                   for r, _, fs in os.walk(d) for f in fs)
        print(f"\n装好了：{d}  ({size >> 20} MB)")
        print("现在去网页的「概览 → 当前生效」把它选上。")
        return 0

    ms.fetch(spec["repo"], need, raw, sizes=sizes)
    if args.download_only:
        print(f"\n下好了：{raw}\n再跑一次不带 --download-only 就会转换。")
        return 0

    print("2) 转成 CTranslate2 int8")
    os.makedirs(d, exist_ok=True)
    convert(raw, os.path.join(d, "ct2"))

    print("3) 摆好分词器")
    for name in spec["keep"]:
        shutil.copyfile(os.path.join(raw, name), os.path.join(d, name))

    if not args.keep_src:
        shutil.rmtree(raw, ignore_errors=True)
        print("   已删掉原始权重（--keep-src 可保留）")

    missing = cat.missing_files(args.models, cat.Catalog().by_id(mid))
    if missing:
        raise SystemExit(f"!! 还缺：{missing}")
    with open(os.path.join(d, cat.OK_MARKER), "w"):
        pass

    size = sum(os.path.getsize(os.path.join(r, f))
               for r, _, fs in os.walk(d) for f in fs)
    print(f"\n装好了：{d}  ({size >> 20} MB)")
    print("现在去网页的「概览 → 当前生效」把它选上。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
