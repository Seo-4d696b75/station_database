source ./src/.env

java -jar $DIAGRAM_JAR_PATH src/solved/station.json src/diagram/station.json
if [ $? -ne 0 ]; then
    echo "fail to calc diagram(impl)"
    exit 1
fi

java -jar $DIAGRAM_JAR_PATH src/solved/station.extra.json src/diagram/station.extra.json
if [ $? -ne 0 ]; then
    echo "fail to calc diagram(extra)"
    exit 1
fi    