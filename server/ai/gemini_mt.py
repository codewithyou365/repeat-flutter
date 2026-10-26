"""用 Google Gemini API 做翻译（在线，免费档）。

为什么要它：本地 7B 级的混元 / Qwen 碰到口语、俗语还是会翻傻，大模型又装不下。
默认用 Gemma 4 26B（也走 Gemini API 免费档），10 秒上下一句。gemini-3.5-flash-lite
快（2~4 秒）但实际用下来翻得不行，没进默认列表。

免费档的坑（2026-10 实测，额度在 https://aistudio.google.com/rate-limit 看）：

    gemma-4-26b-a4b-it      30 次/分  1.44 万次/天  默认，10~16 秒，会先吐 thought
    gemma-4-31b-it          30 次/分  1.44 万次/天  兜底
    gemini-3.5-flash-lite   15 次/分  500 次/天    快，但翻得不行
    gemini-3.8-flash         5 次/分   20 次/天    太少，别用

    - 高峰期会回 503 "high demand"，偶尔还会回**空 body 的 404** 或干脆不回包——
      这些都是暂时的，换下一个模型或者重试一次就好。所以 cfg.models 是一串，按顺序试。
    - 429 是额度用完了，当天别再打它，直接跳下一个。
    - 中国大陆 / 香港不在服务区：必须走代理。用环境变量（setproxy 后再 ./run.sh），
      或 cfg.proxy 写死。
    - 免费档的输入输出会被 Google 拿去训练，别送隐私内容。

key 放在 cfg.keyFile（默认 ~/.repeat-ai/gemini.key），或环境变量 GEMINI_API_KEY。
**别把 key 写进 catalog**——那个文件是进 git 的。
"""

import json
import os
import threading
import time
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional, Tuple

from llm_mt import FEWSHOT_EN, LANG_NAMES, REPAIR, SYSTEM, LlmMtError, _clean, _leftover

API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


class _Skip(Exception):
    """这个模型这次不行（限流 / 过载 / 超时），换下一个。"""


class GeminiTranslator:
    def __init__(self, cfg: Dict[str, Any]):
        self._key = _load_key(cfg)
        self._models: List[str] = list(cfg.get("models") or ["gemma-4-26b-a4b-it"])
        self._target = cfg.get("tgtLang", "en")
        self._timeout = float(cfg.get("timeoutSec", 45))
        proxy = cfg.get("proxy") or ""
        handlers = [urllib.request.ProxyHandler({"http": proxy, "https": proxy})] if proxy else []
        # 不传 ProxyHandler 时 urllib 自己读 https_proxy 环境变量
        self._opener = urllib.request.build_opener(*handlers)
        # 429 的模型记一下什么时候能再用，免得每句都先撞一次墙
        self._cooldown: Dict[str, float] = {}
        self._lock = threading.Lock()

    def translate(self, text: str) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        out = self._ask(self._contents(text), SYSTEM.format(lang=self._lang()))
        # 出口校验和 MlxTranslator 一样：夹了源语言字符就让它整句重来一次
        if _leftover(out, self._target):
            out = self._ask(self._contents(text, repair=out), SYSTEM.format(lang=self._lang())) or out
        return out

    def chat(self, text: str) -> str:
        text = (text or "").strip()
        if not text:
            return ""
        return self._ask([_turn("user", text)], None, clean=False)

    def _lang(self) -> str:
        return LANG_NAMES.get(self._target, self._target)

    def _contents(self, text: str, repair: Optional[str] = None) -> List[Dict[str, Any]]:
        msgs: List[Dict[str, Any]] = []
        if self._target == "en":
            for src, dst in FEWSHOT_EN:
                msgs += [_turn("user", src), _turn("model", dst)]
        msgs.append(_turn("user", text))
        if repair is not None:
            msgs += [_turn("model", repair),
                     _turn("user", REPAIR.format(bad=_leftover(repair, self._target), lang=self._lang()))]
        return msgs

    def _ask(self, contents: List[Dict[str, Any]], system: Optional[str], clean: bool = True) -> str:
        body: Dict[str, Any] = {"contents": contents}
        if system:
            body["systemInstruction"] = {"parts": [{"text": system}]}
        errs: List[str] = []
        now = time.time()
        for model in self._models:
            if self._cooldown.get(model, 0) > now:
                errs.append(f"{model}: 今日额度已用完")
                continue
            # 空 404 / 503 这类抖动重试一次常常就好了；再不行才换下一个
            for _ in range(2):
                try:
                    out = self._post(model, body)
                    return _clean(out) if clean else out
                except _Skip as e:
                    msg = str(e)
                    if msg.startswith("429"):
                        with self._lock:
                            self._cooldown[model] = time.time() + 3600
                        errs.append(f"{model}: {msg}")
                        break
                    errs.append(f"{model}: {msg}")
        raise LlmMtError("Gemini 全部失败：\n  " + "\n  ".join(errs))

    def _post(self, model: str, body: Dict[str, Any]) -> str:
        req = urllib.request.Request(
            API.format(model=model), data=json.dumps(body).encode(),
            headers={"Content-Type": "application/json", "x-goog-api-key": self._key})
        try:
            with self._opener.open(req, timeout=self._timeout) as r:
                d = json.load(r)
        except urllib.error.HTTPError as e:
            msg = _error_message(e)
            if e.code in (404, 429, 500, 502, 503, 504):
                raise _Skip(f"{e.code} {msg}") from e
            # 400 / 403：key 错了、参数错了，换模型也没用
            raise LlmMtError(f"Gemini {model} 返回 {e.code}: {msg}") from e
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            raise _Skip(f"网络 {type(e).__name__}: {e}（没开代理？）") from e
        try:
            parts = d["candidates"][0]["content"]["parts"]
        except (KeyError, IndexError) as e:
            raise _Skip(f"空回复 {str(d)[:120]}") from e
        # gemma 会先吐一段 thought: true 的思考过程，只要正文
        return "".join(p.get("text", "") for p in parts if not p.get("thought")).strip()


def _turn(role: str, text: str) -> Dict[str, Any]:
    return {"role": role, "parts": [{"text": text}]}


def _error_message(e: urllib.error.HTTPError) -> str:
    raw = e.read() or b""
    try:
        return json.loads(raw)["error"]["message"][:160]
    except Exception:
        # 空 body 的 404、Google 前端吐的 HTML 都会走到这里
        return "（无错误信息）" if not raw.strip() else raw[:80].decode(errors="replace")


def _load_key(cfg: Dict[str, Any]) -> str:
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    if key:
        return key
    path = os.path.expanduser(cfg.get("keyFile") or "~/.repeat-ai/gemini.key")
    try:
        with open(path) as f:
            key = f.read().strip()
    except OSError:
        key = ""
    if not key:
        raise LlmMtError(
            f"没找到 Gemini API key。去 https://aistudio.google.com/apikey 建一个，存到 {path}，"
            "或设环境变量 GEMINI_API_KEY")
    return key
