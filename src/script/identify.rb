
require 'json'
require 'set'
require 'securerandom'
Encoding.default_external = 'UTF-8'

# 駅・路線に固有かつ定常な値を決定する

station_src = '../old/20191129/stations.json'
station_dst = './station.json'
line_src = '../old/20191129/lines.json'
line_dst = './line.json'

load('script/utils.rb')

set = IDSet.new



str = ''
File.open(line_src,'r'){|f| f.each_line{|l| str += l}}
lines = []
JSON.parse(str).each do |e|
	id = set.get
	data = {}
	data['id'] = id
	e.each_key{|key| data[key] = e[key]}
	lines << data
end

str = ''

File.open(station_src,'r'){|f| f.each_line{|l| str += l}}
stations = []
JSON.parse(str).each do |e|
	id = set.get
	data = {}
	data['id'] = id
	e.each_key{|key| data[key] = e[key]}
	stations << data
end

File.open(line_dst, 'w') do |f|
	f.puts('[')
	f.puts(lines.map{|e| JSON.dump(e)}.join(",\n"))
	f.puts(']')
end

File.open(station_dst, 'w') do |f|
	f.puts('[')
	f.puts(stations.map{|e| JSON.dump(e)}.join(",\n"))
	f.puts(']')
end
