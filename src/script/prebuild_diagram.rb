load('src/script/io.rb')

# 駅座標図形計算の入力データを用意する
#
# - 入力: src/station.csv
# - 出力:
#   - src/diagram/build/station.json
#   - src/diagram/build/station.extra.json

stations = read_csv_stations 'src/station.csv'

# extraデータセット
puts "station size (extra): #{stations.length}"
stations.write_diagram_json 'src/diagram/build/station.extra.json'

# mainデータセット
stations.reject! { |s| s['extra'] }
puts "station size (main): #{stations.length}"
stations.write_diagram_json 'src/diagram/build/station.json'
