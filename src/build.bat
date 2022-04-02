set version=%1
if "%version%"=="" (
  echo "version string empty"
  exit 1
)

call ./src/check.bat

call ./src/diagram.bat

ruby src/script/polyline.rb
if errorlevel 1 (
  echo "stop polyline step"
  exit 1
)

call ./src/pack.bat %version%

call ./src/release.bat %version%

git add ./src ./out
git commit -m "[build] version %version%"

git add ./latest*
git commit -m "[update] version info %version%"
