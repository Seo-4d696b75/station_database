
Encoding.default_external = "utf-8"

require 'json'
require 'set'


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

class LineItem
	attr_accessor :cnt :data
	def initialize(data)
		@data = data
	end
	def to_s()
		return JSON.dump(@data)
	end
	def hash()
		return @data['code'].hash
	end
	def eql?(other)
		return @data['code'] == other.code['code']
	end
	def rename(name)
		##puts "Log > rename %s => %s" % [@name, name]
		@data['name'] = name
	end
	def set_closed(bool)
		if !bool
			@data.delete('closed')
		else
			@data['closed'] = true
		end
	end
end

class StationItem
	attr_accessor :data
	def initialize(data)
		@data = data
		
	end
	def to_json()
		return "{\"code\":%d,\"station\":\"%s\",\"lon\":%f,\"lat\":%f,\"lines\":[%s]%s}" % [@code, @name, @lon, @lat, @lines.join(","), (@closed ? ",\"closed\":true" : "")]
	end
	def to_s()
		return "station{code:%d, name:%s, lines:[%s]%s}" % [@code, @name, @lines.join(","), (@closed ? ", closed:true" : "")]
	end
	def rename(name)
		if name == nil || name == @data['name']
			puts "Error > invalid argument:%s ,current:%s" % [name, @data['name']]
			return false
		else
			##puts "Log > rename station %s => %s" % [@name, name]
			@data['name'] = name
			return true
		end
	end
	def relocate(lng,lat)
		puts "Log > relocate station %s (%.6f,%.6f) => (%.6f,%.6f)" % [@data['name'],@data['lat'],@data['lng'],lat,lng]
		@data['lng'] = lng
		@data['lat'] = lat
	end
	def add_line(line)
		if @data['lines'].include?(line.data['code'])
		    puts "Error > station already belong to line\nstation:%s\nline:%s" % [to_s, line.to_s]
			return false
		end
		if line.data['closed'] && !@data['closed']
		    puts "Wanning > closed attributed crash\nstation:%s\nline:%s" % [to_s, line.to_s]
		end
		@data['lines'] << line.data['code']
		return true
	end
	def remove_line(code)
		if @data['lines'].delete(code) then return true else
			puts "Error > removing line requested, but not found. line-code:%d %s" % [code, to_s]
			return false
		end
	end
	def set_closed(bool)
		if !bool
			@data.delete('closed')
		else
			@data['closed'] = true
		end
		puts "Log > closed attribute changed : " + to_s
	end
end

