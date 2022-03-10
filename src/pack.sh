ruby src/script/pack.rb -i -d out/main -v $1
if [ $? -ne 0 ]; then
    echo "error while packing (impl)"
    exit 1
fi

ruby src/script/pack.rb -d out/extra -v $1
if [ $? -ne 0 ]; then
    echo "error while packing (extra)"
    exit 1
fi