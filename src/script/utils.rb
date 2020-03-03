
require 'json'
require 'set'
require 'securerandom'

Encoding.default_external = 'UTF-8'



def read(path)
	str = ""
	File.open(path, "r:utf-8") do |file|
		file.each_line do |line|
			str += line
		end
	end
	return str
end

def read_json(path)
	str = ""
	File.open(path, "r:utf-8") do |file|
		file.each_line do |line|
			str += line
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


def sort_hash(data)
	keys = [
		'id',
		'code',
		'name',
		'name_kana',
		'name_formal',
		'size',
		'company_code',
		'lat',
		'lng',
		'prefecture',
		'lines',
		'postal_code',
		'address'
	]
	data.sort do |a,b|
		a = keys.find_index(a)
		b = keys.file_index(b)
		if a
			next b ? a <=> b : -1
		else
			next b ? 1 : 0
		end
	end
end
