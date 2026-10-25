"""repeat-flutter 的局域网推理服务。

手机把录下来的一段音频丢过来，这边跑 ASR / 翻译 / TTS，把文本和合成音频送回去。
用的是和手机端同一份 assets/ai/catalog.json，同一批 sherpa-onnx 模型，
所以结果一致——只是 Mac 比手机快 5~10 倍。

协议见同目录 PROTOCOL.md。明文 HTTP、无鉴权，只面向可信局域网。
"""

import argparse
import base64
import json
import os
import shutil
import socket
import tempfile
import threading
import time
from typing import Any, Dict, List, Optional

import numpy as np
import uvicorn
from fastapi import FastAPI, Form, HTTPException, Request, UploadFile, File
from fastapi.responses import HTMLResponse, JSONResponse, Response

import catalog as cat
import downloader as dl
import engine
import hf_tts
import llm_mt
import mlx_asr
import mlx_audio_asr
import selection as sel
import text_mt
import wav
import web

PROTO = 1

app = FastAPI(title="repeat-ai")

# 模块级就初始化好，这样 `uvicorn server:app` 直接起也能用（main() 里再按命令行覆盖）
_catalog = cat.Catalog(os.environ.get("REPEAT_AI_CATALOG") or cat.DEFAULT_CATALOG)
_model_root = os.environ.get("REPEAT_AI_MODELS") or cat.DEFAULT_MODEL_ROOT


