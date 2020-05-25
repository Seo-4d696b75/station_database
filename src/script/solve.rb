load('script/utils.rb')

Encoding.default_external = "utf-8"

require 'json'
require 'set'


##=====注意============================
##
##  駅の同一判定の基準に関して以下の違いがある
##  (A) ekidata.jp　の定義
##      同一改札内の駅である、または異なる改札でも乗り換え可能(改札間が約200m以内)なら同一扱い(同じ駅グループＩＤ)
##      http://www.ekidata.jp/doc/station_g.php
##  (B) 駅メモ！　の定義(推定)
##      原則として異なる駅名場合は異なる駅として扱う(京王永山・小田急永山、永田町・赤坂見附など)
##      両者とも、”同一駅名でも極端に距離が離れている乗り換え不能の場合は異なる駅扱い(早稲田前など)”は同じ
##
##      (A)基準を(B)に合わせるため、以下の判定基準を用いている
##
##  (1) 異なる駅グループcodeを持つ駅は別扱い
##  (2) 同じ駅グループcodeを持つ場合でも異なる駅名の場合は別扱い
##  ただし、基準(1)が(2)より優先される
##  
##  ekidata.jp では同一駅（乗り換え可能駅）でも登録されている路線ごとに駅コードが割り振られている
##  1駅に対し駅コードひとつを次に従って決める
##  (3) 新幹線駅である場合はその新幹線に登録されているコードを採用
##	(4) 駅グループコードと同じ駅コード・駅名をもつ駅があるならばグループコードを採用
##      存在しないならば同じ駅名をもつ駅（駅メモでの同一駅）のcodeのうち最も小さい値で代表させる
##  (5) 路線や駅の登録の違いにより一部例外もある
##
##  もっともこれでも駅総数は合わない廃駅を考慮しても合わない…orz
##  データファイルのエンコーディングはUTF-8を前提としているので注意
##======================================

class LineItem
	attr_accessor :cnt, :data
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
	def to_s()
		return JSON.dump(@data)
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
		# puts "Log > relocate station %s (%.6f,%.6f) => (%.6f,%.6f)" % [@data['name'],@data['lat'],@data['lng'],lat,lng]
		@data['lng'] = lng
		@data['lat'] = lat
	end
	def add_line(line)
		if @data['lines'].include?(line.data['code'])
		    puts "Error > station already belong to line\nstation:%s\nline:%s" % [to_s, line.to_s]
			return false
		end
		if line.data['closed'] && !@data['closed']
		    puts "Wanning > closed attributed crash. station:#{data['name']} line:#{line.data['name']}(closed)"
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



