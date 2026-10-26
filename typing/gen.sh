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

  # QuickJS 里是普通脚本、没有模块加载，所以 service/common/ 下的公共代码是拼进每个 service 的：
  # --outFile 把这些文件按顺序编成一个脚本，bridge.ts 打头（别的公共文件会用到它的类型）。
  local common_ts
  common_ts=$(ls service/common/*.ts | grep -v '/bridge.ts$')
  # shellcheck disable=SC2086
  pnpm exec tsc service/common/bridge.ts $common_ts "$ts_path" \
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
