load('src/script/io.rb')
load('src/script/kdtree.rb')
require 'optparse'
require 'parallel'

# 指定したデータセットでビルドする
#
# CLI引数
# -e [--extra]: extraデータセットを対象とします
#
# 入力一覧
# - 駅データ src/station.csv
# - 路線データ src/line.csv
# - 路線ポリライン src/polyline/*.json
#
# 出力先: out/${dataset}/
#

extra = false
opt = OptionParser.new
opt.on('-e', '--extra') { extra = true }
opt.parse!(ARGV)
ARGV.clear

dir = "out/#{extra ? 'extra' : 'main'}"

# clean
puts 'cleaning'
Dir.glob(["#{dir}/**/*.json", "#{dir}/**/*.csv"]).each { |file| File.delete(file) }

# 駅・路線マスターデータの取得
puts 'reading src/*.csv'
stations = read_csv_stations 'src/station.csv'
lines = read_csv_lines 'src/line.csv'

line_map = {}
lines.each { |l| line_map[l['code']] = l }
station_map = {}
stations.each { |s| station_map[s['code']] = s }

# データセットの調整
unless extra
  stations.reject! do |s|
    s['extra']
  end
  lines.reject! do |l|
    l['extra']
  end
end

# 駅の詳細（ボロノイ領域・隣接点・Kd-tree）
puts 'read src/diagram/build/*.json'
tree = read_json("src/diagram/build/diagram#{extra ? '.extra' : ''}.json")
assert_equal stations.length, tree['node_list'].length, 'kd-tree頂点数が駅数と異なります'
tree['node_list'].map! do |e|
  # nullでもkeyを要求する
  e['left'] = nil unless e.key?('left')
  e['right'] = nil unless e.key?('right')

  # 対応する駅
  s = station_map[e['code']]
  assert s, "kd-treeの頂点に対応する駅が見つかりません node:#{JSON.dump(e)}"
  # stationsと同じインスタンスを持たせておく
  s.merge!(e)
end

# 路線登録駅の取得
puts 'reading src/line/*.json'
registers = []
lines.each do |line|
  details = read_json "src/line/#{line['code']}.json"
  # 登録駅数
  count = 0

  line['station_list'] = details['station_list'].map do |r|
    station = station_map[r['code']]

    # `extra`属性の曖昧性を解消
    # src/*.csv extra: 路線・駅自体のextra属性
    # src/line/*.json .station_list[].extra:
    #   路線(extra=true)における駅(extra=true)の登録のうち、
    #   駅メモ実装には含まれない登録のみextra=trueを指定している
    r['extra'] = station['extra'] || line['extra'] || r['extra']

    # mainデータセットの登録駅に注意
    next nil if !extra && r['extra']

    # nullでもkeyを要求する
    r['numbering'] = nil unless r.key?('numbering')

    count += 1
    registers << {
      'station_code' => station['code'],
      'line_code' => line['code'],
      'index' => count,
      'numbering' => (n = r['numbering']) ? n.join('/') : 'NULL',
      'extra' => r['extra']
    }
    # 駅要素側にも登録路線を記憶
    station['lines'] << line['code']
    # 駅の詳細情報を追加する
    # extraの意味が路線登録=>駅自体に変わる点に注意
    r.delete('extra')
    next station.merge(r)
  end.compact
  line['station_size'] = line['station_list'].length
end

# line/*.json
puts "writing #{dir}/line/*.json"
lines.each do |line|
  line.write_line_detail_json "#{dir}/line/#{line['code']}.json", extra
end

# *.json
puts "writing #{dir}/*.json"
lines.write_line_json "#{dir}/line.json", extra
stations.write_station_json "#{dir}/station.json", extra
tree.write_tree_json "#{dir}/tree.json"
stations.write_delaunay_json "#{dir}/delaunay.json"

# *.csv
puts "writing #{dir}/*.csv"
stations.write_station_csv "#{dir}/station.csv", extra
lines.write_line_csv "#{dir}/line.csv", extra
registers.write_register_csv "#{dir}/register.csv", extra

# polyline/*.json
puts "writing #{dir}/polyline/*.json"
Parallel.each(lines, in_threads: 4) do |line|
  code = line['code'].to_i
  src = "src/polyline/#{code}.json"
  next unless File.exist?(src)

  data = parse_polyline(read_json(src))
  data.write_polyline_json "#{dir}/polyline/#{code}.json"
end

# tree/*.json
puts "writing #{dir}/tree/*.json"

root = KdTreeNode.new(station_map[tree['root']], 0, station_map)
segments = root.serialize(4)

segments.each do |seg|
  seg['node_list'].map! do |n|
    s = station_map[n['code']]
    # 駅の詳細情報を追加する
    s.merge(n)
  end
  seg.write_tree_segment_json "#{dir}/tree/#{seg['name']}.json", extra
end
