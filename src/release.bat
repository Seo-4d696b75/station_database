set version=%1
ruby src/script/release.rb -s out/main/data.json -d latest_info.json -v %version%
ruby src/script/release.rb -s out/extra/data.json -d latest_info.extra.json -v %version%