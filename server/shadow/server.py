"""跟读打分服务。默认 0.0.0.0:8766。

和 server/ai（8767）是两个独立进程：那边是翻译/识别/合成，这边是发音评测。
分开跑的代价是各自一份内存，好处是一边崩了不影响另一边——
这个进程常驻约 1.5 GB，server/ai 挂着 SeamlessM4T 时约 9 GB。

明文 HTTP，无鉴权，只在可信局域网里用。

错误契约（和 server/ai 一致，手机端的降级逻辑依赖它）：
  4xx = 业务错误，手机**不要**回退本地，把消息显示给人看
  5xx / 超时 = 服务挂了，手机可以回退
所以所有引擎错误一律转成 400 {"error": "..."}，绝不让它冒成 500。
"""

import argparse
import json
import os
import threading
import time
from typing import Any, Dict, Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse
from starlette.concurrency import run_in_threadpool

import calib
import g2p
import gop
import model as model_mod
import modelscope_dl
import wav
import web

MODEL_ROOT = os.environ.get("REPEAT_SHADOW_MODELS", "")
DEVICE = os.environ.get("REPEAT_SHADOW_DEVICE", "cpu")

app = FastAPI(title="repeat-shadow")

# torch 的 kernel 会释放 GIL，权重可以共享，所以不需要像 sherpa 那样
# 用一把全局大锁串行化。但也不能放开跑：每个请求要 1.2 GB 权重的一次
# 前向加一份 [T,V] 的 numpy 缓冲，并发太高会把内存打爆。2 个刚好。
_sem = threading.Semaphore(int(os.environ.get("REPEAT_SHADOW_WORKERS", "2")))

_stats: list = []
_stats_lock = threading.Lock()


# --------------------------------------------------------------------------
# 错误契约
# --------------------------------------------------------------------------

