"""读 assets/ai/catalog.json，并把 cfg 里的相对路径解析成绝对路径。

这份清单和手机端共用同一个文件：手机装什么模型、服务端就装什么模型，
两边跑出来的结果才可能一致。所以这里**不要**另起一份清单。

对应的 Dart 实现在 lib/logic/ai/ai_catalog.dart 和 lib/logic/ai/ai_model_paths.dart，
改了那边记得同步这边。
"""

import json
import os
from typing import Any, Dict, List, Optional

# sherpa 各 config 里值是"文件/目录路径"的字段名。
# 必须和 lib/logic/ai/ai_model_paths.dart 的 pathKeys 保持一致：
# 用白名单而不是"看着像路径就换"，是因为 cfg 里 task / language / provider /
# decodingMethod 同样是字符串，绝不能被拼上目录前缀。
PATH_KEYS = {
    "acousticModel", "bpeVocab", "cachedDecoder", "convFrontend", "ctTransformer",
    "dataDir", "decoder", "dictDir", "durationPredictor", "embedding", "encoder",
    "encoderAdaptor", "hotwordsFile", "joiner", "lexicon", "llm", "lmFlow", "lmMain",
    "mergedDecoder", "model", "preprocessor", "ruleFars", "ruleFsts", "telespeechCtc",
    "textConditioner", "textEncoder", "tokenScoresJson", "tokenizer", "tokens",
    "ttsJson", "uncachedDecoder", "unicodeIndexer", "vectorEstimator", "vocabJson",
    "vocoder", "voices",
}

_HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CATALOG = os.path.normpath(os.path.join(_HERE, "..", "..", "assets", "ai", "catalog.json"))
DEFAULT_MODEL_ROOT = os.path.expanduser("~/.repeat-ai/models")

# 服务端专属清单。存在就叠加到共享清单之上：同 id 覆盖，新 id 追加。
# 手机端读的是 assets/ai/catalog.json，看不到这里的东西——所以这份文件专门放
# 那些手机装不下、但 Mac 随便跑的大模型。
LOCAL_CATALOG = os.path.join(_HERE, "catalog.local.json")

OK_MARKER = ".ok"


class ModelFile:
    """清单里 files[] 的一项。紧凑键名 p/u/h/s 和手机端一致。"""

    def __init__(self, raw: Dict[str, Any]):
        self.path: str = raw.get("p", "")
        self.url: str = raw.get("u", "")
        self.hash: str = raw.get("h", "")  # sha1，可能为空
        self.size: int = int(raw.get("s", 0) or 0)


class ModelEntry:
    def __init__(self, raw: Dict[str, Any]):
        self.id: str = raw["id"]
        role = raw.get("role", [])
        self.roles: List[str] = [role] if isinstance(role, str) else list(role)
        self.name: str = raw.get("name", self.id)
        self.langs: List[str] = list(raw.get("langs", []))
        self.size: int = int(raw.get("size", 0) or 0)
        self.speakers: int = int(raw.get("speakers", 1) or 1)
        self.note: str = raw.get("note", "") or ""
        # "sherpa"（默认）= 交给 sherpa-onnx 跑；"text" = 文本翻译，走 text_mt.py。
        # 两者的 cfg 结构完全不同，加载路径也不同，所以必须显式区分。
        self.kind: str = raw.get("kind", "sherpa") or "sherpa"
        self.license: str = raw.get("license", "") or ""
        # 音色名，下标即 speaker id；只用于显示，空表示这个模型没给名字
        self.voices: List[str] = list(raw.get("voices", []) or [])
        self.cfg: Dict[str, Any] = raw.get("cfg", {}) or {}
        self.files: List[ModelFile] = [ModelFile(f) for f in raw.get("files", [])]
        zip_raw = raw.get("zip")
        # 压缩包整包下载的模型（kokoro 的 espeak-ng-data 有 378 个小文件，
        # 逐个列进清单不现实）。解压后的文件清单无从校验，只能校验包本身。
        self.zip: Optional[ModelFile] = ModelFile(zip_raw) if zip_raw else None

    @property
    def archive_ext(self) -> str:
        """压缩包扩展名。解压要按扩展名分派，所以从 url 里抠出来。"""
        if not self.zip:
            return ""
        url = self.zip.url.split("?")[0]
        for ext in (".tar.bz2", ".tar.gz", ".tar.xz", ".zip"):
            if url.endswith(ext):
                return ext
        return os.path.splitext(url)[1]


