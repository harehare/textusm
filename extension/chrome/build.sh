#!/bin/bash

set -ex

npm run prod

DIST=zip
mkdir -p $DIST

cp manifest.json $DIST/
cp index.html $DIST/
cp -r dist $DIST/
cp -r images $DIST/

cd $DIST && zip -r textusm.zip *
