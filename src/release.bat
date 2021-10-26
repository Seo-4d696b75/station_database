set version=%1
ruby src/script/release.rb -s out/main/data.json -d latest_info.json -v %version%
if errorlevel 1 call :stop

ruby src/script/release.rb -s out/extra/data.json -d latest_info.extra.json -v %version%
if errorlevel 1 call :stop

exit /b

:stop
echo "stop release step"
exit 1