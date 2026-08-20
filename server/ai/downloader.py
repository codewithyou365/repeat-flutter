"""模型下载的核心：下载源改写、断点续传、校验、解压。

命令行（download_models.py）和网页（server.py）共用这一份。之前这些逻辑只长在
CLI 里，网页要用就得抄一遍——抄出来的两份迟早会不一致，尤其是续传和校验这种
边界很多的地方。

对应的手机端实现在 lib/logic/ai/ai_model_help.dart 和 ai_download_source.dart。
"""

import hashlib
import json
import os
import shutil
import tarfile
import time
import zipfile
from typing import Callable, Dict, Optional

import requests

import catalog as cat

CHUNK = 1 << 20
# 流式读的块比写的块小：取消标志一块只能查一次，1MB 在慢网上要等好几秒才响应。
STREAM_CHUNK = 1 << 18

# 下载源。名字和手机端 AiDownloadSource 保持一致。
CN_HF_HOST = "hf-mirror.com"
CN_GH_PREFIX = "https://ghfast.top/"

# 进度回调：(已下字节, 总字节)。总字节为 0 表示服务端没给 Content-Length。
ProgressFn = Callable[[int, int], None]
# 返回 True 表示用户按了取消
StopFn = Callable[[], bool]


class Cancelled(Exception):
    pass


class Source:
    """当前下载源。存在模型目录旁边，重启后还在。"""

    def __init__(self, kind: str = "official", hf_host: str = "", gh_prefix: str = ""):
        self.kind = kind if kind in ("official", "cn", "custom") else "official"
        self.hf_host = hf_host
        self.gh_prefix = gh_prefix

    @property
    def effective(self):
        if self.kind == "cn":
            return CN_HF_HOST, CN_GH_PREFIX
        if self.kind == "custom":
            return self.hf_host, self.gh_prefix
        return "", ""

    def to_json(self) -> Dict[str, str]:
        return {"kind": self.kind, "hfHost": self.hf_host, "ghPrefix": self.gh_prefix}

    @staticmethod
    def path(root: str) -> str:
        return os.path.join(os.path.dirname(os.path.abspath(root)), "source.json")

    @staticmethod
    def load(root: str) -> "Source":
        try:
            with open(Source.path(root), "r", encoding="utf-8") as f:
                d = json.load(f)
            return Source(d.get("kind", "official"), d.get("hfHost", ""), d.get("ghPrefix", ""))
        except (OSError, ValueError):
            return Source()

    def save(self, root: str) -> None:
        os.makedirs(os.path.dirname(Source.path(root)), exist_ok=True)
        with open(Source.path(root), "w", encoding="utf-8") as f:
            json.dump(self.to_json(), f)


def rewrite(url: str, source: Source) -> str:
    hf_host, gh_prefix = source.effective
    if hf_host and "huggingface.co" in url:
        return url.replace("huggingface.co", hf_host, 1)
    if gh_prefix and ("github.com" in url or "objects.githubusercontent.com" in url):
        # 已经带前缀的不要再套一层
        return url if url.startswith(gh_prefix) else gh_prefix + url
    return url


def sha1(path: str) -> str:
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(CHUNK), b""):
            h.update(b)
    return h.hexdigest()


def verify(path: str, f: cat.ModelFile) -> bool:
    """有 sha1 就比 sha1，没有就比大小，都没有就看存在与否。

    catalog.local.json 里那几个大模型上游没给 sha1，只能退到比大小。
    """
    if not os.path.exists(path):
        return False
    if f.hash:
        return sha1(path) == f.hash
    if f.size:
        return os.path.getsize(path) == f.size
    return True


