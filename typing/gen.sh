#!/bin/bash

rm -f dist.zip
rm -rf dist/
pnpm build

mkdir dist/service
if [ -f "../assets/service/type.js" ]; then
  cp ../assets/service/type.js service/type.js
fi
cp service/type.js dist/service/

if [ -f "../assets/service/blank_it_right.js" ]; then
  cp ../assets/service/blank_it_right.js service/blank_it_right.js
fi
cp service/blank_it_right.js dist/service/

if [ -f "../assets/service/word_slicer.js" ]; then
  cp ../assets/service/word_slicer.js service/word_slicer.js
fi
cp service/word_slicer.js dist/service/

(cd dist && zip -r ../dist.zip .)

echo "Build and packaging complete: dist.zip"