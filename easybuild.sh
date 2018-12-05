#!/bin/bash

npm run build

rm -r docs/static
rm docs/index.html

cp -r dist/static docs/static
cp dist/index.html docs/index.html
