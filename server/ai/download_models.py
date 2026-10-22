"""按 catalog.json 把模型下到服务端（命令行版）。

网页上也能下（http://<ip>:8767/ 每个模型都有「下载」按钮），两边共用
downloader.py 的同一套续传/校验逻辑。命令行适合批量和无人值守。

    python download_models.py --preset lite
    python download_models.py whisper-turbo-int8
    python download_models.py --list
    python download_models.py --preset lite --source cn      # 国内镜像
"""

import argparse
import os
import shutil
import sys

import catalog as cat
import downloader as dl


def install(cl: cat.Catalog, root: str, model_id: str, source: dl.Source) -> bool:
    entry = cl.by_id(model_id)
    if entry is None:
        print(f"!! unknown model: {model_id}")
        return False
    if cat.is_installed(root, model_id):
        print(f"== {model_id} already installed")
        return True

    print(f"== {model_id}  ({entry.size >> 20} MB)")
    state = {"name": ""}

    def on_file(i, total, name):
        state["name"] = name
        print(f"\n   [{i + 1}/{total}] {name}")

    def on_progress(done, total):
        if total:
            print(f"\r   {done * 100 // total:3d}%  {done >> 20}/{total >> 20} MB", end="", flush=True)

    try:
        dl.install(cl, root, model_id, source, on_file=on_file, on_progress=on_progress)
    except Exception as e:
        # 一个模型下不动不该把整批都带崩：报清楚，接着下一个。
        # .part 留在原地，重跑这条命令会从断点接着要。
        print(f"\n!! {model_id}: {type(e).__name__}: {e}")
        return False
    print(f"\n   done -> {cat.model_dir(root, model_id)}")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*", help="模型 id")
    ap.add_argument("--preset", help="预设 id: lite / quality / zh")
    ap.add_argument("--list", action="store_true", help="列出清单里的模型和安装状态")
    ap.add_argument("--catalog", default=cat.DEFAULT_CATALOG)
    ap.add_argument("--models", default=cat.DEFAULT_MODEL_ROOT)
    ap.add_argument("--source", choices=["official", "cn", "custom", "saved"], default="saved",
                    help="下载源；saved = 用网页上存的那个设置")
    ap.add_argument("--hf-host", default="", help="--source custom 时的 HuggingFace 镜像域名")
    ap.add_argument("--gh-prefix", default="", help="--source custom 时的 GitHub 加速前缀")
    args = ap.parse_args()

    cl = cat.Catalog(args.catalog)
    root = args.models

    if args.list:
        for m in cl.models:
            mark = "ok " if cat.is_installed(root, m.id) else "   "
            only = "[仅服务端] " if cl.is_local_only(m.id) else ""
            print(f"{mark}{m.id:32s} {','.join(m.roles):8s} {m.size >> 20:5d} MB  {only}{m.name}")
        print("\npresets: " + "  ".join(f"{k}={','.join(v)}" for k, v in cl.presets.items()))
        return 0

    source = dl.Source.load(root) if args.source == "saved" else dl.Source(
        args.source, args.hf_host, args.gh_prefix)
    hf, gh = source.effective
    print(f"下载源: {source.kind}" + (f"  hf={hf} gh={gh}" if hf or gh else ""))

    ids = list(args.ids)
    if args.preset:
        if args.preset not in cl.presets:
            print(f"!! unknown preset: {args.preset}; have {list(cl.presets)}")
            return 2
        ids = cl.presets[args.preset] + ids
    if not ids:
        ap.print_help()
        return 2

    # VAD 只在手机上跑，服务端下了也用不到，直接跳过
    ids = [i for i in dict.fromkeys(ids) if "vad" not in (cl.by_id(i).roles if cl.by_id(i) else [])]

    ok = True
    for i in ids:
        ok = install(cl, root, i, source) and ok
    if ok:
        # 只有全下完了才清暂存：失败时 .part 留着，重跑能续传
        shutil.rmtree(os.path.join(root, ".tmp"), ignore_errors=True)
    else:
        print("\n!! 有模型没下完。重跑同一条命令会从断点接着下；"
              "国内网络加 --source cn")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
