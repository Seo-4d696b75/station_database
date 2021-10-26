ruby src/script/check.rb -i -d out/main
if errorlevel 1 call :stop

ruby src/script/check.rb -d out/extra
if errorlevel 1 call :stop

exit /b

:stop
echo "stop check step"
exit 1