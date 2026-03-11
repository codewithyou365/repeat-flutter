#!/bin/bash

rm -f dist.zip
rm -rf dist/
pnpm build

if [ -f "../assets/editor/service/type.js" ]; then
  cp ../assets/editor/service/type.js service/type.js
fi

cp service/type.js dist/

(cd dist && zip -r ../dist.zip .)

echo "Build and packaging complete: dist.zip"