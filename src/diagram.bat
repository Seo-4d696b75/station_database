set classpath="C:\Users\skaor\Documents\IdeaProject\diagram\out\production\jp.ac.u_tokyo.t.eeic.seo.diagram;C:\Users\skaor\.gradle\caches\modules-2\files-2.1\org.json\json\20200518\41a767de4bde8f01d53856b905c49b2db8862f13\json-20200518.jar;C:\Users\skaor\.gradle\caches\modules-2\files-2.1\com.google.code.gson\gson\2.8.6\9180733b7df8542621dc12e21e87557e8c99b8cb\gson-2.8.6.jar"

java -Dfile.encoding=UTF-8 -classpath %classpath% jp.ac.u_tokyo.t.eeic.seo.station.DiagramCalc src/solved/station.json src/diagram/station.json
if errorlevel 1 call :stop

java -Dfile.encoding=UTF-8 -classpath %classpath% jp.ac.u_tokyo.t.eeic.seo.station.DiagramCalc src/solved/station.extra.json src/diagram/station.extra.json
if errorlevel 1 call :stop

exit /b

:stop
echo "stop diagram step"
exit 1