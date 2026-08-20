"""模型在磁盘上的位置和完整性判断。

只有一个模型，所以不需要 server/ai 那套 catalog/overlay 机制——
这里是它的极简版：装在哪、装全了没、装好了打个 .ok 标记。

模型根目录特意和 server/ai 的 ~/.repeat-ai/models 分开：那边的模型要和手机
对账（手机能上传、能下发），而这个 1.26 GB 的 wav2vec2 永远不会进手机。
两边混在一起只会让 server/ai 的 /v1/models 对账接口看到它不认识的条目。
"""

import os
from typing import List

# ModelScope 上的 repo 名和 HuggingFace 一致，直接用同一个字符串。
MODEL_ID = "facebook/wav2vec2-lv-60-espeak-cv-ft"

# 本地目录名不能带斜杠。
MODEL_DIR_NAME = "wav2vec2-lv-60-espeak-cv-ft"

DEFAULT_MODEL_ROOT = os.path.expanduser("~/.repeat-shadow/models")

OK_MARKER = ".ok"

# 推理真正要用到的文件。仓库里还有 .gitattributes / README.md / configuration.json，
# 那些是 ModelScope 的仓库元数据，不下。
#
# special_tokens_map.json 和 tokenizer_config.json 我们其实不读（词表是自己解析
# vocab.json 的，见 g2p.py 里为什么不用 Wav2Vec2Processor），但一并下下来，
# 这样这个目录直接喂给 transformers 也能用，排错时省事。
WEIGHT_FILE = "pytorch_model.bin"
SAFETENSORS_FILE = "model.safetensors"

REQUIRED_FILES: List[str] = [
    "config.json",
    "preprocessor_config.json",
    "vocab.json",
    "tokenizer_config.json",
    "special_tokens_map.json",
    WEIGHT_FILE,
]

# 整仓大小，用于给下载进度和设置页显示一个预期值（字节）。
TOTAL_SIZE = 1_263_547_434


def model_root(root: str = "") -> str:
    return root or os.environ.get("REPEAT_SHADOW_MODELS", "") or DEFAULT_MODEL_ROOT


def model_dir(root: str = "") -> str:
    return os.path.join(model_root(root), MODEL_DIR_NAME)


def weight_path(root: str = "") -> str:
    """优先用 safetensors。

    ModelScope 上只有 pytorch_model.bin。transformers 5.x 对 .bin 的加载路径
    在收紧（torch.load 的 weights_only 默认值变过），所以 install.py 装完会把它
    转成 safetensors。转换成功后 .bin 会被删掉，这里就走 safetensors 分支。
    """
    d = model_dir(root)
    st = os.path.join(d, SAFETENSORS_FILE)
    if os.path.exists(st):
        return st
    return os.path.join(d, WEIGHT_FILE)


def missing_files(root: str = "") -> List[str]:
    """缺哪些文件。空 list 表示齐了。

    权重那一项特殊：.bin 和 .safetensors 有任意一个就算齐。
    """
    d = model_dir(root)
    missing = []
    for name in REQUIRED_FILES:
        if name == WEIGHT_FILE:
            if not os.path.exists(os.path.join(d, WEIGHT_FILE)) and \
                    not os.path.exists(os.path.join(d, SAFETENSORS_FILE)):
                missing.append(f"{WEIGHT_FILE} 或 {SAFETENSORS_FILE}")
            continue
        if not os.path.exists(os.path.join(d, name)):
            missing.append(name)
    return missing


def is_installed(root: str = "") -> bool:
    """装好了没。

    .ok 标记和文件齐全两个条件都要满足：.ok 单独存在挡不住有人手贱删了权重，
    文件齐全单独成立挡不住半截下载正好凑齐了体积为 0 的占位文件。
    """
    return os.path.exists(os.path.join(model_dir(root), OK_MARKER)) and not missing_files(root)


def mark_ok(root: str = "") -> None:
    with open(os.path.join(model_dir(root), OK_MARKER), "w") as f:
        f.write("ok\n")


def clear_ok(root: str = "") -> None:
    p = os.path.join(model_dir(root), OK_MARKER)
    if os.path.exists(p):
        os.remove(p)


def disk_usage(root: str = "") -> int:
    """已占磁盘字节数。目录不存在返回 0。"""
    d = model_dir(root)
    total = 0
    for dirpath, _, names in os.walk(d):
        for n in names:
            try:
                total += os.path.getsize(os.path.join(dirpath, n))
            except OSError:
                pass
    return total