class DataParser
	def init(path_line="mid/line.json", path_station="mid/station.json")
		@line = []
		read_json(path_line).each do |e|
			if item =  init_line(e)
				@line.push(item)
			else
				return false
			end
		end
		
		@station = []
		read_json(path_station).each do |e| 
			if item = init_station(e)
				@station.push(item)
			else
				return false
			end
		end
		
		@merge = false
		return true
	end
	
	def init_line(data)
		cp = {}
		['code','company_code','name','name_formal','lng','lat','zoom'].each do |key|
			if !data.key?(key)
				puts "Error > imcompleted line data key:#{key} data:#{data.to_s}" 
				return nil
			end
			cp[key] = data[key]
		end
		if !!data['closed'] then cp['closed'] = true end
		return LineItem.new(cp)
	end

	def init_station(data)
		cp = {}
		['code','prefecture','name','post_number','address','lat','lng'].each do |key|
			if !data.key?(key)
				puts "Error > imcompleted station data key:#{key} data:#{data.to_s}" 
				return nil
			end
			cp[key] = data[key]
		end
		if !!data['closed'] then cp['closed'] = true end
		cp['lines'] = (data.key?('lines') ? data['lines'] : [])
		return StationItem.new (cp)
	end
	
	def get_lines()
		return @line.clone
	end
	
	def get_stations()
		return @station.clone
	end
	
	def merge(data_path="merge.json")
	
		##deep copy of array
		if @_station && @_line
			@station = []
			@_station.each{|e| @station.push(Marshal.load(Marshal.dump(e)))}
			@line = []
			@_line.each{|e| @line.push(Marshal.load(Marshal.dump(e)))}
		else
			@_station = []
			@station.each{|e| @_station.push(Marshal.load(Marshal.dump(e)))}
			@_line = []
			@line.each{|e| @_line.push(Marshal.load(Marshal.dump(e)))}
		end
		@line = get_lines()
		@station = get_stations()

		
		#路線名も重複があるかも
		#がこれ以降の編集時は重複を許さない
		@line_map = Hash.new()
		@line_set = Set.new()
		@line_name_set = Set.new()
		@line.each do |e| 
			if !@line_set.add?(e.data['code'])
				puts "Error > line code duplicated: " + e.to_s
				return
			end
			if !@line_name_set.add?(e.data['name'])
				puts "Warning > line name duplicated : " + e.name
			end
			@line_map[e.data['code']] = e
		end
		
		#駅名の重複がＡＰＩから落としたrawデータには含まれてる　
		#とりあえず許容する
		@station_set = Set.new()
		@station_map = Hash.new()
		@station.each do |e|
			if !@station_set.add?(e.data['code'])
				puts "Error > code duplicated: " + e.to_s
				return
			end
			@station_map[e.data['code']] = e
		end
		
		# merge.json
		# str = read(data_path)
		# merge.json => JSONArray
		data = read_data(data_path)
		
		#駅名は以降の読み込みが終了したら改めて登録する
		lines = []
		stations = []
		data.each do |e|
			## data を駅と路線に分けます
			if e.key?("line")
				e['name'] = e.delete('line')
				lines.push(e)
				if e.key?("add_station")
					e["add_station"].map! do |item|
						if item.kind_of?(String) || item.kind_of?(Integer)
							next item
						elsif item.kind_of?(Hash) && item.key?("station")
								## 新規駅の追加
								item["add"] = true
								stations.push(item)
								next item["name"].to_s
						else
							puts "Error > invalid station item in a line : %s \nentry : %s" % [e["line"], item.to_s]
							return
						end
					end.compact!
				end
			elsif e.key?("station")
				e['name'] = e.delete('station')
				stations.push(e)
			else
				puts "Error > invalid item, item must has either attribute line/station : " + e.to_s
				return
			end
		end
		
		removed_line_map = Hash.new()
		
		## 路線から評価する
		lines.each do |e|
			name = e["name"]
			if e.key?("code")
				##一応名前でも確認とる（人間にも編集しやすい
				code = e["code"].to_i
				if e.key?("add") && !!e["add"]
					##路線の追加
					if !@line_set.add?(code) then 
						puts "Error > line code duplicated. %d" % code 
						return
					end
					if line = init_line(e)
						@line.push(line)
						@line_map[code] = line
					else return end
					next
				end
				## 路線をコード＆名称で一致を確認
				line = @line_map[code]
				if line == nil
					puts "Error > target line not found name:%s code:%d" % [name, code]
					return
				elsif line.data['name'] != name
					puts "Error > target line name mismatched %s <> %s" % [name, line.name]
					return
				end
				##エントリから消去
				if e.key?("remove") && !!e["remove"]
					if (line = @line_map.delete(code)) && @line.delete(line)
						puts "Log > remove line entry : " + line.to_s
					else
						puts "Error > fail to remove line entry. code:#{code}"
						return
					end
					removed_line_map[name] = line
					next
				end
				##名称の変更
				if e.key?("rename")
					rename = e["rename"]
					if @line_name_set.add?(rename)
						line.rename(rename)
						##更新する以上昔の名前はもう出てこないよね？
						##@line_name_set.delete(name)
					else
						puts "Error > line new name has already existed : " + rename
						return
					end
				end
				##廃線情報の更新
				if e.key?("closed")
					line.set_closed(!!e["closed"])
				end
			else
				puts "Error >  code not found: " + e.to_s
				return
			end
		end
		
		removed_station_set = Set.new()
		
		#以降の駅情報の更新は路線名の重複を許容できないので要確認
		@line_name_set = Set.new()
		@line_name_map = Hash.new()
		@line.each do |item|
			name = item.data['name']
			if @line_name_map.key?(name)
				puts "Error > line name dupulicated : " + item.name
				return
			end
			@line_name_map[name] = item
			@line_name_set.add(name)
		end
		
		# 次に駅を評価する
		stations.each do |e|
			name = e["name"]

			if e.key?("code")
				##codeを指定されたアイテムは既存エントリの編集
				##一応名前でも確認とる（人間にも編集しやすい
				code = e["code"].to_i
				if e.key?("add") && !!e["add"]
					##駅の追加
					##廃駅になってもコードはそのままで
					if !@station_set.add?(code) then 
						puts "Error > station code duplicated %d" % code 
						return
					end
					
					if s = init_station(e)
						@station_map[code] = s
						@station.push(s)
					else return end
					next
				end
				s = @station_map[code]
				if s == nil
					puts "Error > target station not found name:%s code:%d" % [name, code]
					return
				elsif s.data['name'] != name
					puts "Error > target station name mismatched %s <> %s" % [name, s.name]
					return
				end
				##エントリから消去
				if e.key?("remove") && e["remove"]
					if (s = @station_map.delete(code)) && @station.delete(s)
						puts "Log > remove station entry ; " + s.to_json
					else
						puts "Error > fail to remove station entry code:#{code}"
						return
					end
					removed_station_set.add(name)
					removed_station_set.add(code)
					next
				end
				##名称の変更
				if e.key?("rename")
					rename = e["rename"]
					return if !s.rename(rename)
				end
				#位置情報の更新
				if e.key?("lng") && e.key?("lat")
					s.relocate(e["lng"].to_f, e["lat"].to_f)
				end
				#廃駅情報の更新
				if e.key?("closed")
					s.set_closed(!!e["closed"])
				end
				
			else
				puts "line has no code: " + e.to_s
				return
			end
		end
		
		
		##駅名の重複を確認（駅メモ仕様に合わせる）
		@station_name_map = Hash.new()
		@station.each do |e|
			name = e.data['name']
			if @station_name_map.key?(name)
				puts "Error > station name duplicated"
				list = []
				line = []
				puts "following stations has same name : " + name
				@station.select{|s| s.data['name'] == name}.each do |s|
					puts "\t" + s.to_s
					line.concat(s.data['lines'])
					list.push(s)
				end
				line.uniq!
				puts "relative %d lines are here : " % line.length
				line.each{|code| puts "\t" + @line_map[code].to_json}
				puts "you must add items in completion data to avoid name crash"
				return
			end
			@station_name_map[name] = e
		end
		
		#路線の駅情報を更新
		#この段階で駅名の重複は許さない
		lines.each do |e|
			if e.key?("add_station") || e.key?("remove_station")
				name = e.key?("rename") ? e["rename"] : e["name"]
				line_removed = removed_line_map.key?(name)
				if line = ( line_removed ? removed_line_map[name] : @line_name_map[name])
					if e.key?("add_station") 
						if line_removed
							puts "Error > cannot add stations to removed line : " + line.to_json
							return
						end
						puts "Log > add station item to line : " + line.to_s
						e["add_station"].each do |item|
							if name = add_station_item(line,item)
								print "#{name} "
							else return end
						end
						puts "size=%d" % e["add_station"].length
					end
					if e.key?("remove_station")
						puts "Log > remove station item from line : " + line.to_json
						e["remove_station"].each do |item|
							removed = removed_station_set.include?(item)
							if removed || (name = add_station_item(line,item,true))
								print name
								print "(removed)" if removed
								print ", "
							else return end
						end
						puts "size=%d" % e["remove_station"].length
					end
				else
					puts "Error > adding/removing station item is requested, but line has deleted yet. line:" + name
					return
				end
			end
		end

		
		puts "Log > success to merge with completion data"
		@merge = true
	end

	def add_station_item(line, station, remove=false)
		s = nil
		if station.kind_of?(String)
			s = @station_name_map[station]
		elsif station.kind_of?(Integer)
			s = @station_map[station]
		end
		if s
			if remove
				return (s.remove_line(line['code']) ? s.data['name'] : nil)
			else
				return (s.add_line(line) ? s.data['name'] : nil)
			end
		end
		puts "Error > add/remove station item requested, but station not found. id:#{station}"
		return nil
	end
	
	def check(data_path="check_list.txt")
		
		if !@merge
			puts "Error > merge with completion data in ahead"
			return
		end
		@merge = false
		
		##路線名＆駅数の一覧表
		comparison = []
		File.open(data_path, "r:utf-8") do |file|
			file.each_line do |line|
				if matcher = line.match(/^(.+?)\s*([0-9]+)$/)
					comparison.push([matcher[1],matcher[2].to_i])
				else
					puts "Error > can not resolve line : " + line
					return
				end
			end
		end
		##対応する路線の存在を確認
		comparison.each do |e|
			if !@line_name_set.delete?(e[0])
				puts "Error > line not found : %s(size:%d)" % [e[0], e[1]]
				puts "  you must add following entry to completion data."
				puts "{\"line\":\"%s\",\"add_station\":[\n{\"station\":\"??\",\"lat\":,\"lon\":}\n]}" % e[0]
				puts "  or rename line to this name."
				puts "{\"code\":,\"line\":\"\",\"rename\":\"%s\"}" % e[0]
				return
			end
		end
		##取り残されがないか確認
		if @line_name_set.size > 0 
			@line_name_set.each do |e|
				puts "Error > corresponding line not found :" + @line_name_map[e].to_s
			end 
			return
		end
		##路線の駅数を確認
		@line.each{|e| e.cnt = 0}
		@station.each do |s|
			if s.data['lines'].length == 0
				puts "Error > line not registered, station : " + s.to_json
				return 
			end
			s.data['lines'].each do |code| 
				if line = @line_map[code] then line.cnt += 1 else
					puts "Error > requested line with code not found. code:%d station:%s" % [code, s.to_json]
					return
				end
			end
		end
		comparison.each do |e|
			line = @line_name_map[e[0]]
			if e[1] != line.cnt
				puts "Error > station list size mismatch(expected:%d, actual:%d) on line : \n%s" % [e[1], line.cnt, line.to_json]
				return
			end
			line.data['size'] = line.cnt
		end
		puts "Log > all the line(size:%d) and station(size:%d) data checked." % [@line.size, @station.size]
	end
	
	def write()
		path = "lines.json"
		file = File.open(path, "w")
		file.puts("[")
		file.puts(@line.map{|e| e.to_s }.join(",\n"))
		file.puts("]")
		file.close
		puts "write line list. size:%d file:%s" % [@line.length, path] 
		path = "stations.json"
		file = File.open(path, "w")
		file.puts("[")
		file.puts(@station.map{|e| e.to_s }.join(",\n"))
		file.puts("]")
		file.close
		puts "write station list. size:%d file:%s" % [@station.length, path] 
	end
	
end