class Catalog:
    def __init__(self, path: str = DEFAULT_CATALOG, local: Optional[str] = LOCAL_CATALOG):
        with open(path, "r", encoding="utf-8") as f:
            raw = json.load(f)
        self.path = path
        self.version: int = int(raw.get("v", 0))
        self.models: List[ModelEntry] = [ModelEntry(m) for m in raw.get("models", [])]
        self.presets: Dict[str, List[str]] = {
            p["id"]: list(p.get("models", [])) for p in raw.get("presets", [])
        }
        # 手机端也有的模型，用来区分"这个模型手机传得上来"和"这个只能服务端自己下"
        self.shared_ids = {m.id for m in self.models}

        if local and os.path.exists(local):
            with open(local, "r", encoding="utf-8") as f:
                extra = json.load(f)
            by_id = {m.id: m for m in self.models}
            for raw_m in extra.get("models", []):
                m = ModelEntry(raw_m)
                if m.id in by_id:
                    self.models[self.models.index(by_id[m.id])] = m
                else:
                    self.models.append(m)
            for p in extra.get("presets", []):
                self.presets[p["id"]] = list(p.get("models", []))

        self._by_id = {m.id: m for m in self.models}

    def is_local_only(self, model_id: str) -> bool:
        """只在服务端清单里、手机没有的模型。网页上要标出来。"""
        return model_id not in self.shared_ids

    def by_id(self, model_id: str) -> Optional[ModelEntry]:
        return self._by_id.get(model_id)

    def by_role(self, role: str) -> List[ModelEntry]:
        return [m for m in self.models if role in m.roles]


def resolve_paths(cfg: Any, model_dir: str) -> Any:
    """返回一份新的 cfg，把白名单字段里的相对路径换成绝对路径。原 cfg 不动。"""
    if isinstance(cfg, dict):
        out: Dict[str, Any] = {}
        for k, v in cfg.items():
            if isinstance(v, dict):
                out[k] = resolve_paths(v, model_dir)
            elif isinstance(v, str) and k in PATH_KEYS and v:
                out[k] = _resolve_value(v, model_dir)
            else:
                out[k] = v
        return out
    return cfg


def _resolve_value(value: str, model_dir: str) -> str:
    # ruleFsts / lexicon 允许写成逗号分隔的多个路径
    parts = []
    for seg in value.split(","):
        p = seg.strip()
        if not p:
            continue
        parts.append(p if os.path.isabs(p) else os.path.join(model_dir, p))
    return ",".join(parts)


def model_dir(root: str, model_id: str) -> str:
    return os.path.join(root, model_id)


def is_installed(root: str, model_id: str) -> bool:
    return os.path.exists(os.path.join(model_dir(root, model_id), OK_MARKER))


def missing_files(root: str, entry: ModelEntry) -> List[str]:
    """还缺哪些文件（相对模型目录）。zip 类模型没有逐文件清单，只能看 .ok。"""
    d = model_dir(root, entry.id)
    if not entry.files and (entry.cfg.get("require") or entry.kind == "text"):
        # 没有逐文件清单的模型：text 是本地转换出来的，llm-mt / mlx-* 是整仓库拖下来的
        # （文件名还随分片数变，7B 是两片、3B 是一片）。cfg.require 点名哪些东西必须在，
        # 不然一个空目录也会被 complete 判成"齐了"。
        #
        # **按 require 存不存在判，别按 kind 列名单**：kind 是会加的（text -> llm-mt ->
        # mlx-audio-stt），每加一种就得回来改这里的话，迟早漏一种，而漏了不报错——
        # 只是下载校验静默失效。
        want = entry.cfg.get("require") or ["ct2"]
        return [w for w in want if w and not os.path.exists(os.path.join(d, w))]
    if entry.zip:
        return [] if os.path.exists(os.path.join(d, OK_MARKER)) else ["<archive>"]
    missing = []
    for f in entry.files:
        p = os.path.join(d, f.path)
        if not os.path.exists(p):
            missing.append(f.path)
        elif f.size and os.path.getsize(p) != f.size:
            missing.append(f.path)
    return missing
