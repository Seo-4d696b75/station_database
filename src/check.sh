ruby src/script/check.rb -i -d out/main
if [ $? -ne 0 ]; then
    echo "error while checking (impl)"
    exit 1
fi

ruby src/script/check.rb -d out/extra
if [ $? -ne 0 ]; then
    echo "error while checking (extra)"
    exit 1
fi
