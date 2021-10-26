set version=%1

call ./src/check.bat

call ./src/diagram.bat

ruby src/script/polyline.rb
if errorlevel 1 (
  echo "stop polyline step"
  exit 1
)

call ./src/pack.bat %version%

call ./src/release.bat %version%

echo "build complete"
exit

git add .
git commit -m "[update] version %version%"
git push origin feature/update

git tag -a "v%version%" -m "version %version%"
git push origin "v%version%"