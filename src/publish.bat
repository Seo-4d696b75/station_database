set version=%1
set version=%1
if "%version%"=="" (
  echo "version string empty"
  exit 1
)

git tag -a "v%version%" -m "version %version%"
git push origin "v%version%"