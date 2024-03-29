#!/bin/sh

if [ $# = 0 ] || [ "$1" != "main" -a "$1" != "extra" ]; then
  echo "dataset (main/out) must be specified"
  exit 1
fi

cd out/$1
rm *.zip
mkdir csv json
cp *.csv csv
cp -r *.json line polyline json
zip -r -q csv.zip csv
zip -r -q json.zip json
rm -r csv json
du -h *.zip