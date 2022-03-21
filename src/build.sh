set -e

version=$1
if [ $# -ne 1 ]; then
  echo "version string not found"
  exit 1
fi

test 0 -eq 9

./src/check.sh

./src/diagram.sh

ruby src/script/polyline.rb

./src/pack.sh $version

/src/release.sh $version


git add ./src ./out
git commit -m "[build] version ${version}"

git add ./latest*
git commit -m "[update] version info ${version}"
