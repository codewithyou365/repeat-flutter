"""服务端当前用哪几个模型。

为什么归服务端而不是手机：手机的清单是 assets/ai/catalog.json，里面没有
catalog.local.json 那几个服务端专属大模型（whisper-turbo 之类），由手机指定的话
那些模型下下来也永远用不上。算力在哪，模型就在哪选。

**语言不在这儿**：language 说的是"我在说什么话"，跟算力无关，仍由手机每次请求带上来。
**音色 sid 在这儿**：它只对特定 TTS 模型有意义，模型换了 sid 就可能越界。
"""

import json
import os
from typing import Any, Dict, Optional

import catalog as cat

ROLES = ("asr", "mt", "tts")


class Selection:
    def __init__(self, asr: str = "", mt: str = "", tts: str = "",
                 tts_sid: int = 0, tts_speed: float = 1.0):
        self.asr = asr
        self.mt = mt
        self.tts = tts
        self.tts_sid = tts_sid
        self.tts_speed = tts_speed

    def get(self, role: str) -> str:
        return getattr(self, role, "")

    def set(self, role: str, model_id: str) -> None:
        if role not in ROLES:
            raise ValueError(f"unknown role: {role}")
        setattr(self, role, model_id)

    def to_json(self) -> Dict[str, Any]:
        return {"asr": self.asr, "mt": self.mt, "tts": self.tts,
                "ttsSid": self.tts_sid, "ttsSpeed": self.tts_speed}

    @staticmethod
    def path(root: str) -> str:
        return os.path.join(os.path.dirname(os.path.abspath(root)), "selection.json")

    @staticmethod
    def load(root: str) -> "Selection":
        try:
            with open(Selection.path(root), "r", encoding="utf-8") as f:
                d = json.load(f)
            return Selection(d.get("asr", ""), d.get("mt", ""), d.get("tts", ""),
                             int(d.get("ttsSid", 0) or 0), float(d.get("ttsSpeed", 1.0) or 1.0))
        except (OSError, ValueError, TypeError):
            return Selection()

    def save(self, root: str) -> None:
        os.makedirs(os.path.dirname(Selection.path(root)), exist_ok=True)
        with open(Selection.path(root), "w", encoding="utf-8") as f:
            json.dump(self.to_json(), f)

    def resolve(self, role: str, cl: cat.Catalog, root: str) -> Optional[cat.ModelEntry]:
        """这个角色**实际会用**的模型。

        回退链和手机端 AiModelHelp.selectedFor 保持一致：存的 id 装好了且担得起这个
        角色就用它，否则退到"任意一个装好的该角色模型"，都没有返回 None。

        为什么要回退：用户在网页上删掉正在用的模型时，推理不该直接崩——
        换一个还能跑的接着跑，比报错强。
        """
        mid = self.get(role)
        if mid:
            e = cl.by_id(mid)
            if e is not None and role in e.roles and cat.is_installed(root, mid):
                return e
        for e in cl.by_role(role):
            if cat.is_installed(root, e.id):
                return e
        return None

    def resolved(self, cl: cat.Catalog, root: str) -> Dict[str, Any]:
        """三个角色实际生效的模型。跟 to_json() 存的值可能不同（模型被删时）。"""
        out: Dict[str, Any] = {}
        for role in ROLES:
            e = self.resolve(role, cl, root)
            out[role] = None if e is None else {
                "id": e.id, "name": e.name, "speakers": e.speakers, "voices": e.voices,
                # 存的和实际用的不是一个，网页上要提示"已回退"
                "fellBack": bool(self.get(role)) and e.id != self.get(role),
            }
        return out
