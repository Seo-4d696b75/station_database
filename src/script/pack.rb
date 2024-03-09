# すべてのデータを集約

load("src/script/utils.rb")
load("src/script/kdtree.rb")
require "optparse"

extra = false
dst = "."
version = 0
opt = OptionParser.new
opt.on("-e", "--extra") { extra = true }
opt.on("-d", "--dst VALUE") { |v| dst = v }
opt.on("-v", "--version VALUE") { |v| version = v.to_i }
opt.parse!(ARGV)
ARGV.clear()

puts "version: #{version}"

# TODO src/*.csv を使う
print "read soved line data..."
lines = read_json("build/line#{extra ? ".extra" : ""}.json")
puts "size:#{lines.length}"

print "read soved station data..."
stations = read_json("build/station#{extra ? ".extra" : ""}.json")
puts "size:#{stations.length}"

station_map = {}
stations.each do |s|
  station_map[s["name"]] = s
  station_map[s["code"]] = s
end

# 駅の詳細（ボロノイ領域・隣接点・Kd-tree）
puts "read diagram details"
tree = read_json("build/diagram#{extra ? ".extra" : ""}.json")
if stations.length != tree["node_list"].length
  puts "Error > station size mismatch. list:#{stations.length} diagram:#{tree["node_list"].length}"
  exit(1)
end

node_map = {}
delaunay_map = {}
tree["node_list"].each do |e|
  code = e["code"]
  s = station_map[code]
  if !s
    puts "Error > station not found. code:#{code}"
    exit(1)
  end
  s["voronoi"] = e.delete("voronoi")
  delaunay_map[code] = e.delete("next")
  node_map[code] = e
end

puts "read station-list and polyline data."
# clean
Dir.glob("#{dst}/line/*").each{ |file|  File.delete(file)}

lines.each do |line|
  # 路線の詳細情報
  path = "src/line/#{line["code"]}.json"
  details = read_json(path)
  line.each { |key, value| details[key] = value }
  # 登録路線の抽出（駅メモ）
  details["station_list"].select! do |e|
    s = station_map[e["code"]]
    next false if !s # TODO station.csv なら必ずhitする
    if extra || (!e["extra"] && !s["extra"] && !line["extra"])
      # 出力先 out/*/line/*.json .station_list[].extra は別の意味になる
      e.delete("extra")
      next true
    end
    next false
  end
  if details["station_list"].length != line["station_size"]
    puts "Error > station size mismatch. line:#{line} <=> details:#{details["station_list"]}"
    exit(1)
  end

  # 路線ポリライン
  path = "build/polyline/#{line["code"]}.json"
  if File.exist?(path)
    polyline = read_json(path)
    File.open("#{dst}/polyline/#{line["code"]}.json", "w") do |f|
      f.write(format_json(sort_hash(polyline), flat_key: ["coordinates"]))
    end
  end

  # 路線ファイルの書き出し
  details["station_list"].map! do |e|
    s = station_map[e["code"]]
    sort_hash(e.merge(s))
  end
  File.open("#{dst}/line/#{line["code"]}.json", "w") do |f|
    f.write(format_json(sort_hash(details), flat_key: ["coordinates"], flat_array: ["station_list"]))
  end
end

puts "write line list to file."
File.open("#{dst}/line.json", "w") do |f|
  f.write(format_json(lines.map { |e| sort_hash(e) }, flat_array: [:root]))
end
puts "write station list to file."
File.open("#{dst}/station.json", "w") do |f|
  f.write(format_json(stations.map { |e| sort_hash(e) }, flat_array: [:root]))
end
puts "write raw Kd-tree to file."
File.open("#{dst}/tree.json", "w") do |f|
  tree["node_list"].map!{|e| sort_hash(e)}
  f.write(format_json(tree, flat_array: ["node_list"]))
end

puts "build Kd-tree"
root = Node.new(node_map[tree["root"]], 0, node_map)
segments = root.serialize(4)

# clean
Dir.glob("#{dst}/tree/*").each{ |file|  File.delete(file)}
# write segmented tree
segments.map do |seg|
  details = seg.clone
  details["node_list"] = seg["node_list"].map do |n|
    node = n.clone
    station_map[n["code"]].each { |key, value| node[key] = value }
    sort_hash(node)
  end
  details
end.each do |seg|
  File.open("#{dst}/tree/#{seg["name"]}.json", "w") do |f|
    f.write(format_json(seg, flat_array: ["node_list"]))
  end
end

puts "write delaunay to file."
stations.each do |s|
  s["next"] = delaunay_map[s["code"]]
end
File.open("#{dst}/delaunay.json", "w") do |f|
  f.write(format_json(stations.map do |s|
    e = {
      "name" => s["name"],
      "code" => s["code"],
      "lat" => s["lat"],
      "lng" => s["lng"],
      "next" => s["next"],
    }
    sort_hash(e)
  end, flat_array: [:root]))
end

puts "All done."
