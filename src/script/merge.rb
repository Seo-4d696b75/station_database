
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
			if line[0] != "#"
				str += line
			end
		end
	end
	return JSON.parse(str)
end

class LineItem
	attr_reader :code, :name, :closed, :extra
	attr_accessor :cnt
	def initialize(data, code=nil)
		@code = code==nil ? data["code"] : code
		@name = data.key?("line") ? data["line"] : data["name"]
		@closed = data.key?("closed") && data["closed"]
		##自前定義コードは50000台を仮定
		@extra = (@code / 10000 == 5)
	end
	def to_s()
		return "line{code:%d, name:%s%s}" % [@code, (@closed ? "(*)" : ""), @name]
	end
	def to_json()
		return "{\"code\":%d,\"line\":\"%s\"%s%s}" % [@code, @name, (@cnt ? ",\"size\":" + @cnt.to_s : ""),(@closed ? ",\"closed\":true" : "")]
	end
	def hash()
		return @code.hash
	end
	def eql?(other)
		return @code == other.code
	end
	def rename(name)
		##puts "Log > rename %s => %s" % [@name, name]
		@name = name
	end
	def set_closed(bool)
		@closed = bool
		puts "Log > closed attribute changed : " + to_s
	end
end

class StationItem
	attr_reader:code, :name, :lines, :lon, :lat, :closed, :extra
	def initialize(data, code=nil, lines=nil)
		@code = code == nil ? data["code"] : code
		@name = data.key?("station") ? data["station"] : data["name"]
		@lines = lines==nil ? data["lines"] : lines
		@lon = data["lon"].to_f
		@lat = data["lat"].to_f
		@closed = data.key?("closed") && data["closed"]
		##自前定義コードは5000000台を仮定
		@extra = (@code / 1000000 == 5)
	end
	def to_json()
		return "{\"code\":%d,\"station\":\"%s\",\"lon\":%f,\"lat\":%f,\"lines\":[%s]%s}" % [@code, @name, @lon, @lat, @lines.join(","), (@closed ? ",\"closed\":true" : "")]
	end
	def to_s()
		return "station{code:%d, name:%s, lines:[%s]%s}" % [@code, @name, @lines.join(","), (@closed ? ", closed:true" : "")]
	end
	def rename(name)
		if name == nil || name == @name
			puts "Error > invalid argument:%s ,current:%s" % [name, @name]
			return false
		else
			##puts "Log > rename station %s => %s" % [@name, name]
			@name = name
			return true
		end
	end
	def relocate(lon,lat)
		puts "Log > relocate station %s (%.6f,%.6f) => (%.6f,%.6f)" % [@name, @lon, @lat, lon, lat]
		@lon = lon
		@lat = lat
	end
	def add_line(line)
		if @lines.include?(line.code)
		    puts "Error > station already belong to line\nstation:%s\nline:%s" % [to_json, line.to_json]
			return false
		end
		if line.closed && !@closed
		    puts "Wanning > closed attributed crash\nstation:%s\nline:%s" % [to_json, line.to_json]
		end
		@lines.push(line.code)
		return true
	end
	def remove_line(code)
		if @lines.delete(code) then return true else
			puts "Error > removing line requested, but not found. line-code:%d %s" % [code, to_json]
			return false
		end
	end
	def set_closed(bool)
		@closed = bool
		puts "Log > closed attribute changed : " + to_s
	end
end

