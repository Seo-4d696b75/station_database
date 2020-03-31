
load('script/utils.rb')

file_src_line = './solved/line.json'
file_src_station = './details/station.json'
dir_src_details = './details/line'
file_src_details = './details/line.csv'
file_src_diagram = './diagram/station.json'
dir_src_polyline = './polyline/solved'
dir_dst = '../out'
version = ARGV[0].to_i

# soved された路線データ
print "read soved line data..."
lines = read_json(file_src_line)
puts "size:#{lines.length}"


# line name_kana
kana_map = {}
File.open(file_src_details, "r") do |f|
	f.each_line do |l|
		if m = l.chomp.match(/^(.+?),(.+?)$/)
			kana_map[m[1]] = m[2]
		end
	end
end
puts "read line details data. size:#{kana_map.length}"

lines.each do |line|
	# 路線の詳細情報
	path = "#{dir_src_details}/#{line['code']}.json"
	if !File.exists?(path)
		puts "Error > file:#{path} not fount. line:#{JSON.dump(line)}"
		exit(0)
	end
	# 路線ポリラインは廃線のみ欠損許す
	path = "#{dir_src_polyline}/#{line['code']}.json"
	if !File.exists?(path) && !line['closed']
		puts "Error > polyline not found. line:#{JSON.dump(line)}"
		exit(0)
	end
	
	kana = kana_map[line['name']]
	if !kana 
		puts "Error > name-kana not found. line:#{JSON.dump(line)}"
		exit(0)
	end
	line['name_kana'] = kana
end

# soved された駅データ + 詳細（住所・属性・名前かな）
print "read soved station data..."
station_map = {}
stations = []
read_json(file_src_station).each do |s|
	name = s['name']
	if station_map.key?(name)
		puts "Error > name duplicated #{name}"
		exit(0)
	end
	station_map[name] = s
	station_map[s['code']] = s
	stations << s
end
puts "size:#{lines.length}"





def set_details(line,details,polyline,station_map,dir_dst,dir_src)
	name = line['name']
	if name != details['name']
		puts "Error > name mismatch(details). file:#{line['code']}.json line:#{JSON.dump(line)}"
		exit(0)
	end
	if polyline && name != polyline['name']
		puts "Error > name mismatch(polyline). file:#{line['code']}.json line:#{JSON.dump(line)}"
		exit(0)
	end
	size = line['station_size']
	if size != details['station_list'].length
		puts "Error > station list size mismatch. expected:#{size} actual:#{details['station_list'].length} at #{JSON.dump(line)}"
		exit(0)
	end
	line['color'] = details['color'] if details.key?('color')
	line['symbol'] = details['symbol'] if details.key?('symbol')
	line.delete('name_formal') if line['name_formal'] == name

	# 路線詳細の書き出し
	write = false
	details['station_list'].map! do |e|
		s = nil
		if !(s = station_map[e['name']]) && !(s = station_map[e['code']])
			puts "Error > station not found #{e['name']}(#{e['code']}) at station_list #{JSON.dump(line)}"
			exit(0)
		end
		if !s['lines'].include?(line['code'])
			puts "Error > station #{JSON.dump(s)} not registered in line #{JSON.dump(line)}"
			exit(0)
		end
		if e['code'] != s['code']
			## puts "station code chnage. #{e['name']}: #{e['code']}=>#{s['code']}"
			e['code'] = s['code']
			write = true
		end
		if e['name'] != s['name']
			print "station name chnage. #{e['code']}: #{e['name']}=>#{s['name']} Is this OK? Y/N =>"
			exit(0) if gets.chomp.match(/[nN]/)
			e['name'] = s['name']
			write = true
		end
		next sort_hash(e)
	end
	if write
		File.open("#{dir_src}/#{line['code']}.json","w") do |f|
			f.write(format_json(details, flat_array:['station_list']))
		end
	end
	details['code'] = line['code']
	if polyline
		details['east'] = polyline['east']
		details['west'] = polyline['west']
		details['north'] = polyline['north']
		details['south'] = polyline['south']
		details['polyline_list'] = polyline['polyline_list']
	end
	File.open("#{dir_dst}/line/#{line['code']}.json",'w') do |f|
		f.write(format_json(sort_hash(details), flat_key:['delta_lng','delta_lat'], flat_array:['station_list']))
	end
	line.each{|key,value| details[key] = value}
	details['station_list'].each{|e| e.delete('name')}
