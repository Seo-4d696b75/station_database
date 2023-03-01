set -e

source ./src/build.env

./src/check.sh

./src/diagram.sh

ruby src/script/polyline.rb

./src/pack.sh $VERSION

./src/release.sh $VERSION


git add ./src ./out
git commit -m "[build] version ${VERSION}"

git add ./latest*
git commit -m "[update] version info ${VERSION}"
