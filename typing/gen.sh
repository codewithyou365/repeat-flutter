#!/bin/bash

rm dist.zip
rm -rf dist/
pnpm build
cp service.js dist/
cd dist && zip -r ../dist.zip . && cd ..