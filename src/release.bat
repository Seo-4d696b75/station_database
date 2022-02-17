set version=%1

git add -N .

for /f "usebackq" %%A in (`git diff --name-only -- out/main/* ^| find /c /v "" `) do set count=%%A
if %count% gtr 0 (
  ruby src/script/release.rb -s out/main/data.json -d latest_info.json -v %version%
  if errorlevel 1 call :stop
) else (
  echo "no change in out/main/*"
)

for /f "usebackq" %%A in (`git diff --name-only -- out/extra/* ^| find /c /v "" `) do set count=%%A
if %count% gtr 0 (
  ruby src/script/release.rb -s out/extra/data.json -d latest_info.extra.json -v %version%
  if errorlevel 1 call :stop
) else (
  echo "no change in out/extra/*"
)

exit /b

:stop
echo "stop release step"
exit 1