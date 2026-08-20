#!/usr/bin/env bash
# 启动跟读打分服务。默认端口 8766，模型放 ~/.repeat-shadow/models。
#
# venv 优先用自己目录下的 .venv；没有就复用 server/ai/.venv——
# 那边已经装了 torch / transformers / numpy / fastapi，这边真正新增的
# 只有 phonemizer-fork 和 espeakng-loader，没必要为此再装一份 2GB 的 torch。
set -e
cd "$(dirname "$0")"
if [ -d .venv ]; then
  source .venv/bin/activate
elif [ -d ../ai/.venv ]; then
  source ../ai/.venv/bin/activate
fi
exec python server.py "$@"