class DataParser
	def initialize(path_line="lines_raw.json", path_station="stations_raw.json")
		@line = []
		read_json(path_line).each{|e| @line.push(LineItem.new(e))}
		
		@station = []
		read_json(path_station).each{|e| @station.push(StationItem.new(e))}
		
		@merge = false
		
	end
	
	def get_station_code()
		if @station_code == nil
			@station_code = 5000000
		end
		while @station_set.include?(@station_code)
			@station_code += 1
		end
		@station_set.add(@station_code)
		return @station_code
	end
	def get_line_code(name)
		if @line_code == nil
			@line_code = 50000
		end
		while @line_set.include?(@line_code)
			@line_code += 1
		end
		@line_set.add(@line_code)
		return @line_code
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
		@line_code = nil
		@line_name_set = Set.new()
		@line.each do |e| 
			if !@line_set.add?(e.code)
				puts "Error > line code duplicated: " + e.to_s
				return
			end
			if !@line_name_set.add?(e.name)
				puts "Warning > line name duplicated : " + e.name
			end
			if e.extra
				## code != (5[0-9]+) を仮定している
				puts "Error > invalid line code(NOT extra!) : " + e.code
				return
			end
			@line_map[e.code] = e
		end
		
		#駅名の重複がＡＰＩから落としたrawデータには含まれてる　とりあえず許容する
		@station_set = Set.new()
		@station_code = nil
		@station_map = Hash.new()
		@station.each do |e|
			if !@station_set.add?(e.code)
				puts "Error > code duplicated: " + e.to_s
				return
			end
			if e.extra
				## code != (5[0-9]+) を仮定している
				puts "Error > invalid station code(NOT extra!) : " + e.code
				return
			end
			@station_map[e.code] = e
		end
		
		str = read(data_path)
		data = read_json(data_path)
		
		#駅名は以降の読み込みが終了したら改めて登録する
		lines = []
		stations = []
		data.each do |e|
			## data を駅と路線に分けます
			if e.key?("line")
				lines.push(e)
				if e.key?("add_station")
					e["add_station"].map! do |item|
						if item.kind_of?(String)
							next item
						elsif item.kind_of?(Hash) && item.key?("station") && item.key?("lon") && item.key?("lat")
							if item.key?("skip") && !!item["skip"]
								## "skip"の場合はこの路線への追加を中止する
								## ただし"code"は新規には与えないように予約しておく
								stations.push(item)
								next nil
							else
								## 新規駅の追加
								item["add"] = true
								stations.push(item)
								next item["station"].to_s
							end
						else
							puts "Error > invalid station item in a line : %s \nentry : %s" % [e["line"], item.to_s]
							return
						end
					end.compact!
				end
			elsif e.key?("station")
				stations.push(e)
			else
				puts "Error > invalid item, item must has either attribute line/station : " + e.to_s
				return
			end
		end
		
		removed_line_map = Hash.new()
		
		lines.delete_if  do |e|
			
			if e.key?("skip") && !!e["skip"]
				if !e.key?("code")
					puts "Error > node not found at skipped item : " + e.to_s
					return
				end
				code = e["code"].to_i
				##路線の指定済みコードの読み飛ばし
				##このコードは新規に割り当てないように予約
				if !@line_set.add?(code) then 
					puts "Error > line code duplicated. %d" % code 
					return
				end
				puts "Log > skip line : " + e.to_s
				next true
			end
			next false
		end
		## 路線から評価する
		lines.select do |e|
			name = e["line"]
			if e.key?("code")
				##codeを指定されたアイテムは既存エントリの編集
				##一応名前でも確認とる（人間にも編集しやすい
				code = e["code"].to_i
				if e.key?("add") && !!e["add"]
					##路線の追加(コード指定済み)
					if !@line_set.add?(code) then 
						puts "Error > line code duplicated. %d" % code 
						return
					end
					line = LineItem.new(e, nil)
					@line.push(line)
					@line_map[line.code] = line
					next false
				end
				## 路線をコード＆名称で一致を確認
				line = @line_map[code]
				if line == nil
					puts "Error > target line not found name:%s code:%d" % [name, code]
					return
				elsif line.name != name
					puts "Error > target line name mismatched %s <> %s" % [name, line.name]
					return
				end
				##エントリから消去
				if e.key?("remove") && !!e["remove"]
					if !e.key?("code")
						puts "Error > node not found at removed item : " + e.to_s
						return
					end
					code = e["code"].to_i
					if (line = @line_map.delete(code)) && @line.delete(line)
						puts "Log > remove line entry : " + line.to_json
					else
						puts "Error > fail to remove line entry. code:#{code}"
						return
					end
					name = e["line"]
					removed_line_map[name] = line
					next false
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
				next false
			else
				##追加(コード指定未了)
				##あとでコードを割り振るが、さきにコード指定済みの要素を走査しておく必要がる
				next true
				
			end
		end.each do |e|
				##追加(コード指定未了)
				name = e["line"]
				if @line_name_set.add?(name)
					if e.key?("code")
						puts "RuntimeError code set yet :" + e.to_s
						return
					end
					line = LineItem.new(e, get_line_code(name))
					@line.push(line)
					@line_map[line.code] = line
					##追加される際の新コードを保存
					if !(str = add_code(str, ("\"line\":\"%s\"" % name), line.code))
						puts "Error > fail to write line code : " + line.to_s
						return
					end
				else
					puts "Error > added line name already exist : " + name
					return 
				end
		end
		
		removed_station_set = Set.new()
		
		#以降の駅情報の更新は路線名の重複を許容できないので要確認
		@line_name_set = Set.new()
		@line_name_map = Hash.new()
		@line.each do |item|
			if @line_name_map.key?(item.name)
				puts "Error > line name dupulicated : " + item.name
				return
			end
			@line_name_map[item.name] = item
			@line_name_set.add(item.name)
		end
		
		stations.delete_if do |e|
			name = e["station"]
			##過去にコード指定済みで新たにコードを指定する場合
			if e.key?("skip") && !!e["skip"]
				if !e.key?("code") 
					puts "Error > code not found at skipped station : " + e.to_s
					return
				end
				code = e["code"].to_i
				if !@station_set.add?(code) then 
					puts "Error > station code duplicated %d" % code 
					return 
				end
				puts "Log > skip station code:#{code} at #{name}"
				next true
			end
			
				##エントリから消去
			if e.key?("remove") && e["remove"]
				if !e.key?("code") 
					puts "Error > code not found at removed station : " + e.to_s
					return
				end
				code = e["code"].to_i
				if (s = @station_map.delete(code)) && @station.delete(s)
					puts "Log > remove station entry ; " + s.to_json
				else
					puts "Error > fail to remove station entry code:#{code}"
					return
				end
				removed_station_set.add(name)
				next true
			end
			next false
		end
		stations.select do |e|
			name = e["station"]
			if e.key?("code")
				##codeを指定されたアイテムは既存エントリの編集
				##一応名前でも確認とる（人間にも編集しやすい
				code = e["code"].to_i
				if e.key?("add") && !!e["add"]
					##駅の追加(コード指定済み)
					##廃駅になってもコードはそのままで
					if !@station_set.add?(code) then 
						puts "Error > station code duplicated %d" % code 
						return 
					end
					
					s = StationItem.new(e, nil, [])
					@station_map[s.code] = s
					@station.push(s)
					next false
				end
				s = @station_map[code]
				if s == nil
					puts "Error > target station not found name:%s code:%d" % [name, code]
					return
				elsif s.name != name
					puts "Error > target station name mismatched %s <> %s" % [name, s.name]
					return
				end
				##名称の変更
				if e.key?("rename")
					rename = e["rename"]
					return if !s.rename(rename)
				end
				#位置情報の更新
				if e.key?("lon") && e.key?("lat")
					s.relocate(e["lon"].to_f, e["lat"].to_f)
				end
				#廃駅情報の更新
				if e.key?("closed")
					s.set_closed(!!e["closed"])
				end
				next false
			else
				##追加
				##駅の追加(コード指定未了)
				next true
			end
		end.each do |e|
				##駅の追加(コード指定未了)
				if e.key?("lon") && e.key?("lat")
						code = get_station_code()
						s = StationItem.new(e, code, [])
						@station_map[s.code] = s
						@station.push(s)
						if !(str = add_code(str, ("\"station\":\"%s\"" % s.name), s.code))
							puts "Error > fail to write new station code : " + s.to_s
							return
						end
				else
					puts "Error > not all the required attribute found : " + e.to_s 
					return
				end
		end
		
		
		##駅名の重複を確認（駅メモ仕様に合わせる）
		@station_name_map = Hash.new()
		@station.each do |e|
			if @station_name_map.key?(e.name)
				puts "Error > station name duplicated"
				list = []
				line = []
				puts "following stations has same name : " + e.name
				@station.select{|s| s.name == e.name}.each do |s|
					puts "\t" + s.to_s
					line.concat(s.lines)
					list.push(s)
				end
				line.uniq!
				puts "relative %d lines are here : " % line.length
				line.each{|code| puts "\t" + @line_map[code].to_json}
				puts "you must add following items in completion data to avoid name crash"
				puts list.map{|s| "{\"code\":%d,\"name\":\"%s\",\"rename\":\"%s(?)\"}" % [s.code, s.name, s.name] }.join(",\n")
				return
			end
			@station_name_map[e.name] = e
		end
		
		#路線の駅情報を更新
		#この段階で駅名の重複は許さない
		lines.each do |e|
			if e.key?("add_station") || e.key?("remove_station")
				name = e.key?("rename") ? e["rename"] : e["line"]
				line_removed = removed_line_map.key?(name)
				if line = ( line_removed ? removed_line_map[name] : @line_name_map[name])
					if e.key?("add_station") 
						if line_removed
							puts "Error > cannot add stations to removed line : " + line.to_json
							return
						end
						puts "Log > add station item to line : " + line.to_json
						e["add_station"].each do |name|
							if add_station_item(line,name)
								print name + ", "
							else return end
						end
						puts "size=%d" % e["add_station"].length
					end
					if e.key?("remove_station")
						puts "Log > remove station item from line : " + line.to_json
						e["remove_station"].each do |name|
							removed = removed_station_set.include?(name)
							if removed || add_station_item(line,name,true)
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

		puts "Log > write data with new defined code."
		file = File.open(data_path, "w")
		file.puts(str)
		file.close
		
		puts "Log > success to merge with completion data"
		@merge = true
	end

	def add_code(data,key,code)
		key.gsub!("\(", "\\\\(")
		key.gsub!("\)", "\\\\)")
		regex = Regexp.new(("^(.+)(%s.+)$" % key), option=Regexp::MULTILINE)
		##puts regex.to_s
		if m = regex.match(data)
			return ("%s\"code\":%d,\"add\":true,%s" % [m[1], code, m[2]])
		else
			return nil
		end
	end
	
	def add_station_item(line, station_name, remove=false)
		if s = @station_name_map[station_name]
			if remove
				return s.remove_line(line.code)
			else
				return s.add_line(line)
			end
		end
		puts "Error > add/remove station item requested, but station not found. name:" + station_name
		return false
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
			if s.lines.length == 0
				puts "Error > line not registered, station : " + s.to_json
				return 
			end
			s.lines.each do |code| 
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
		end
		puts "Log > all the line(size:%d) and station(size:%d) data checked." % [@line.size, @station.size]
	end
	
	def write()
		path = "lines.json"
		file = File.open(path, "w")
		file.puts("[")
		file.puts(@line.map{|e| e.to_json }.join(",\n"))
		file.puts("]")
		file.close
		puts "write line list. size:%d file:%s" % [@line.length, path] 
		path = "stations.json"
		file = File.open(path, "w")
		file.puts("[")
		file.puts(@station.map{|e| e.to_json }.join(",\n"))
		file.puts("]")
		file.close
		puts "write station list. size:%d file:%s" % [@station.length, path] 
	end
	
