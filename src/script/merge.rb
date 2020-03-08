
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
	stations << s
end
puts "size:#{lines.length}"





def set_details(line,details,polyline,station_map,dir_dst)
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
	details['code'] = line['code']
	details['station_list'].map! do |e|
		s = station_map[e['name']]
		if !s
			puts "Error > station not found #{e['name']} at station_list #{JSON.dump(line)}"
			exit(0)
		end
		e['code'] = s['code']
		next sort_hash(e)
	end
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
	set_details(line,details,polyline,station_map,dir_dst)
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

tree['node_list'].each do |e|
	code = e['code']
	s = station_map[code]
	if !s
		puts "Error > station not found. code:#{code}"
		exit(0)
	end
	s['voronoi'] = e.delete('voronoi')
	s['next'] = e.delete('next')
	end
puts "write station list to file."
File.open("#{dir_dst}/station.json","w") do |f|
	f.write(format_json(stations.map{|e| sort_hash(e)},flat:true))
end
puts "write Kd-tree to file."
File.open("#{dir_dst}/tree.json","w") do |f|
	f.write(format_json(tree,flat_array:['node_list']))
end

# build Kd-tree
class Node
	attr_reader :code, :depth, :left, :right
	def initialize(data,depth,map)
		@code = data['code']
		@depth = depth
		@left = data.key?('left') ? Node.new(map[data['left']],depth+1,map) : nil
		@right = data.key?('right') ? Node.new(map[data['right']],depth+1,map) : nil
	end
end
		
# root = Node.new(tree_map[tree['root']],0,tree_map)
tree['node_list'].each do |e|
	e.delete('name')
	e.delete('lat')
	e.delete('lng')
end

# one-file
puts "write all the data to one file."
data = {}
data['version'] = version
data['stations'] = stations.map{|e| sort_hash(e)}
data['lines'] = lines_details.map{|e| sort_hash(e)}
data['tree'] = tree
File.open("#{dir_dst}/data.json","w") do |f|
	f.write(format_json(data,flat_array:['stations','station_list','polyline_list','node_list']))
end

puts 'All done.'
