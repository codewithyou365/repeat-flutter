#!/bin/bash
# 把 typing/ 的前端重新打包，再拷到本 mock 服务器的包目录里，一步完成"改完代码 -> App 能拉到新包"。
#
# 用法（在哪个目录跑都行，路径是按脚本自身位置算的）：
#
#	example/game_server/sync.sh            # 跑 typing/gen.sh，拷 dist.zip -> games/typing.zip
#	example/game_server/sync.sh -b         # 拷之前先把 manifest 的 version +1
#	example/game_server/sync.sh -n foo     # 拷成 games/foo.zip
#	example/game_server/sync.sh -s         # 跳过构建，直接拷现成的 typing/dist.zip
#
# 注意：App 是靠 manifest 里的 version 变大才认为"有更新"的，版本号没动就只会拿到旧包。
# 联调时想让手机重新下载，就带上 -b（改的是 typing/public/manifest.json，会进 git 改动）。
# 服务器本身不用重启：zip 的 mtime/size 一变它就重新解析。

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
typing_dir="$repo_root/typing"
manifest="$typing_dir/public/manifest.json"
games_dir="$script_dir/games"

name="typing"
bump=0
skip_build=0

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--bump) bump=1; shift ;;
    -s|--skip-build) skip_build=1; shift ;;
    -n|--name)
      [ $# -ge 2 ] || { echo "-n 后面要跟包名" >&2; exit 1; }
      name="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,13p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "未知参数: $1（-h 看用法）" >&2; exit 1 ;;
  esac
done

if [ "$bump" = "1" ]; then
  [ -f "$manifest" ] || { echo "找不到 $manifest" >&2; exit 1; }
  # 只动 version 这一行，manifest 其它内容（含注释外的字段顺序）原样保留
  old_version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*\([0-9]\{1,\}\).*/\1/p' "$manifest" | head -n 1)"
  [ -n "$old_version" ] || { echo "manifest 里没找到数字 version" >&2; exit 1; }
  new_version=$((old_version + 1))
  tmp="$manifest.tmp.$$"
  sed "s/\"version\"[[:space:]]*:[[:space:]]*$old_version/\"version\": $new_version/" "$manifest" > "$tmp"
  mv "$tmp" "$manifest"
  echo "manifest version: $old_version -> $new_version"
fi

if [ "$skip_build" = "1" ]; then
  echo "跳过构建，直接用现成的 dist.zip"
else
  echo "== 打包 typing =="
  (cd "$typing_dir" && ./gen.sh)
fi

src="$typing_dir/dist.zip"
[ -f "$src" ] || { echo "没有 $src，先跑一次不带 -s 的构建" >&2; exit 1; }

mkdir -p "$games_dir"
dst="$games_dir/$name.zip"
cp "$src" "$dst"

echo "== 完成 =="
ls -l "$dst"
echo "服务器不用重启，直接刷新即可：cd example/game_server && go run ."
