#!/usr/bin/env bash
# 启动局域网推理服务。默认端口 8767，模型放 ~/.repeat-ai/models。
set -e
cd "$(dirname "$0")"
if [ -d .venv ]; then
  source .venv/bin/activate
fi
exec python server.py "$@"
