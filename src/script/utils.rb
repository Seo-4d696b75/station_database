
require 'json'
require 'set'
require 'securerandom'

Encoding.default_external = 'UTF-8'



def read(path)
	str = ""
	File.open(path, "r:utf-8") do |file|
		file.each_line do |line|
			str << line
		end
	end
	return str
end

def read_json(path)
	str = ""
	File.open(path, "r:utf-8") do |file|
		file.each_line do |line|
			str << line
		end
	end
	return JSON.parse(str)
end

def flatten_data(obj,list)
	if children = obj["data"]
		children.each{|child| flatten_data(child,list)}
	else
		list << obj
	end
end

def read_data(path)
	root = read_json(path)
	list = []
	flatten_data(root,list)
	return list
end


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

def format_json(data,flat_key:[],flat_array:[],flat:false,depth:0)
	if data.kind_of?(String)
		return "\"#{data.to_s}\""
	elsif data.kind_of?(Numeric) || data == true || data == false
		return data.to_s
	elsif data.kind_of?(Hash)
		return JSON.dump(data) if flat
		str = "{\n"
		str << ("  " * (depth+1))
		str << data.to_a.map do |e|
			key,value = e
			if value.kind_of?(Array)
				if flat_key.include?(key)
					next "\"#{key}\":#{JSON.dump(value)}"
				else
					value = format_json(
						value,
						flat_key:flat_key,
						flat_array:flat_array,
						flat:flat_array.include?(key),
						depth:(depth+1)
					)
					next "\"#{key}\":#{value}"
				end
			end
			value = format_json(
				value,
				flat_key:flat_key,
				flat_array:flat_array,
				flat:flat_key.include?(key),
				depth:(depth+1)
			)
			"\"#{key}\":#{value}"
		end.join(",\n" + ("  " * (depth+1)))
		str << "\n"
		str << ("  " * depth)
		str << "}"
		return str
	elsif data.kind_of?(Array)
		str = "[\n"
		str << ("  " * (depth+1))
		str << data.map do |value|
			format_json(
				value,
				flat_key:flat_key,
				flat_array:flat_array,
				flat:flat,
				depth:(depth+1)
			)
		end.join(",\n" + ("  " * (depth+1)))
		str << "\n"
		str << ("  " * depth)
		str << "]"
		return str
	else
		raise "invalid json data: " + data.to_s
	end
end


def sort_hash(data)
	keys = [
		'code',
		'left',
		'right',
		'segment',
		'id',
		'name',
		'name_kana',
		'name_formal',
		'station_size',
		'company_code',
		'closed',
		'lat',
		'lng',
		'prefecture',
		'lines',
		'color',
		'symbol',
		'station_list',
		'north',
		'south',
		'east',
		'west',
		'point_list',
		'attr',
		'postal_code',
		'address',
		'next',
		'voronoi'
	]
	data.sort do |a,b|
		a = keys.find_index(a[0])
		b = keys.find_index(b[0])
		if a
			next b ? a <=> b : -1
		else
			next b ? 1 : 0
		end
	end.to_h
end
