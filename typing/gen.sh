#!/bin/bash

rm -f dist.zip
rm -rf dist/
pnpm build

if [ -f "../assets/editor/service.js" ]; then
  cp ../assets/editor/service.js dist/
  echo "Copied service.js from assets."
else
  cp service.js dist/
  echo "Copied local service.js."
fi

(cd dist && zip -r ../dist.zip .)

echo "Build and packaging complete: dist.zip"