#!/bin/bash

deal() {
  local name="$1"
  local src_ts="service/${name}.ts"
  local src_ts_dir="service/${name}/${name}.ts"
  local out_js="dist/service/${name}.js"
  local test_js="../assets/service/${name}.js"

  local ts_path="$src_ts"
  if [ -f "$src_ts_dir" ]; then
    ts_path="$src_ts_dir"
  fi

  # QuickJS 里是普通脚本、没有模块加载，所以公共的 service/common/bridge.ts 是拼进每个 service 的：
  # --outFile 把两个文件按顺序编成一个脚本。
  pnpm exec tsc service/common/bridge.ts "$ts_path" \
    --target ES2020 \
    --module None \
    --outFile "$out_js" \
    --skipLibCheck
  if [ -f "$out_js" ]; then
    cp "$out_js" "$test_js"
  else
    echo "Missing service source for: $name" >&2
    exit 1
  fi
}

rm -f dist.zip
rm -rf dist/
pnpm build
mkdir -p dist/service
deal type
deal blank_it_right
deal word_slicer
deal japanese
deal word_ask
deal shadow
(cd dist && zip -r ../dist.zip .)

echo "Build and packaging complete: dist.zip"