end

class NameGroup
	attr_reader:pattern, :list
	def initialize(pattern, name)
		@pattern = pattern
		@list = [name]
	end
	def pattern?(pattern, name)
		if pattern == @pattern
			@list.push(name) if !@list.include?(name)
			return true
		else
		return false
		end
	end
	def to_s()
		return "{pattern:%s, member:[%s]}" % [@pattern, @list.join(",")]
	end
end

def check_pattern(list)
	pick = []
	mark = "〇"
	list.each do |item|
		if item.name.match(/.+?[ヶケが].+?/)
			e = item.name.gsub(/[ヶケが]/,mark)
			find = false
			pick.each do |group|
				if group.pattern?(e, item.name) 
					find = true
					break
				end
			end
			pick.push(NameGroup.new(e, item.name)) if !find
		end
	end
	pick.select{|e| e.list.length > 1 }.each{|e| puts e.to_s}
	return pick
end

def check_close(list,top=50)
	puts "Log > check name..."
	list = list.map do |s|
		if matcher = s.name.match(/(.+?)\(.+?\)$/)
			next [matcher[1], s]
		else
			next [s.name, s]
		end
	end
	puts "Log > calc all the combination size:" + list.length.to_s
	cnt = 0
	all = (list.length**2)/2.0
	pair = []
	list.combination(2) do |a,b|
		if entry = compair(a[1],b[1],a[0],b[0]) then pair.push(entry) end
		cnt += 1
		print "\r%.2f%% complete" % (cnt*100.0/all)
	end
	puts "Log > sorting list...."
	pair.sort!{|a,b| -(a[0] <=> b[0])}
	if pair.length > top then pair = pair[0..top] end
	pair.each do |item|
		puts "score:%.2f station:%s, %s" % [item[0], item[1].to_json, item[2].to_json]
	end
