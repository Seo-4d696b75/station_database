JAR="/Users/k_senda/Documents/ekimemo/diagram/build/artifacts/diagram_app_main_jar/diagram.app.main.jar"

java -jar $JAR src/solved/station.json src/diagram/station.json
if [ $? -ne 0 ]; then
    echo "fail to calc diagram(impl)"
    exit 1
fi

java -jar $JAR src/solved/station.extra.json src/diagram/station.extra.json
if [ $? -ne 0 ]; then
    echo "fail to calc diagram(extra)"
    exit 1
fi    