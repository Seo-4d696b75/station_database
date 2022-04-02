version=$1

git add -N .

count=`git diff --name-only -- out/main/ | wc -l`
if [ $count -gt 0 ]; then
    ruby src/script/release.rb -s out/main/data.json -d latest_info.json -v $version
else
    echo "no change in out/main/"
fi

count=`git diff --name-only -- out/extra/ | wc -l`
if [ $count -gt 0 ]; then
    ruby src/script/release.rb -s out/extra/data.json -d latest_info.extra.json -v $version
else
    echo "no change in out/extra/"
fi
