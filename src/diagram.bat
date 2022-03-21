set JAR=""

java -jar %JAR% src/solved/station.json src/diagram/station.json
if errorlevel 1 call :stop

java -jar %JAR% src/solved/station.extra.json src/diagram/station.extra.json
if errorlevel 1 call :stop

exit /b

:stop
echo "stop diagram step"
exit 1