end

SCORE_MATCH = 2
SCORE_MISMATCH = -1
SCORE_GAP = -2

def align(a,b)
	array = Array.new(a.length+1){|index| Array.new(b.length+1)}
	array[0][0] = 0
	for i in 1..a.length do array[i][0] = array[i-1][0] + SCORE_GAP end
	for i in 1..b.length do array[0][i] = array[0][i-1] + SCORE_GAP end
	for i in 1..a.length
		for j in 1..b.length
			v1 = array[i][j-1] + SCORE_GAP
			v2 = array[i-1][j] + SCORE_GAP
			v3 = array[i-1][j-1] + (a[i-1] == b[j-1] ? SCORE_MATCH : SCORE_MISMATCH)
			array[i][j] = [v1,v2,v3].max
		end
	end
	return array[a.length][b.length]
end

def compair(a,b,aa,bb,th=1)
	distance = 6*Math.exp(-Math.sqrt((a.lon.to_f-b.lon.to_f)**2 + (a.lat.to_f-b.lat.to_f)**2)/0.001)
	if distance > th
		name = align(aa, bb)
		return [name+distance,a,b]
	else return nil end
end

def split_block(stations)
	step = 0.5
	output_path = "stations_%.1f-%.1f.json"
	while !stations.empty?
		top = stations[0]
		list = []
		lon = (top.lon / step).floor * step
		lat = (top.lat / step).floor * step
		stations.delete_if do |s|
			if lon <= s.lon && s.lon < lon + step && lat <= s.lat && s.lat < lat + step
				list.push(s.to_json)
				next true
			end
			next false
		end
		path = output_path % [lon, lat]
		file = File.open(path, "w")
		file.puts("[")
		file.puts(list.join(",\n"))
		file.puts("]")
		file.close
		puts "write station list. size:%d file:%s" % [list.length, path] 
	end
	puts "fin"
	return true
end