end

# 路線
lines_details = []

lines.each do |line|
	# 路線の詳細情報
	path = "#{dir_src_details}/#{line['code']}.json"
	details = read_json(path)
	# 路線ポリラインは廃線のみ欠損許す
	path = "#{dir_src_polyline}/#{line['code']}.json"
	polyline = nil
	if File.exists?(path)
		polyline = read_json(path)
	end
	set_details(line,details,polyline,station_map,dir_dst,dir_src_details)
	lines_details << details
end

puts "write line list to file."
File.open("#{dir_dst}/line.json", "w") do |f|
	f.write(format_json(lines.map{|e| sort_hash(e)}, flat:true))
end

# 駅
station_map = {}
stations.each do |s|
	code = s['code']
	if station_map.key?(code)
		puts "Error > station code duplicated #{code}"
		exit(0)
	end
	station_map[code] = s
end

# 駅の詳細（ボロノイ領域・隣接点・Kd-tree）
puts 'read diagram details'
tree = read_json(file_src_diagram)
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
puts "write station list to file."
File.open("#{dir_dst}/station.json","w") do |f|
	f.write(format_json(stations.map{|e| sort_hash(e)},flat:true))
end
puts "write raw Kd-tree to file."
File.open("#{dir_dst}/tree.json","w") do |f|
	f.write(format_json(tree,flat_array:['node_list']))
end

puts "build Kd-tree"
class Node
	attr_reader :code, :depth, :left, :right, :lat, :lng
	attr_accessor :south, :north, :west, :east
	def initialize(data,depth,map)
		@code = data['code']
		@lat = data['lat']
		@lng = data['lng']
		@depth = depth
		@left = data.key?('left') ? Node.new(map[data['left']],depth+1,map) : nil
		@right = data.key?('right') ? Node.new(map[data['right']],depth+1,map) : nil
	end
	def serialize(depth=4)
		@west = -180.0
		@south = -90.0
		@east = 180.0
		@north = 90.0
		segments = []
		root = {}
		segments << root
		root['name'] = 'root'
		root['root'] = @code
		list = []
		to_segment(depth,list,segments)
		root['station_size'] = list.select{|e| !e.key?('segment')}.length
		root['node_list'] = list
		puts "tree-segment name:root size:#{root['station_size']} depth:#{depth}"
		return segments
	end
	def to_segment(depth,nodes,segments)
		if @depth == depth
			node = {'code'=>@code}
			name = "segment#{segments.length}"
			node['segment'] = name
			nodes << node
			segment = {}
			segments << segment
			segment['name'] = name
			segment['root'] = @code
			segment['east'] = @east
			segment['west'] = @west
			segment['south'] = @south
			segment['north'] = @north
			list = []
			to_segment(-1,list,nil)
			segment['station_size'] = list.length
			segment['node_list'] = list
			puts "tree-segment name:#{name} size:#{list.length} lng:[#{@west},#{@east}] lat:[#{@south},#{@north}]"
		else
			node = {'code'=>@code}
			node['left'] = @left.code if @left
			node['right'] = @right.code if @right
			nodes << node
			if @left 
				if @depth%2 == 0
					@left.east = @lng
					@left.west = @west
					@left.south = @south
					@left.north = @north
				else
					@left.east = @east
					@left.west = @west
					@left.south = @south
					@left.north = @lat
				end
				@left.to_segment(depth,nodes,segments)
			end
			if @right
				if @depth%2 == 0
					@right.east = @east
					@right.west = @lng
					@right.south = @south
					@right.north = @north
				else
					@right.east = @east
					@right.west = @west
					@right.south = @lat
					@right.north = @north
				end
				@right.to_segment(depth,nodes,segments)
			end
		end

	end

end
		
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
