
require 'json'
require 'set'
require 'securerandom'
Encoding.default_external = 'UTF-8'

# 駅・路線に固有かつ定常な値を決定する

src_station = 'solved/station.json'
src_line = 'solved/staton.json'
dst_station = 'identified/station.json'
dst_line = 'identified/line.json'


class IDSet

	def initialize
		@id = Set.new
	end

	def add?(e)
		if id = e['id']
			if id.match(/[0-9a-f]{8}/)
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
			id = SecureRandom.hex(4)
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

stations_old = {}
if File.exits?(file_station)
	load_list(file_station, stations_old, set)
end

lines_old = {}
if File.exits?(file_line)
	load_list(file_line, lines_old, set)
end
