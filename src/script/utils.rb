
require 'json'
require 'set'



Encoding.default_external = 'UTF-8'

src_file = '../old/20191129/stations.json'
src_dir = '../old/20191129/details/lines'
dst_dir = './details/line'

str = ''
File.open(src_file,'r') {|f| f.each_line{|l| str += l}}
station_map = {}
JSON.parse(str).each do |s|
	station_map[s['code'].to_i] = s['station']
end
puts "station name size:#{station_map.length}"

Dir.glob("#{src_dir}/*.json").each do |n|
	str = ''
	File.open(n,'r') {|f| f.each_line{|l| str += l}}
	j = JSON.parse(str)
	str.gsub!('"line"','"name"')
	j['station_list'].each do |item|
		code = item['code']
		if name = station_map[code]
			str.gsub!("\"code\":#{code}","\"code\":#{code},\"name\":\"#{name}\"")
		else
			puts "Error > no station found. code:#{code} @ #{n}"
		end
	end
	File.open("#{dst_dir}/#{j['code']}.json","w"){|f| f.write(str)}
end
