FOR /F "usebackq delims== tokens=1,2" %%i IN ("src/build.env") do SET %%i=%%j

call ./src/check.bat

call ./src/diagram.bat

ruby src/script/polyline.rb
if errorlevel 1 (
  echo "stop polyline step"
  exit 1
)

call ./src/pack.bat %VERSION%

call ./src/release.bat %VERSION%

git add ./src ./out
git commit -m "[build] version %VERSION%"

git add ./latest*
git commit -m "[update] version info %VERSION%"
