"""装发音评测模型。

    python install.py            # 下载
    python install.py --check    # 只检查装没装全
    python install.py --force    # 重下（先清 .ok）

**必须绕开代理**。这是 1.26 GB 的权重，走代理既慢又烧流量——
server/ai/modelscope_dl.py 的文件头记着实测数据：直连 16 MB/s，
挂 http_proxy 只有 30 KB/s，差两个多数量级。modelscope_dl.session()
里的 trust_env=False 就是干这个的，本文件全程走它，不碰 HuggingFace。
"""

import argparse
import os
import sys

import model
import modelscope_dl


def _warn_proxy() -> None:
    """代理环境变量在的话说一声，免得用户以为下载在走代理而白等。"""
    names = ["http_proxy", "https_proxy", "all_proxy",
             "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"]
    found = [n for n in names if os.environ.get(n)]
    if found:
        print(f"检测到代理环境变量 {', '.join(found)}——已绕开，直连 ModelScope。")
        print("（这 1.26 GB 走代理会慢两个数量级，而且白烧代理流量。）")


def _to_safetensors(d: str) -> bool:
    """把 pytorch_model.bin 转成 model.safetensors，成功后删掉 .bin。

    ModelScope 上只有 .bin。transformers 5.x 走 .bin 要经过 torch.load，
    而 torch 2.6 起 weights_only 默认变成 True，这条路径在版本组合上很脆。
    safetensors 是纯张量容器，没有反序列化风险，加载也更快，一次转换永久受益。

    转失败不算致命——model.weight_path() 会退回 .bin，大概率还是能加载。
    """
    src = os.path.join(d, model.WEIGHT_FILE)
    dst = os.path.join(d, model.SAFETENSORS_FILE)
    if os.path.exists(dst):
        return True
    if not os.path.exists(src):
        return False
    try:
        import torch
        from safetensors.torch import save_file
    except ImportError as e:
        print(f"  转 safetensors 跳过（缺 {e.name}），继续用 .bin")
        return False

    print("  转 safetensors ...", end="", flush=True)
    try:
        sd = torch.load(src, map_location="cpu", weights_only=True)
        # 权重共享（tied weights）时 safetensors 会拒绝保存共享存储，
        # 所以统一 clone 成独立张量再存。1.2 GB 的峰值内存，可接受。
        sd = {k: v.clone().contiguous() for k, v in sd.items()
              if hasattr(v, "clone")}
        save_file(sd, dst + ".part", metadata={"format": "pt"})
        os.replace(dst + ".part", dst)
        os.remove(src)
        print(" 好了，已删掉 .bin")
        return True
    except Exception as e:
        print(f" 失败（{e}），继续用 .bin")
        for p in (dst, dst + ".part"):
            if os.path.exists(p):
                os.remove(p)
        return False


def check(root: str = "") -> bool:
    d = model.model_dir(root)
    miss = model.missing_files(root)
    print(f"模型目录：{d}")
    print(f"占磁盘：{model.disk_usage(root) / 1e9:.2f} GB")
    if miss:
        print(f"缺文件：{', '.join(miss)}")
        print("装好了没：否")
        return False
    print(f"装好了没：{'是' if model.is_installed(root) else '否（文件齐了但没有 .ok 标记）'}")
    return model.is_installed(root)


def install(root: str = "", force: bool = False) -> bool:
    d = model.model_dir(root)

    if model.is_installed(root) and not force:
        print(f"已装好，跳过：{d}")
        return True

    _warn_proxy()
    model.clear_ok(root)
    os.makedirs(d, exist_ok=True)

    print(f"从 ModelScope 下 {model.MODEL_ID}")
    print(f"到 {d}")

    # 先拉清单拿真实大小：modelscope_dl.fetch 用它判断"已存在且大小对得上就跳过"，
    # 这就是断点续传在文件粒度上的表现——重跑一次不会把已下好的再下一遍。
    try:
        files = modelscope_dl.file_list(model.MODEL_ID)
    except Exception as e:
        print(f"拿文件清单失败：{e}")
        return False
    sizes = dict(files)

    want = [n for n in model.REQUIRED_FILES if n in sizes]
    lost = [n for n in model.REQUIRED_FILES if n not in sizes]
    if lost:
        # 仓库结构变了。宁可停下来让人看一眼，也别下一半装个残废的。
        print(f"仓库里没有这些文件，可能上游结构变了：{', '.join(lost)}")
        return False

    total = sum(sizes[n] for n in want)
    print(f"共 {len(want)} 个文件，{total / 1e9:.2f} GB\n")

    try:
        modelscope_dl.fetch(model.MODEL_ID, want, d, sizes=sizes)
    except Exception as e:
        print(f"\n下载失败：{e}")
        print("重跑一次会从断点继续（.part 文件带 Range 续传）。")
        return False

    _to_safetensors(d)

    miss = model.missing_files(root)
    if miss:
        print(f"下完了但还缺：{', '.join(miss)}")
        return False

    model.mark_ok(root)
    print(f"\n装好了：{d}")
    print(f"占磁盘 {model.disk_usage(root) / 1e9:.2f} GB")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description="装发音评测模型（走 ModelScope，绕代理）")
    ap.add_argument("--models", default="", help=f"模型根目录，默认 {model.DEFAULT_MODEL_ROOT}")
    ap.add_argument("--check", action="store_true", help="只检查，不下载")
    ap.add_argument("--force", action="store_true", help="重下")
    args = ap.parse_args()

    if args.check:
        return 0 if check(args.models) else 1
    return 0 if install(args.models, args.force) else 1


if __name__ == "__main__":
    sys.exit(main())
