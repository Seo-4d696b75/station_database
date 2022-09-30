FOR /F "usebackq delims== tokens=1,2" %%i IN ("src/.env") do SET %%i=%%j

java -jar %DIAGRAM_JAR_PATH% src/solved/station.json src/diagram/station.json
if errorlevel 1 call :stop

java -jar %DIAGRAM_JAR_PATH% src/solved/station.extra.json src/diagram/station.extra.json
if errorlevel 1 call :stop

exit /b

:stop
echo "stop diagram step"
exit 1