#!/bin/bash

deal() {
  local name="$1"
  local src_ts="service/${name}.ts"
  local src_ts_dir="service/${name}/${name}.ts"
  local out_js="dist/service/${name}.js"
  local test_js="../assets/service/${name}.js"

  local ts_path="$src_ts"
  local root_dir="service"
  if [ -f "$src_ts_dir" ]; then
    ts_path="$src_ts_dir"
    root_dir="service/${name}"
  fi

  pnpm exec tsc "$ts_path" \
    --target ES2020 \
    --module ES2020 \
    --moduleResolution Node \
    --rootDir "$root_dir" \
    --outDir dist/service \
    --esModuleInterop \
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
(cd dist && zip -r ../dist.zip .)

echo "Build and packaging complete: dist.zip"