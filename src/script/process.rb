load('script/utils.rb')
load('script/kdtree.rb')

version = ARGV[0].to_i
puts "version: #{version}"

dir_dst = "../out"

print "read soved line data..."
lines = read_json('solved/line.json')
puts "size:#{lines.length}"

print "read soved station data..."
stations = read_json('solved/station.json')
puts "size:#{stations.length}"

station_map = {}
stations.each do |s|
  station_map[s['name']] = s
  station_map[s['code']] = s
end

# 駅の詳細（ボロノイ領域・隣接点・Kd-tree）
puts 'read diagram details'
tree = read_json('diagram/station.json')
if stations.length != tree['node_list'].length
	puts "Error > station size mismatch. list:#{stations.length} diagram:#{tree['node_list'].length}"
	exit(0)
end


node_map = {}
tree['node_list'].each do |e|
	code = e['code']
	s = station_map[code]
	if !s
		puts "Error > station not found. code:#{code}"
		exit(0)
	end
	s['voronoi'] = e.delete('voronoi')
	s['next'] = e.delete('next')
	node_map[code] = e
end

puts "read station-list and polyline data."
lines_details = []
lines.each do |line|
	# 路線の詳細情報
	path = "details/line/#{line['code']}.json"
  details = read_json(path)
  if  details['name'] != line['name']
    puts "Error > line name mismatch line:#{JSON.dump(line)}"
    exit(0)
  end
  line.each{|key,value| details[key]=value}
  # 登録路線の抽出（駅メモ）
  details['station_list'].select! do |e|
    s = station_map[e['code']]
    next false if !s
    if e['name'] != s['name']
      puts "Error > unknown station item. expected:#{e} found:#{s}"
      exit(0)
    end
    next true
  end
  if details['station_list'].length != line['station_size']
    puts "Error > station size mismatch. line:#{line} <=> details:#{details['station_list']}"
    exit(0)
  end

	# 路線ポリライン
	path = "polyline/solved/#{line['code']}.json"
	if File.exists?(path)
		polyline = read_json(path)
		details['east'] = polyline['east']
		details['west'] = polyline['west']
		details['north'] = polyline['north']
		details['south'] = polyline['south']
		details['polyline_list'] = polyline['polyline_list']
  end
  
  list = details['station_list']
  # 路線ファイルの書き出し
  details['station_list'] = list.map do |e|
    s = station_map[e['code']]
    sort_hash(e.merge(s))
  end
  File.open("#{dir_dst}/line/#{line['code']}.json",'w') do |f|
    f.write(format_json(sort_hash(details), flat_key:['delta_lng','delta_lat'], flat_array:['station_list']))
  end
  details['station_list'] = list.map do |e|
    e.delete('name')
    next e
  end
  lines_details << details
end


puts "write line list to file."
File.open("#{dir_dst}/line.json", "w") do |f|
	f.write(format_json(lines.map{|e| sort_hash(e)}, flat:true))
end
puts "write station list to file."
File.open("#{dir_dst}/station.json","w") do |f|
	f.write(format_json(stations.map{|e| sort_hash(e)},flat:true))
end
puts "write raw Kd-tree to file."
File.open("#{dir_dst}/tree.json","w") do |f|
	f.write(format_json(tree,flat_array:['node_list']))
end

puts "build Kd-tree"
root = Node.new(node_map[tree['root']],0,node_map)
segments = root.serialize(4)


# write segmented tree
segments.map do |seg|
	details = seg.clone
	details['node_list'] = seg['node_list'].map do |n|
		node = n.clone
		if !node.key?('segment')
			station_map[n['code']].each{|key,value| node[key] = value}
		end
		sort_hash(node)
	end
	details
end.each do |seg|
	File.open("#{dir_dst}/tree/#{seg['name']}.json","w") do |f|
		f.write(format_json(seg,flat_array:['node_list']))
	end
end



# one-file
puts "write all the data to one file."
data = {}
data['version'] = version
data['stations'] = stations.map{|e| sort_hash(e)}
data['lines'] = lines_details.map{|e| sort_hash(e)}
data['tree_segments'] = segments
File.open("#{dir_dst}/data.json","w") do |f|
	f.write(format_json(data,flat_array:['stations','station_list','polyline_list','node_list']))
end

puts 'All done.'