load('src/script/io.rb')
load('src/script/utils.rb')

# 駅座標図形計算の入力データを用意する
#
# - 入力: src/station.csv
# - 出力:
#   - src/diagram/build/station.json
#   - src/diagram/build/station.extra.json

def prebuild(extra, stations)
  File.open("src/diagram/build/station#{extra ? '.extra' : ''}.json", 'w') do |f|
    list = stations.select do |s|
      extra || !s['extra']
    end
    list.map!(&:diagram_json)
    f.write(format_json(list, flat_array: [:root]))
  end
end

stations = read_csv_stations

impl_size = stations.reject { |s| s['extra'] }.length
puts "station size: #{stations.length} (impl #{impl_size})"

prebuild false, stations
prebuild true, stations
