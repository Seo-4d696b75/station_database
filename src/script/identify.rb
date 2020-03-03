
require 'json'
require 'set'
require 'securerandom'
Encoding.default_external = 'UTF-8'

# 駅・路線に固有かつ定常な値を決定する

station_src = '../old/20191129/stations.json'
station_dst = './station.json'
line_src = '../old/20191129/lines.json'
line_dst = './line.json'


class IDSet

	def initialize
		@id = Set.new
	end

	def add?(e)
		if id = e['id']
			if id.match(/[0-9a-f]{6}/)
				if @id.add?(id)
					return true
				else
					puts "Error > id:#{id} duplicated  item:#{e}"
				end
			else
				puts "Error > invalid id item:#{e}"
			end
		else
			puts "Error > no id item:#{e}"
		end
		return false
	end

	def get
		while true
			id = SecureRandom.hex(3)
			if @id.add?(id)
				return id
			end
		end
	end
end

set = IDSet.new


def load_list(file_name, map, set)
	str = ''
	File.open(file_name, 'r'){|f| f.each_line{|l| str += l}}
	JSON.parse(str).each do |e|
		exit(0) if !set.add?(e)
		name = e['name']
		if map.key?(name)
			puts "Error > name duplicated #{e}"
			exit(0)
		end
		map[name] = e
	end		
	
end

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