@app.exception_handler(engine.EngineError)
async def _engine_error(_request, exc: engine.EngineError):
    # 模型没装、类型不认识这类是"业务错误"：手机端看到 4xx 不会回退本地，
    # 而是把这一段标成 failed，让用户去复核页重跑。别用 5xx。
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(mlx_asr.MlxAsrError)
async def _mlx_asr_error(_request, exc: mlx_asr.MlxAsrError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(mlx_audio_asr.MlxAudioAsrError)
async def _mlx_audio_asr_error(_request, exc: mlx_audio_asr.MlxAudioAsrError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(llm_mt.LlmMtError)
async def _llm_mt_error(_request, exc: llm_mt.LlmMtError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(hf_tts.HfTtsError)
async def _hf_tts_error(_request, exc: hf_tts.HfTtsError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(text_mt.TextMtError)
async def _text_mt_error(_request, exc: text_mt.TextMtError):
    return JSONResponse(status_code=400, content={"error": str(exc)})


@app.exception_handler(HTTPException)
async def _http_error(_request, exc: HTTPException):
    # FastAPI 默认把消息塞在 detail 里。统一成 error，跟 PROTOCOL.md 和
    # EngineError 那条保持一致，客户端只用认一个字段。
    return JSONResponse(status_code=exc.status_code, content={"error": str(exc.detail)})


@app.get("/v1/health")
def health() -> Dict[str, Any]:
    installed = {"vad": [], "asr": [], "mt": [], "tts": []}
    for m in _catalog.models:
        if not cat.is_installed(_model_root, m.id):
            continue
        for role in m.roles:
            installed.setdefault(role, []).append(m.id)
    return {
        "name": "repeat-ai",
        "proto": PROTO,
        "catalogVersion": _catalog.version,
        "threads": engine.num_threads(),
        "models": installed,
        # 手机要显示"服务器在用什么"，一次调用就拿全，不用再多打一趟
        "selection": _selection.resolved(_catalog, _model_root),
    }


# 下载任务。同一时刻只跑一个：并发下载会互相抢带宽，进度也更难看懂。
_jobs: Dict[str, Dict[str, Any]] = {}
_job_lock = threading.Lock()
_source = dl.Source.load(_model_root)
_selection = sel.Selection.load(_model_root)

# 最近 N 次推理的分阶段耗时。概览页显示它——"到底哪一步慢"是这条链路上
# 最常问的问题，实测 kokoro 占 64% 就是这么发现的。只在内存里，重启清零。
_port = 8767
_STATS_KEEP = 50
_stats: List[Dict[str, int]] = []
_stats_lock = threading.Lock()


def _job(model_id: str) -> Dict[str, Any]:
    return _jobs.setdefault(model_id, {"state": "idle"})


def _busy_id() -> Optional[str]:
    for mid, j in _jobs.items():
        if j.get("state") == "running":
            return mid
    return None


def _run_download(model_id: str) -> None:
    j = _job(model_id)
    try:
        dl.install(
            _catalog, _model_root, model_id, _source,
            on_file=lambda i, n, name: j.update(fileIndex=i, fileTotal=n, file=name, done=0, total=0),
            on_progress=lambda d, t: j.update(done=d, total=t),
            should_stop=lambda: j.get("cancel", False),
        )
        j.update(state="done", error="")
        engine.drop_cache(model_id)
    except dl.Cancelled:
        j.update(state="idle", error="")
    except Exception as e:
        j.update(state="failed", error=f"{type(e).__name__}: {e}")
    finally:
        j.pop("cancel", None)


def _lan_ip() -> str:
    """本机在局域网里的地址，概览页直接告诉用户手机该填什么。

    connect 一个 UDP 地址不会真发包，只是让内核挑一条出口路由，
    比遍历网卡靠谱（Mac 上 en0/en1/utun 一堆）。
    """
    s_ = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s_.connect(("8.8.8.8", 80))
        return s_.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s_.close()


@app.get("/v1/selection")
def get_selection() -> Dict[str, Any]:
    return {**_selection.to_json(), "resolved": _selection.resolved(_catalog, _model_root)}


@app.post("/v1/selection")
def set_selection(role: Optional[str] = Form(None), model: Optional[str] = Form(None),
                  ttsSid: Optional[int] = Form(None),
                  ttsSpeed: Optional[float] = Form(None)) -> Dict[str, Any]:
    if role is not None:
        if role not in sel.ROLES:
            raise HTTPException(status_code=400, detail=f"unknown role: {role}")
        mid = model or ""
        if mid:
            e = _catalog.by_id(mid)
            if e is None:
                raise HTTPException(status_code=404, detail=f"unknown model: {mid}")
            if role not in e.roles:
                raise HTTPException(status_code=400, detail=f"{mid} 担不了 {role}")
            if not cat.is_installed(_model_root, mid):
                raise HTTPException(status_code=400, detail=f"{mid} 还没装好")
        _selection.set(role, mid)
    if ttsSid is not None:
        _selection.tts_sid = max(0, ttsSid)
    if ttsSpeed is not None:
        _selection.tts_speed = ttsSpeed
    _selection.save(_model_root)
    # 换了模型还留着旧实例就白换了
    engine.drop_cache()
    text_mt.drop_cache()
    hf_tts.drop_cache()
    llm_mt.drop_cache()
    mlx_asr.drop_cache()
    mlx_audio_asr.drop_cache()
    return {**_selection.to_json(), "resolved": _selection.resolved(_catalog, _model_root)}


@app.get("/v1/stats")
def stats() -> Dict[str, Any]:
    with _stats_lock:
        rows = list(_stats)
    if not rows:
        return {"count": 0}
    def avg(k: str) -> int:
        vals = [r[k] for r in rows if r.get(k)]
        return round(sum(vals) / len(vals)) if vals else 0
    return {
        "count": len(rows),
        "totalMs": avg("totalMs"), "asrMs": avg("asrMs"),
        "mtMs": avg("mtMs"), "ttsMs": avg("ttsMs"),
        "audioMs": avg("audioMs"), "last": rows[-1],
    }


@app.get("/v1/source")
def get_source() -> Dict[str, Any]:
    return _source.to_json()


@app.post("/v1/source")
def set_source(kind: str = Form(...), hfHost: str = Form(""), ghPrefix: str = Form("")) -> Dict[str, Any]:
    global _source
    _source = dl.Source(kind, hfHost.strip(), ghPrefix.strip())
    _source.save(_model_root)
    return _source.to_json()


@app.get("/v1/downloads")
def downloads() -> Dict[str, Any]:
    return {k: v for k, v in _jobs.items() if v.get("state") != "idle"}


@app.post("/v1/models/{model_id}/download")
def start_download(model_id: str) -> Dict[str, Any]:
    entry = _catalog.by_id(model_id)
    if entry is None:
        raise HTTPException(status_code=404, detail=f"unknown model: {model_id}")
    if not entry.files and not entry.zip:
        # 文本翻译模型要先下 HF 权重再转 CT2，这套下载器干不了
        raise HTTPException(
            status_code=400,
            detail=f"{entry.name} 不能这样下。在 server/ai 下跑：python setup_mt.py")
    with _job_lock:
        busy = _busy_id()
        if busy:
            raise HTTPException(status_code=409, detail=f"正在下载 {busy}，一次只跑一个")
        _jobs[model_id] = {"state": "running", "fileIndex": 0, "fileTotal": 0,
                           "file": "", "done": 0, "total": 0, "error": ""}
    threading.Thread(target=_run_download, args=(model_id,), daemon=True).start()
    return {"ok": True}


@app.post("/v1/models/{model_id}/cancel")
def cancel_download(model_id: str) -> Dict[str, Any]:
    j = _jobs.get(model_id)
    if not j or j.get("state") != "running":
        return {"ok": False}
    # 已下的 .part 故意留着，下次点下载会从断点接着要
    j["cancel"] = True
    return {"ok": True}


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return web.INDEX


def _dir_size(path: str) -> int:
    total = 0
    for root, _, names in os.walk(path):
        for n in names:
            try:
                total += os.path.getsize(os.path.join(root, n))
            except OSError:
                pass
    return total


@app.get("/v1/catalog")
def full_catalog() -> Dict[str, Any]:
    """网页要的一切，一次给全：状态 + 下载地址 + 缺哪些文件。

    比 /v1/models 多出 name/size/note/urls，是给人看的；/v1/models 保持精简，
    手机端对账只需要那几个字段。
    """
    out: List[Dict[str, Any]] = []
    for m in _catalog.models:
        d = cat.model_dir(_model_root, m.id)
        missing = cat.missing_files(_model_root, m)
        units = [m.zip] if m.zip else m.files
        urls = [{
            # 展示的和服务端真会去下的是同一个地址，免得用户照着官方地址下完
            # 才发现跟这边期望的对不上
            "url": dl.rewrite(u.url, _source),
            "size": u.size,
            # "缺"标记让用户一眼看出这次只需要下哪几个，不用整包重下
            "have": m.zip is None and u.path not in missing,
        } for u in units]
        out.append({
            "id": m.id, "name": m.name, "roles": m.roles, "size": m.size,
            "note": m.note, "langs": m.langs, "archive": m.zip is not None,
            "kind": m.kind, "downloadable": bool(m.files or m.zip),
            "localOnly": _catalog.is_local_only(m.id),
            "ok": cat.is_installed(_model_root, m.id),
            "missing": missing, "urls": urls,
            "onDisk": _dir_size(d) if os.path.isdir(d) else 0,
        })
    return {
        "root": _model_root,
        "threads": engine.num_threads(),
        "catalogVersion": _catalog.version,
        "diskUsage": _dir_size(_model_root),
        # 概览页直接告诉用户手机该填什么，省得他去 ifconfig
        "lan": _lan_ip(),
        "port": _port,
        "source": _source.to_json(),
        "cnHfHost": dl.CN_HF_HOST,
        "cnGhPrefix": dl.CN_GH_PREFIX,
        "models": out,
    }


@app.get("/v1/models")
def models() -> Dict[str, Any]:
    out = {}
    for m in _catalog.models:
        missing = cat.missing_files(_model_root, m)
        out[m.id] = {
            "ok": cat.is_installed(_model_root, m.id),
            "archive": m.zip is not None,
            "missing": missing,
        }
    return out


def _params(raw: Optional[str]) -> Dict[str, Any]:
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"bad params json: {e}")


def _selected(role: str) -> cat.ModelEntry:
    """这个角色该用哪个模型。**由服务端决定**，请求里带的 model id 一律忽略。

    手机的清单里没有服务端专属大模型，让它指定的话那些模型永远用不上。
    没有可用模型时报 400 而不是 5xx：这是业务错误，手机看到 4xx 不会回退本地
    （回退了也是一样的结果），而是把这一段标 failed 让用户去复核页重跑。
    """
    e = _selection.resolve(role, _catalog, _model_root)
    if e is None:
        raise HTTPException(status_code=400, detail=f"服务端没有可用的 {role} 模型，请先在网页上装一个")
    return e


def _run_asr(samples, lang: str) -> str:
    """识别。按选中模型的 kind 分派：sherpa（CPU int8）、mlx-whisper 还是 mlx-audio（都是 Apple GPU）。"""
    e = _selected("asr")
    if e.kind == "mlx-asr":
        return mlx_asr.get(e.id, cat.model_dir(_model_root, e.id), e.cfg).recognize(samples, lang)
    if e.kind == "mlx-audio-stt":
        return mlx_audio_asr.get(e.id, cat.model_dir(_model_root, e.id), e.cfg).recognize(samples, lang)
    r = engine.get_recognizer(_catalog, _model_root, e.id, lang, "transcribe")
    return engine.recognize(r, samples)


def _synthesize(say: str, sid: int, speed: float):
    """合成一段话，返回 (wav 文件字节 | None, 音频时长 ms)。/v1/infer 和 /v1/tts 共用。"""
    tts_entry = _selected("tts")
    if tts_entry.kind == "hf-tts":
        # transformers 那条路：权重共享，靠内部信号量限流，
        # 不像 sherpa 那样每个并发都要一份实例
        inst = hf_tts.get(tts_entry.id, cat.model_dir(_model_root, tts_entry.id),
                          tts_entry.cfg, engine.num_threads(), engine.tts_workers())
        out, rate = inst.synthesize(say)
    else:
        # **必须走池子**：sherpa 的 OfflineTts 实例不是线程安全的，
        # 而 TTS 不在全局锁里，多个请求会同时进到这儿。
        pool = engine.tts_pool(_catalog, _model_root, tts_entry.id)
        with pool.acquire() as inst:
            out, rate = engine.synthesize(inst, say, sid, speed)
    if out is None:
        return None, 0
    return wav.write(out, rate), wav.duration_ms(out.size, rate)


def _tts_response(text: Optional[str], sid: Optional[int], speed: Optional[float]) -> Response:
    say = (text or "").strip()
    if not say:
        raise HTTPException(status_code=400, detail="text is required")
    t0 = time.time()
    data, _ = _synthesize(say,
                          _selection.tts_sid if sid is None else max(0, sid),
                          _selection.tts_speed if speed is None else speed)
    if data is None:
        raise HTTPException(status_code=400, detail="tts produced no audio")
    ms = int((time.time() - t0) * 1000)
    with _stats_lock:
        _stats.append({"asrMs": 0, "mtMs": 0, "ttsMs": ms, "totalMs": ms,
                       "audioMs": 0, "kind": "tts-api"})
        del _stats[:-_STATS_KEEP]
    # 每次现合成、只在内存里，不落盘：朗读文本千变万化，缓存命中率低，还得管清理
    return Response(content=data, media_type="audio/wav")


@app.get("/v1/tts")
def tts_get(text: str = "", sid: Optional[int] = None, speed: Optional[float] = None) -> Response:
    """对外的朗读接口：直接回 audio/wav，手机悬浮球的朗读动作、浏览器、curl 都能直接用。"""
    return _tts_response(text, sid, speed)


@app.post("/v1/tts")
def tts_post(text: str = Form(""), sid: Optional[int] = Form(None),
             speed: Optional[float] = Form(None)) -> Response:
    # 长文本走 POST，不受 URL 长度限制
    return _tts_response(text, sid, speed)


# ---- /v1/chat：给悬浮球「自定义动作 → 联网」用的自由问答 ----
#
# 协议照搬手机端联网动作原来对接的助手服务：POST <服务地址>/start 发任务，
# 每秒 GET <服务地址>/status 轮询到 running=false 再取 result.text。
# 所以手机那边服务地址填 http://<IP>:8767/v1/chat 就能用，App 不用改。
#
# 跟助手服务一样同一时刻只跑一个任务：状态是全局的一份，谁来轮询看到的都是它。
# 问答一句要好几秒，排队意义不大，忙的时候直接回 409。
_chat_lock = threading.Lock()
_chat: Dict[str, Any] = {"running": False, "log": [], "result": {}}


def _chat_model() -> cat.ModelEntry:
    """问答用哪个模型：选中的翻译模型是通用 LLM 就用它（已经加载好了，省一份显存），
    否则找任意一个装好的通用 LLM。翻译专用的混元、NMT、whisper 都不行。"""
    mt = _selection.resolve("mt", _catalog, _model_root)
    if mt is not None and mt.kind == "llm-mt" and llm_mt.is_chat_model(mt.cfg):
        return mt
    for e in _catalog.by_role("mt"):
        if e.kind == "llm-mt" and llm_mt.is_chat_model(e.cfg) and cat.is_installed(_model_root, e.id):
            return e
    raise HTTPException(status_code=400,
                        detail="问答要一个通用 LLM（如 Qwen2.5 Instruct），请先在网页上装一个；"
                               "混元 Hy-MT2 是翻译专用模型，答不了问题")


def _chat_log(line: str) -> None:
    with _chat_lock:
        _chat["log"].append(line)


def _run_chat(entry: cat.ModelEntry, text: str) -> None:
    t0 = time.time()
    result: Dict[str, Any] = {}
    try:
        _chat_log(f"model: {entry.id}")
        # 第一次用会加载模型（几秒到十几秒），放在线程里，/start 不用等
        inst = llm_mt.get(entry.id, cat.model_dir(_model_root, entry.id), entry.cfg)
        result = {"text": inst.chat(text)}
        _chat_log("done")
    except Exception as e:
        _chat_log(f"error: {e}")
    ms = int((time.time() - t0) * 1000)
    with _stats_lock:
        _stats.append({"asrMs": 0, "mtMs": ms, "ttsMs": 0, "totalMs": ms,
                       "audioMs": 0, "kind": "chat"})
        del _stats[:-_STATS_KEEP]
    with _chat_lock:
        _chat["result"] = result
        _chat["running"] = False


@app.post("/v1/chat/start")
async def chat_start(request: Request) -> Dict[str, Any]:
    """body: {"params": {"input": "..."}}（手机联网动作发的形状），也接受 {"input": "..."}。
    params 里的其它字段（withSpeak 等）忽略。"""
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="body must be json")
    params = body.get("params") if isinstance(body, dict) and isinstance(body.get("params"), dict) else body
    text = str((params or {}).get("input") or "").strip() if isinstance(params, dict) else ""
    if not text:
        raise HTTPException(status_code=400, detail="input is required")
    entry = _chat_model()
    with _chat_lock:
        if _chat["running"]:
            raise HTTPException(status_code=409, detail="上一个问答还没跑完")
        _chat.update({"running": True, "log": ["started"], "result": {}})
    threading.Thread(target=_run_chat, args=(entry, text), daemon=True).start()
    return {"ok": True}


@app.get("/v1/chat/status")
def chat_status() -> Dict[str, Any]:
    with _chat_lock:
        return {"running": _chat["running"], "log": list(_chat["log"]), "result": dict(_chat["result"])}


@app.post("/v1/infer")
async def infer(
    kind: str = Form(...),
    params: Optional[str] = Form(None),
    text: Optional[str] = Form(None),
    audio: Optional[UploadFile] = File(None),
) -> Dict[str, Any]:
    if kind not in ("full", "asr", "mt", "tts"):
        raise HTTPException(status_code=400, detail=f"unknown kind: {kind}")
    p = _params(params)

    samples: Optional[np.ndarray] = None
    # kind=mt 时音频是可选的：文本翻译只要文字。whisper 那条路缺音频会在下面报错。
    need_audio = kind in ("full", "asr")
    if need_audio or (kind == "mt" and audio is not None):
        if audio is None:
            raise HTTPException(status_code=400, detail=f"audio is required for kind={kind}")
        try:
            samples, rate = wav.read(await audio.read())
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"bad wav: {e}")
        if rate != 16000:
            raise HTTPException(status_code=400, detail=f"expect 16kHz wav, got {rate}")

    src: Optional[str] = None
    dst: Optional[str] = None
    tts_wav: Optional[bytes] = None
    tts_ms = 0
    # 源语言仍由手机给：它说的是"我在说什么话"，跟算力无关
    lang = str((p.get("language") if isinstance(p.get("language"), str) else "") or "")
    timing: Dict[str, int] = {"asrMs": 0, "mtMs": 0, "ttsMs": 0}
    t0 = time.time()

    # 识别和翻译持全局锁：sherpa 的 recognizer 实例不是线程安全的，
    # 而且这两步加起来才一百多毫秒，并行不划算。
    # **合成不在这把锁里**——它占整段的 94%，锁住它等于整个服务串行，
    # 手机那边的队列就永远排不空。合成走自己的实例池。
    with engine.lock():
        if kind in ("full", "asr"):
            t = time.time()
            src = _run_asr(samples, lang)
            timing["asrMs"] = int((time.time() - t) * 1000)

        if kind in ("full", "mt"):
            t = time.time()
            mt = _selected("mt")
            if mt.kind == "text":
                # 文本翻译：拿**文字**去翻。kind=full 时用刚识别出来的 src；
                # kind=mt 时用手机传上来的 text（复核页里用户可能改过原文）。
                # 都没有就先识别一遍——总比报错强。
                say = src if kind == "full" else (text or "")
                if not say and samples is not None:
                    say = _run_asr(samples, lang)
                    src = say
                tr = text_mt.get(mt.id, cat.model_dir(_model_root, mt.id), mt.cfg,
                                 engine.num_threads())
                dst = tr.translate(say)
            elif mt.kind == "llm-mt":
                say = src if kind == "full" else (text or "")
                if not say and samples is not None:
                    say = _run_asr(samples, lang)
                    src = say
                dst = llm_mt.get(mt.id, cat.model_dir(_model_root, mt.id),
                                 mt.cfg).translate(say)
            else:
                if samples is None:
                    # whisper 的 translate 是拿音频重跑一遍，没音频做不了
                    raise HTTPException(status_code=400, detail="whisper translate needs audio")
                # whisper 的 translate 任务里 language 指的是**源语言**，不给它照样要猜一遍，
                # 猜错译文就跟着错。所以这里必须把手机钉的识别语言也传下去。
                r = engine.get_recognizer(_catalog, _model_root, mt.id, lang, "translate")
                dst = engine.recognize(r, samples)
            timing["mtMs"] = int((time.time() - t) * 1000)

    # 合成在锁外，用实例池并行。多个请求同时进来时它们各拿一个实例，
    # 互不阻塞——这正是把吞吐做上去的地方。
    if kind in ("full", "tts"):
        say = text if kind == "tts" else (dst or "")
        # 译文长度和音频时长严重不成比例时，多半是翻译模型退化打转了。
        # 不设这道闸的话：1.9 秒的话译出几百个词，kokoro 花 27.7 秒念完，
        # 整段 31.7 秒——用户在录音页就是干等。宁可截断也不能让它跑满。
        if kind == "full" and samples is not None and say:
            # 每秒语音最多允许 40 个字符的译文，再给 80 字符的底
            limit = 80 + int(wav.duration_ms(samples.size, 16000) / 1000 * 40)
            if len(say) > limit:
                print(f"[warn] 译文异常长（{len(say)} 字符 / 音频 "
                      f"{wav.duration_ms(samples.size, 16000)} ms），截到 {limit}；"
                      f"多半是翻译模型退化打转")
                say = say[:limit].rstrip()
                dst = say
        if say:
            t = time.time()
            tts_wav, tts_ms = _synthesize(say, _selection.tts_sid, _selection.tts_speed)
            timing["ttsMs"] = int((time.time() - t) * 1000)

    timing["totalMs"] = int((time.time() - t0) * 1000)
    timing["audioMs"] = 0 if samples is None else wav.duration_ms(samples.size, 16000)
    timing["kind"] = kind
    with _stats_lock:
        _stats.append(timing)
        del _stats[:-_STATS_KEEP]

    return {
        "src": src,
        "dst": dst,
        "ttsMs": tts_ms,
        "ttsWav": base64.b64encode(tts_wav).decode("ascii") if tts_wav else None,
    }


@app.post("/v1/models/{model_id}/file")
async def upload_file(model_id: str, path: str = Form(...), data: UploadFile = File(...)) -> Dict[str, Any]:
    entry = _catalog.by_id(model_id)
    if entry is None:
        raise HTTPException(status_code=404, detail=f"unknown model: {model_id}")
    d = cat.model_dir(_model_root, model_id)
    dest = os.path.normpath(os.path.join(d, path))
    # 手机传上来的相对路径不可信，越出模型目录一律拒绝
    if not dest.startswith(os.path.join(d, "")) and dest != d:
        raise HTTPException(status_code=400, detail=f"path escapes model dir: {path}")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    # 先写临时文件再改名：传一半断了不会留下一个看着完整的坏文件
    tmp = dest + ".part"
    with open(tmp, "wb") as f:
        shutil.copyfileobj(data.file, f, 1024 * 1024)
    os.replace(tmp, dest)
    return {"ok": True, "size": os.path.getsize(dest)}


ARCHIVE_EXTS = (".zip", ".tar.bz2", ".tar.gz", ".tar.xz", ".tgz")


def _is_archive(name: str) -> bool:
    return name.lower().endswith(ARCHIVE_EXTS)


@app.post("/v1/models/{model_id}/import")
async def import_file(model_id: str, data: UploadFile = File(...)) -> Dict[str, Any]:
    """网页上传用：**按文件名**归位，不需要用户还原目录结构。

    和 /file 的区别是那边要显式给相对路径（手机知道自己的目录结构），
    而浏览器的文件选择器根本不给路径，只有一个文件名。清单里每个模型的
    文件名都是唯一的（melo-tts 那 16 个带子目录的也是），所以文件名足够定位。

    认不出来的文件名一律拒绝，而不是随便丢进模型目录——那样只会让 complete
    校验时莫名其妙地过不了。
    """
    entry = _catalog.by_id(model_id)
    if entry is None:
        raise HTTPException(status_code=404, detail=f"unknown model: {model_id}")
    d = cat.model_dir(_model_root, model_id)
    name = os.path.basename(data.filename or "")
    if not name:
        raise HTTPException(status_code=400, detail="no filename")

    if _is_archive(name):
        os.makedirs(os.path.join(_model_root, ".tmp"), exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=os.path.join(_model_root, ".tmp"), suffix=name)
        os.close(fd)
        try:
            with open(tmp, "wb") as f:
                shutil.copyfileobj(data.file, f, 1024 * 1024)
            try:
                dl.extract(tmp, d)
            except ValueError as e:
                # zip slip 之类：是用户给的包有问题，属于 4xx
                raise HTTPException(status_code=400, detail=str(e))
        finally:
            os.remove(tmp)
        engine.drop_cache(model_id)
        return {"ok": True, "extracted": True}

    wanted = {os.path.basename(f.path).lower(): f.path for f in entry.files}
    rel = wanted.get(name.lower())
    if rel is None:
        raise HTTPException(
            status_code=400,
            detail=f"{name} 不属于 {entry.name}；这个模型要的是: " + ", ".join(sorted(wanted)),
        )
    dest = os.path.join(d, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".part"
    with open(tmp, "wb") as f:
        shutil.copyfileobj(data.file, f, 1024 * 1024)
    os.replace(tmp, dest)
    engine.drop_cache(model_id)
    return {"ok": True, "path": rel, "size": os.path.getsize(dest)}


@app.delete("/v1/models/{model_id}")
def delete_model(model_id: str) -> Dict[str, Any]:
    if _catalog.by_id(model_id) is None:
        raise HTTPException(status_code=404, detail=f"unknown model: {model_id}")
    shutil.rmtree(cat.model_dir(_model_root, model_id), ignore_errors=True)
    engine.drop_cache(model_id)
    text_mt.drop_cache(model_id)
    hf_tts.drop_cache(model_id)
    llm_mt.drop_cache(model_id)
    mlx_asr.drop_cache(model_id)
    mlx_audio_asr.drop_cache(model_id)
    return {"ok": True}


@app.post("/v1/models/{model_id}/complete")
def complete(model_id: str) -> Dict[str, Any]:
    entry = _catalog.by_id(model_id)
    if entry is None:
        raise HTTPException(status_code=404, detail=f"unknown model: {model_id}")
    missing = cat.missing_files(_model_root, entry)
    if entry.zip:
        # zip 类模型没有逐文件清单可校验，只要目录里有东西就认。
        d = cat.model_dir(_model_root, model_id)
        missing = [] if os.path.isdir(d) and os.listdir(d) else ["<empty>"]
    if missing:
        return {"ok": False, "missing": missing}
    with open(os.path.join(cat.model_dir(_model_root, model_id), cat.OK_MARKER), "w") as f:
        f.write("")
    engine.drop_cache(model_id)
    return {"ok": True, "missing": []}


def main() -> None:
    global _catalog, _model_root
    ap = argparse.ArgumentParser(description="repeat-flutter LAN inference server")
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=8767)
    ap.add_argument("--catalog", default=cat.DEFAULT_CATALOG, help="assets/ai/catalog.json 的路径")
    ap.add_argument("--models", default=cat.DEFAULT_MODEL_ROOT, help="模型目录，布局和手机端 m/ 一致")
    args = ap.parse_args()

    _catalog = cat.Catalog(args.catalog)
    _model_root = args.models
    globals()["_port"] = args.port
    os.makedirs(_model_root, exist_ok=True)
    globals()["_source"] = dl.Source.load(_model_root)
    globals()["_selection"] = sel.Selection.load(_model_root)

    ready = [m.id for m in _catalog.models if cat.is_installed(_model_root, m.id)]
    print(f"catalog v{_catalog.version} from {args.catalog}")
    print(f"models  {_model_root}  installed: {', '.join(ready) if ready else '(none)'}")
    shown = "127.0.0.1" if args.host in ("0.0.0.0", "::") else args.host
    res = _selection.resolved(_catalog, _model_root)
    print("当前生效  " + "  ".join(
        f"{r}={res[r]['id'] if res[r] else '(无)'}" for r in sel.ROLES))
    print(f"threads {engine.num_threads()}")
    print(f"网页管理  http://{shown}:{args.port}/    （手机填局域网 IP，同端口）")
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()
