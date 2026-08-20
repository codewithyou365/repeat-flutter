"""从 ModelScope 下文件。`setup_mt.py` 和 `bench_s2st.py` 共用。

**必须绕开代理**：实测 ModelScope 直连 16 MB/s，挂着 http_proxy 只有 30 KB/s——
差两个多数量级。requests 默认会读 http_proxy 环境变量，所以这里一律 trust_env=False。

断点续传照 downloader.py 那套：写 .part，带 Range 重试，成功才原子改名。
几个 GB 的权重断在半路重下一遍太亏。
"""

import os
import time
from typing import Callable, List, Optional

BASE = "https://www.modelscope.cn/models/{repo}/resolve/{rev}/{path}"
CHUNK = 1 << 20
STREAM_CHUNK = 1 << 18


def session():
    import requests
    s = requests.Session()
    # ModelScope 在国内直连最快，走代理反而慢两个数量级
    s.trust_env = False
    return s


def file_list(repo: str, rev: str = "master"):
    """仓库里的文件清单 [(path, size)]。"""
    s = session()
    r = s.get(f"https://www.modelscope.cn/api/v1/models/{repo}/repo/files",
              params={"Revision": rev}, timeout=30)
    r.raise_for_status()
    fs = r.json().get("Data", {}).get("Files", [])
    return [(f["Path"], f.get("Size") or 0) for f in fs if f.get("Type") == "blob"]


def download(repo: str, path: str, dest: str, rev: str = "master",
             on_progress: Optional[Callable[[int, int], None]] = None,
             retries: int = 6) -> None:
    """下单个文件到 dest，断了带 Range 续传。"""
    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    tmp = dest + ".part"
    url = BASE.format(repo=repo, rev=rev, path=path)
    s = session()

    for attempt in range(retries):
        done = os.path.getsize(tmp) if os.path.exists(tmp) else 0
        headers = {"Range": f"bytes={done}-"} if done else {}
        try:
            with s.get(url, stream=True, timeout=60, headers=headers) as r:
                if done and r.status_code == 200:
                    done = 0  # 服务端不认 Range，只能从头来
                r.raise_for_status()
                total = int(r.headers.get("content-length") or 0) + done
                with open(tmp, "wb" if done == 0 else "ab") as f:
                    for chunk in r.iter_content(STREAM_CHUNK):
                        f.write(chunk)
                        done += len(chunk)
                        if on_progress:
                            on_progress(done, total)
            os.replace(tmp, dest)
            return
        except Exception:
            if attempt == retries - 1:
                raise
            time.sleep(2 * (attempt + 1))


def fetch(repo: str, paths: List[str], dest_dir: str, rev: str = "master",
          sizes: Optional[dict] = None) -> None:
    """按清单下一批文件到 dest_dir，已存在且大小对得上的跳过。"""
    os.makedirs(dest_dir, exist_ok=True)
    for i, p in enumerate(paths):
        out = os.path.join(dest_dir, p)
        want = (sizes or {}).get(p, 0)
        if os.path.exists(out) and (not want or os.path.getsize(out) == want):
            print(f"  [{i+1}/{len(paths)}] {p} 已有，跳过")
            continue
        label = f"  [{i+1}/{len(paths)}] {p}"
        print(label, end="", flush=True)

        def prog(d, t, _l=label):
            if not t:
                return
            # 小文件按 KB 显示，不然清一色 "0/0 MB" 看着像卡住了
            unit, sh = ("MB", 20) if t >= (1 << 20) else ("KB", 10)
            print(f"\r{_l} {d*100//t:3d}%  {d>>sh}/{t>>sh} {unit}", end="", flush=True)

        download(repo, p, out, rev, on_progress=prog)
        print()