class Solver
	def init(path_line="parsed/line.json", path_station="parsed/station.json")
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
		['code','name'].each do |key|
			if !data.key?(key)
				puts "Error > imcompleted line data key:#{key} data:#{data.to_s}" 
				return nil
			end
			cp[key] = data[key]
		end
		if !!data['closed'] then cp['closed'] = true end
		if data.key?('company_code') then cp['company_code'] = data['company_code'] end
		cp['name_formal'] = ( data.key?('name_formal') ? data['name_formal'] : data['name'])
		return LineItem.new(cp)
	end

	def init_station(data)
		cp = {}
		['code','name','lat','lng'].each do |key|
			if !data.key?(key)
				puts "Error > imcompleted station data key:#{key} data:#{data.to_s}" 
				return nil
			end
			cp[key] = data[key]
		end
		if !!data['closed'] then cp['closed'] = true end
		cp['lines'] = (data.key?('lines') ? data['lines'] : [])
		if post = data['postal_code'] then cp['postal_code'] = post end
		if adr = data['address'] then cp['address'] = adr end
		if prf = data['prefecture'] then cp['prefecture'] = prf end
		if cd = data['closed_date'] then cp['closed_date'] = cd end
		if od = data['open_date'] then cp['open_date'] = od end
		return StationItem.new (cp)
	end
	
	def get_lines()
		return @line.clone
	end
	
	def get_stations()
		return @station.clone
	end
	
	def solve(data_path="solution.json",line_id_path='previous/line.json',station_id_path='previous/station.json')
	
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
				puts "Warning > line name duplicated : " + e.data['name']
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
								item["name"] = item.delete("station")
								stations.push(item)
								## 新たに駅を追加するので"rename"はない・"name"は一意（重複のない駅メモ仕様での名称）と仮定
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
		
		removed_line_set = Set.new()
		
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
					puts "Error > target line name mismatched %s <> %s" % [name, line.data['name']]
					return
				end
				##エントリから消去
				if e.key?("remove") && !!e["remove"]
					if (line = @line_map.delete(code)) && @line.delete(line)
						# puts "Log > remove line entry : " + line.to_s
					else
						puts "Error > fail to remove line entry. code:#{code}"
						return
					end
					removed_line_set.add(line.data['code'])
					removed_line_set.add(line.data['name'])
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
				if e.key?('recode')
					val = e["recode"].to_i
					if !@line_set.add?(val)
						puts "Error > try to recode, but duplicated. " + e.to_s
						return 
					end
					line.data['code'] = val.to_i
				end
				if id = e['id']
					if id.match(/[0-9a-f]{6}/)
						line.data['id'] = id
					else
						puts "Error > invalid id format #{e}"
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
				puts "Error > line name dupulicated : " + name
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
					puts "Error > target station name mismatched %s <> %s" % [name, s.data['name']]
					return
				end
				##エントリから消去
				if e.key?("remove") && e["remove"]
					if (s = @station_map.delete(code)) && @station.delete(s)
						# puts "Log > remove station entry ; " + s.to_s
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
				if e.key?("recode")
					val = e['recode'].to_i
					if !@station_set.add?(val)
						puts "Error > try to recode, but value duplicated. " + e.to_s
						return
					end
					s.data['code'] = val
				end
				if id = e['id']
					if id.match(/[0-9a-f]{6}/)
						s.data['id'] = id
					else
						puts "Error > invalid id format #{e}"
						return
					end
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
		duplicated_set = Set.new()
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
				line.each{|code| puts "\t" + @line_map[code].to_s}
				puts "you must add items in completion data to avoid name crash"
				return
			end
			if m = name.match(/(.+?)\(.+\)/)
				duplicated_set.add(m[1])
			elsif duplicated_set.include?(name)
				puts "Error > name my duplicated : #{name}(***)"
				return
			end
			@station_name_map[name] = e
			e.data["lines"].delete_if{|code| removed_line_set.include?(code)}
		end
		
		#路線の駅情報を更新
		#この段階で駅名の重複は許さない
		lines.each do |e|
			if e.key?("add_station") || e.key?("remove_station")
				name = e.key?("rename") ? e["rename"] : e["name"]
				if  removed_line_set.include?(name) || removed_line_set.include?(e['code'])
					puts "Error > removed line has invalid attr. #{e.to_s}"
					return
				end
				if line = @line_name_map[name]
					if e.key?("add_station") 
						# puts "Log > add station item to line : " + line.to_s
						e["add_station"].each do |item|
							if name = add_station_item(line,item)
								# print "#{name} "
							else return end
						end
						# puts "size=%d" % e["add_station"].length
					end
					if e.key?("remove_station")
						# puts "Log > remove station item from line : " + line.to_s
						e["remove_station"].each do |item|
							if (name = add_station_item(line,item,true)) || removed_station_set.include?(item)
								# print "#{name}(removed) "
							else
								puts "Error > remove station item requested, but station not found. #{item}" 
								return 
							end
						end
						# puts "size=%d" % e["remove_station"].length
					end
				else
					puts "Error > adding/removing station item is requested, but line has deleted yet. line:" + name
					return
				end
			end
		end

		puts "Log > success to merge with completion data"
		puts "Log > solve id for line/station item"

		# 最後にidの確認
		line_map = {}
		station_map = {}
		id_set = IDSet.new
		read_json(line_id_path).each do |e|
			return if !id_set.add?(e)
			line_map[e['id']] = e
		end
		read_json(station_id_path).each do |e|
			return if !id_set.add?(e)
			station_map[e['id']] = e
		end
		diff = File.open('diff.txt','w')
		## 明示的にidを指定する場合
		## 対応する要素が既存とする
		@line.each do |line|
			if id = line.data['id']
				if old = line_map.delete(id)
					name = line.data['name']
					code = line.data['code']
					if old['name'] != name
						# 要チェック
						puts "Warning > id:#{id} line name changed. #{old['name']} > #{name}"
					end
					if old['name'] != name || old['code'] != code
						# 変更有
						diff.puts("[line] name/code changed")
						diff.puts("\told:#{JSON.dump(old)}")
						diff.puts("\tnew:#{JSON.dump(line.data)}")
					end
				else
					puts "Error > no line found in old version id:#{id} new item:#{line.data}"
					return
				end
			end
		end
		@station.each do |s|
			if id = s.data['id']
				## 明示的にidを指定する場合
				if old = station_map.delete(id)
					## 対応する要素が既存のハズ
					name = s.data['name']
					code = s.data['code']
					if old['name'] != name
						# 要チェック
						puts "Warning > id:#{id} station name changed. #{old['name']} > #{name}"
					end
					if old['name'] != name || old['code'] != code
						# 変更有
						diff.puts("[station] name/code changed")
						diff.puts("\told:#{JSON.dump(old)}")
						diff.puts("\tnew:#{JSON.dump(s.data)}")
					end
				else
					puts "Error > no station found in old version id:#{id} new_item:#{s.data}"
					return
				end
			end
		end
		## 残りの既存の要素はどれかに対応するはず
		## 廃線・廃駅になっても消えたりはしない
		line_map.each_key do |key|
			e = line_map[key]
			name = e['name']
			code = e['code']
			if line = @line_name_map[name] || line = @line_map[code]
				# 名前優先で探索
				if id = line.data['id']
					# 別の要素に対応済み！？
					puts "Error > id crash. new:#{id} <> old:#{key} at #{e}"
					return
				end
				line.data['id'] = key
				if line.data['code'] != code
					diff.puts("[line] code changed")
					diff.puts("\told:#{JSON.dump(e)}")
					diff.puts("\tnew:#{JSON.dump(line.data)}")
				elsif line.data['name'] != name
					# 要チェック
					puts "Warning > id:#{key} line name changed. #{name} > #{line.data['name']}"

					diff.puts("[line] name changed")
					diff.puts("\told:#{JSON.dump(e)}")
					diff.puts("\tnew:#{JSON.dump(line.data)}")
				end

			else
				## 対応する要素がない
				puts "Error > no line found at new version. old:#{e}"
				return
			end
		end
		station_map.each_key do |key|
			e = station_map[key]
			name = e['name']
			code = e['code']
			if s = @station_name_map[name] || s = @station_map[code]
				# 路線名を優先に探索
				if id = s.data['id']
					# 別の要素に対応済み！？
					puts "Error > id crash. new:#{id} <> old:#{key} at #{e}"
					return
				end
				s.data['id'] = key
				if s.data['code'] != code
					diff.puts("[station] code changed")
					diff.puts("\told:#{JSON.dump(e)}")
					diff.puts("\tnew:#{JSON.dump(s.data)}")
				elsif s.data['name'] != name 
					# 要チェック
					puts "Warning > id:#{key} station name changed. #{name} > #{s.data['name']}"
				
					diff.puts("[station] name changed")
					diff.puts("\told:#{JSON.dump(e)}")
					diff.puts("\tnew:#{JSON.dump(s.data)}")
				end
			else
				## 対応する要素がない
				puts "Error > no line found at new version. old:#{e}"
				return
			end
		end
		## 既存の要素に対応するものがないなら新規追加した要素
		@line.select{|line| !line.data.key?('id')}.each do |line|
			line.data['id'] = id_set.get
			diff.puts("[line] add")
			diff.puts("\tnew:#{JSON.dump(line.data)}")
		end
		@station.select{|s| !s.data.key?('id')}.each do |s|
			s.data['id'] = id_set.get
			diff.puts("[station] add")
			diff.puts("\tnew:#{JSON.dump(s.data)}")
		end
			
		diff.close

		## sort
		@line.each{|e| e.data = sort_hash(e.data)}
		@station.each{|e| e.data = sort_hash(e.data)}

		puts "Success to solve station and line data."
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
				return (s.remove_line(line.data['code']) ? s.data['name'] : nil)
			else
				return (s.add_line(line) ? s.data['name'] : nil)
			end
		end
		return nil
	end
	
	def check(data_path="check/line.csv")
		
		if !@merge
			puts "Error > merge with completion data in ahead"
			return
		end
		@merge = false
		
		##路線名＆駅数の一覧表
		comparison = []
		File.open(data_path, "r:utf-8") do |file|
			file.each_line do |line|
				if matcher = line.match(/^(.+?),([0-9]+)$/)
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
				puts "Error > line not registered, station : " + s.to_s
				return 
			end
			s.data['lines'].each do |code| 
				if line = @line_map[code] then line.cnt += 1 else
					puts "Error > requested line with code not found. code:%d station:%s" % [code, s.to_s]
					return
				end
			end
		end
		comparison.each do |e|
			line = @line_name_map[e[0]]
			if e[1] != line.cnt
				puts "Error > station list size mismatch(expected:%d, actual:%d) on line : \n%s" % [e[1], line.cnt, line.to_s]
				@station.each do |s|
					if s.data['lines'].include?(line.data['code'])
						puts s.to_s
					end
				end
				return
			end
			line.data['station_size'] = line.cnt
		end
		puts "Log > all the line(size:%d) and station(size:%d) data checked." % [@line.size, @station.size]
	end
	
	def write()
		path = "solved/line.json"
		File.open(path, "w") do |f|
			f.write(format_json(@line.map{|e| e.data}, flat:true))
		end
		puts "write line list. size:%d file:%s" % [@line.length, path] 
		path = "solved/station.json"
		File.open(path, "w") do |f|
			f.write(format_json(@station.map{|e| e.data}, flat:true))
		end
		puts "write station list. size:%d file:%s" % [@station.length, path] 
	end
	
end