def download(url: str, dest: str, on_progress: Optional[ProgressFn] = None,
             should_stop: Optional[StopFn] = None, retries: int = 6) -> None:
    """下到 dest。断了就带 Range 续传重试。

    模型动辄一两百 MB，一次连接从头拉到尾对着 HuggingFace 经常撑不住
    （IncompleteRead / Connection broken）。从头再来一遍太浪费，所以 .part
    留着，下一次从断点接着要。
    """
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".part"

    for attempt in range(retries):
        if should_stop and should_stop():
            raise Cancelled()
        done = os.path.getsize(tmp) if os.path.exists(tmp) else 0
        headers = {"Range": f"bytes={done}-"} if done else {}
        try:
            with requests.get(url, stream=True, timeout=60, headers=headers) as r:
                if done and r.status_code == 200:
                    done = 0  # 服务端不认 Range，只能从头来
                r.raise_for_status()
                total = int(r.headers.get("content-length") or 0) + done
                with open(tmp, "wb" if done == 0 else "ab") as f:
                    for chunk in r.iter_content(STREAM_CHUNK):
                        if should_stop and should_stop():
                            raise Cancelled()
                        f.write(chunk)
                        done += len(chunk)
                        if on_progress:
                            on_progress(done, total)
            os.replace(tmp, dest)
            return
        except Cancelled:
            raise
        except (requests.RequestException, OSError):
            if attempt == retries - 1:
                raise
            time.sleep(2 * (attempt + 1))


def extract(archive: str, dest: str) -> None:
    os.makedirs(dest, exist_ok=True)
    if archive.lower().endswith(".zip"):
        with zipfile.ZipFile(archive) as z:
            _check_names(z.namelist())
            z.extractall(dest)
    else:
        with tarfile.open(archive) as t:
            _check_names(t.getnames())
            t.extractall(dest)
    flatten_single_root(dest)


def _check_names(names) -> None:
    for n in names:
        # zip slip：压缩包里的 ../ 能写到模型目录外面去
        if os.path.isabs(n) or ".." in n.replace("\\", "/").split("/"):
            raise ValueError(f"unsafe path in archive: {n}")


def flatten_single_root(dest: str) -> None:
    """上游压缩包通常裹了一层同名目录，抹掉它，让布局和手机端一致。"""
    entries = [e for e in os.listdir(dest) if e != cat.OK_MARKER]
    if len(entries) != 1:
        return
    inner = os.path.join(dest, entries[0])
    if not os.path.isdir(inner):
        return
    for name in os.listdir(inner):
        shutil.move(os.path.join(inner, name), os.path.join(dest, name))
    os.rmdir(inner)


def install(cl: cat.Catalog, root: str, model_id: str, source: Source,
            on_file: Optional[Callable[[int, int, str], None]] = None,
            on_progress: Optional[ProgressFn] = None,
            should_stop: Optional[StopFn] = None) -> None:
    """装一个模型。已经校验通过的文件会跳过，所以重跑等于续传。

    出错直接抛：调用方（CLI / 网页任务）自己决定怎么报。
    """
    entry = cl.by_id(model_id)
    if entry is None:
        raise ValueError(f"unknown model: {model_id}")
    d = cat.model_dir(root, model_id)

    if entry.zip:
        archive = os.path.join(root, ".tmp", model_id + entry.archive_ext)
        if on_file:
            on_file(0, 1, os.path.basename(archive))
        if not verify(archive, entry.zip):
            download(rewrite(entry.zip.url, source), archive, on_progress, should_stop)
            if not verify(archive, entry.zip):
                raise ValueError(f"{model_id}: archive verify failed")
        extract(archive, d)
        os.remove(archive)
    else:
        for i, f in enumerate(entry.files):
            if on_file:
                on_file(i, len(entry.files), os.path.basename(f.path))
            dest = os.path.join(d, f.path)
            if verify(dest, f):
                continue
            download(rewrite(f.url, source), dest, on_progress, should_stop)
            if not verify(dest, f):
                raise ValueError(f"{model_id}: verify failed for {f.path}")

    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, cat.OK_MARKER), "w"):
        pass