@app.exception_handler(gop.ShadowError)
async def _shadow_error(_req, exc: gop.ShadowError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(g2p.G2pError)
async def _g2p_error(_req, exc: g2p.G2pError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(ValueError)
async def _value_error(_req, exc: ValueError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(HTTPException)
async def _http_error(_req, exc: HTTPException):
    # detail 改名成 error，客户端只用解析一个字段。
    return JSONResponse(status_code=exc.status_code, content={"error": str(exc.detail)})


# --------------------------------------------------------------------------
# 健康检查
# --------------------------------------------------------------------------

@app.get("/v1/health")
def health() -> Dict[str, Any]:
    installed = model_mod.is_installed(MODEL_ROOT)
    g2p_ok, g2p_err, ver = True, "", ""
    try:
        ver = g2p.espeak_version()
        if not ver:
            g2p_ok, g2p_err = False, "espeak 没就绪"
    except Exception as e:
        g2p_ok, g2p_err = False, str(e)

    c = calib.load()
    return {
        "name": "repeat-shadow",
        "proto": 1,
        "model": model_mod.MODEL_ID,
        # 装好了和加载好了要分开报：模型 1.26 GB，"服务在但还在加载"
        # 是个常见状态，设置页的"测试连接"得能说清楚是哪一种。
        "modelInstalled": installed,
        "modelLoaded": gop.is_loaded(),
        "missing": model_mod.missing_files(MODEL_ROOT),
        "g2p": {"ok": g2p_ok, "espeak": ver, "lang": c["lang"], "error": g2p_err},
        "calib": c,
        **gop.info(),
    }


# --------------------------------------------------------------------------
# 打分
# --------------------------------------------------------------------------

@app.post("/v1/score")
async def score(
    audio: UploadFile = File(...),
    text: str = Form(...),
    lang: str = Form(""),
    params: str = Form(""),
) -> Dict[str, Any]:
    if not (text or "").strip():
        raise HTTPException(400, "参考文本是空的")

    raw = await audio.read()
    if not raw:
        raise HTTPException(400, "音频是空的")

    try:
        samples, rate = wav.read(raw)
    except Exception as e:
        raise HTTPException(400, f"读不了这个 wav（只收 16k 单声道 PCM16）：{e}")

    overrides: Dict[str, Any] = {}
    if params:
        try:
            overrides = json.loads(params) or {}
        except Exception as e:
            raise HTTPException(400, f"params 不是合法 json：{e}")
    if lang:
        overrides["lang"] = lang

    if not gop.is_loaded():
        # 第一次请求才加载的话会阻塞几秒。加载本身是双检锁，多个请求
        # 同时进来只会加载一次。
        await run_in_threadpool(gop.load, MODEL_ROOT, DEVICE)

    def _run():
        with _sem:
            return gop.score(samples, rate, text, overrides, MODEL_ROOT)

    t0 = time.time()
    res = await run_in_threadpool(_run)

    with _stats_lock:
        _stats.append({
            "ms": int((time.time() - t0) * 1000),
            "audioMs": res["durationMs"],
            "overall": res["overall"],
        })
        del _stats[:-50]
    return res


@app.get("/v1/stats")
def stats() -> Dict[str, Any]:
    with _stats_lock:
        rows = list(_stats)
    if not rows:
        return {"count": 0}
    n = len(rows)
    return {
        "count": n,
        "avgMs": sum(r["ms"] for r in rows) // n,
        "avgAudioMs": sum(r["audioMs"] for r in rows) // n,
        "avgOverall": sum(r["overall"] for r in rows) // n,
        "last": rows[-1],
    }


# --------------------------------------------------------------------------
# 校准参数
# --------------------------------------------------------------------------

@app.get("/v1/calib")
def get_calib() -> Dict[str, Any]:
    return calib.load()


@app.post("/v1/calib")
def set_calib(key: str = Form(...), value: str = Form(...)) -> Dict[str, Any]:
    try:
        v = calib.coerce(key, value)
    except KeyError:
        raise HTTPException(400, f"没有这个参数：{key}")
    except ValueError:
        raise HTTPException(400, f"{key} 的值不合法：{value}")
    return calib.save({key: v})


# --------------------------------------------------------------------------
# 模型管理
# --------------------------------------------------------------------------

_dl: Dict[str, Any] = {"state": "idle", "done": 0, "total": 0, "file": "", "error": ""}
_dl_lock = threading.Lock()
_dl_cancel = threading.Event()


@app.get("/v1/model")
def get_model() -> Dict[str, Any]:
    return {
        "id": model_mod.MODEL_ID,
        "dir": model_mod.model_dir(MODEL_ROOT),
        "installed": model_mod.is_installed(MODEL_ROOT),
        "missing": model_mod.missing_files(MODEL_ROOT),
        "onDisk": model_mod.disk_usage(MODEL_ROOT),
        "size": model_mod.TOTAL_SIZE,
        "loaded": gop.is_loaded(),
    }


def _download_job() -> None:
    d = model_mod.model_dir(MODEL_ROOT)
    try:
        model_mod.clear_ok(MODEL_ROOT)
        os.makedirs(d, exist_ok=True)
        files = dict(modelscope_dl.file_list(model_mod.MODEL_ID))
        want = [n for n in model_mod.REQUIRED_FILES if n in files]
        total = sum(files[n] for n in want)
        base = 0
        for name in want:
            if _dl_cancel.is_set():
                with _dl_lock:
                    _dl.update(state="idle", error="已取消")
                return
            out = os.path.join(d, name)
            if os.path.exists(out) and os.path.getsize(out) == files[name]:
                base += files[name]
                continue
            with _dl_lock:
                _dl.update(file=name)

            def prog(done, _t, _b=base):
                with _dl_lock:
                    _dl.update(done=_b + done, total=total)

            modelscope_dl.download(model_mod.MODEL_ID, name, out, on_progress=prog)
            base += files[name]
        miss = model_mod.missing_files(MODEL_ROOT)
        if miss:
            with _dl_lock:
                _dl.update(state="failed", error=f"还缺：{', '.join(miss)}")
            return
        model_mod.mark_ok(MODEL_ROOT)
        with _dl_lock:
            _dl.update(state="done", done=total, total=total, file="", error="")
    except Exception as e:
        with _dl_lock:
            _dl.update(state="failed", error=str(e))


@app.post("/v1/model/download")
def start_download() -> Dict[str, Any]:
    with _dl_lock:
        if _dl["state"] == "running":
            raise HTTPException(409, "已经在下了")
        _dl.update(state="running", done=0, total=model_mod.TOTAL_SIZE, file="", error="")
    _dl_cancel.clear()
    threading.Thread(target=_download_job, daemon=True).start()
    return dict(_dl)


@app.get("/v1/model/download")
def download_status() -> Dict[str, Any]:
    with _dl_lock:
        return dict(_dl)


@app.post("/v1/model/cancel")
def cancel_download() -> Dict[str, Any]:
    _dl_cancel.set()
    with _dl_lock:
        return dict(_dl)


@app.delete("/v1/model")
def delete_model() -> Dict[str, Any]:
    import shutil
    gop.drop()
    d = model_mod.model_dir(MODEL_ROOT)
    if os.path.exists(d):
        shutil.rmtree(d)
    return {"ok": True}


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return web.INDEX


# --------------------------------------------------------------------------

def main() -> None:
    global MODEL_ROOT, DEVICE
    ap = argparse.ArgumentParser(description="跟读打分服务")
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=8766)
    ap.add_argument("--models", default=MODEL_ROOT)
    ap.add_argument("--device", default=DEVICE, choices=["cpu", "mps"],
                    help="mps 会先跑一次数值自检，不过就退回 cpu")
    ap.add_argument("--preload", action="store_true", help="启动时就把模型加载好")
    args = ap.parse_args()

    MODEL_ROOT = args.models
    DEVICE = args.device

    print(f"[shadow] 模型目录 {model_mod.model_dir(MODEL_ROOT)}")
    print(f"[shadow] 校准文件 {calib.path()}")
    if not model_mod.is_installed(MODEL_ROOT):
        print("[shadow] 模型没装。跑：python install.py")
    elif args.preload:
        try:
            gop.load(MODEL_ROOT, DEVICE)
        except Exception as e:
            print(f"[shadow] 预加载失败：{e}")

    print(f"[shadow] http://127.0.0.1:{args.port}/")
    import uvicorn
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()
