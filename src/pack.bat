ruby src/script/pack.rb -i -d out/main -v %1
if errorlevel 1 call :stop

ruby src/script/pack.rb -d out/extra -v %1
if errorlevel 1 call :stop

exit /b

:stop
echo "stop pack step"
exit 1