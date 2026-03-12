#!/bin/bash

rm -f dist.zip
rm -rf dist/
pnpm build

mkdir dist/service
if [ -f "../assets/service/type.js" ]; then
  cp ../assets/service/type.js service/type.js
fi

cp service/type.js dist/service/

(cd dist && zip -r ../dist.zip .)

echo "Build and packaging complete: dist.zip"