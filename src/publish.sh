version=$1
if [ $# -ne 1 ]; then
  echo "version string not found"
  exit 1
fi

git tag -a "v${version}" -m "version ${version}"
git push origin "v${version}"