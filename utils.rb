
require 'net/http'
require 'json'
require 'set'

RESPONSE_HEADER = "\nif(typeof(xml)=='undefined') xml = {};\nxml.data = "
RESPONSE_FOOTER = "\nif(typeof(xml.onload)=='function') xml.onload(xml.data);\n"
API_PREFECTURE = "http://www.ekidata.jp/api/p/%d.json"
API_LINE = "http://www.ekidata.jp/api/l/%d.json"
LINES_OUT = "lines.json"
STATIONS_OUT = "stations.json"
STATION_OUT = "stations_%.1f-%.1f.json"
STEP = 0.5

Encoding.default_external = 'UTF-8'

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
##  このとき、
##	(3) 駅ＩＤはその駅グループcodeと同じ駅code・駅名をもつ駅があるならばそのcode、
##      存在しないならば同じ駅名をもつ駅のcodeのうち最も小さい値で代表させる
##
##  もっともこれでも駅総数は合わない廃駅を考慮しても合わない…orz
##  データファイルのエンコーディングはUTF-8を前提としているので注意
##======================================


class Line
	attr_reader :code, :name, :closed
	def initialize(code,name,closed=false)
		@code = code
		@name = name
		@closed = closed
	end
	def to_s()
		return "line{code:%d, name:%s%s}" % [@code, (@closed ? "(*)" : ""), @name]
	end
	def to_json()
		return "{\"code\":%d,\"name\":\"%s\"%s}" % [@code, @name, (@closed ? ",\"closed\":true" : "")]
	end
	def hash()
		return @code.hash
	end
	def eql?(other)
		return @code == other.code
	end
end

#"group_code"に対応したStationオブジェクトの集合
#同一"group_code"でも異なる駅名の場合は別扱いしたいので、
#その場合はフィールド値の@listが複数要素もつ
class StationGroup
	attr_reader :code, :list
	def initialize(group_code, station_code, line_code, name, lon, lat)
		@list = [Station.new(station_code, group_code, name, lon, lat, line_code)]
		@code = group_code
	end
	def add(station_code, line_code, name, lon, lat)
		@list.each do |e|
			if e.equals?(station_code, @code, name, line_code)
				return
			end
		end
		#異なる駅名の場合
		@list.push(Station.new(station_code, @code, name, lon, lat, line_code))
	end
	def to_s()
		return @list.map{|e| e.to_s }.join("\n")
	end
	def to_json()
		return @list.map{|e| e.to_json}.join(",\n")
	end
end

class Station
	attr_reader :code, :name, :lines, :longitude, :latitude, :closed
	def initialize(station_code, group_code, name, longitude, latitude, line)
		@code = station_code
		@match = station_code == group_code
		@name = name
		@longitude = longitude
		@latitude = latitude
		@lines = [line]
		@closed = group_code == nil
	end
	def initialize(data)
	  @code = data["code"].to_i
	  @name = data["station"].to_s
	  @longitude = data["lon"].to_f
	  @latitude = data["lat"].to_f
	  @lines = data["lines"]
	  @closed = data.key?("closed") && data["closed"]
	end
	def equals?(station_code, group_code, name, line_code)
		if @name == name
			#同一駅だった場合(違う路線上の駅として参照されたとき)
			if !@match
				#規則(3)参照
				if group_code == station_code
					@code = station_code
					@match = true
				else
					if station_code < @code
						@code = station_code
					end
				end
			end
			#路線の追加
			add_line(line_code)
			return true
		end
		return false
	end
	def add_line(line_code)
		@lines.push(line_code)
	end
	def to_s()
		return "Station{code:%d, name:%s%s (%f,%f), line:[%s]}" % [@code,(@closed ? "(*)" : ""), @name, @longitude, @latitude, @lines.join(",")]
	end
	def to_json()
		return "{\"code\":%d,\"name\":\"%s\",\"lon\":%f,\"lat\":%f,\"lines\":[%s]%s}" % [@code, @name, @longitude, @latitude, @lines.join(","), (@closed ? ",\"closed\":true" : "")]
	end
	def inside?(lon, lat)
		return lon <= @longitude && @longitude < lon + STEP && lat <= @latitude && @latitude < lat + STEP
	end
end

def load_prefecture(code=-1, line_set)
	if code < 0 || line_set == nil
		return false
	end
	path = API_PREFECTURE % code
	puts "Loading : " + path
	response = Net::HTTP.get(URI.parse(path))
	if response && 
			response.index(RESPONSE_HEADER) == 0 && 
			response.rindex(RESPONSE_FOOTER) == response.length - RESPONSE_FOOTER.length
		response = response.slice(RESPONSE_HEADER.length..(response.length - RESPONSE_FOOTER.length))
		root = JSON.parse(response)
		root["line"].each do |item|
			line = Line.new(item["line_cd"].to_i, item["line_name"].to_s)
			line_set.add(line)
		end
		return true
	end
	return false
end

def load_line(line_code=-1, stations)
	if line_code < 0 || stations == nil
		return false
	end
	path = API_LINE % line_code
	response = Net::HTTP.get(URI.parse(path))
	if response && 
			response.index(RESPONSE_HEADER) == 0 && 
			response.rindex(RESPONSE_FOOTER) == response.length - RESPONSE_FOOTER.length
		response = response.slice(RESPONSE_HEADER.length..(response.length - RESPONSE_FOOTER.length))
		root = JSON.parse(response)
		root["station_l"].each do |item|
			station_code = item["station_cd"].to_i
			group_code = item["station_g_cd"].to_i
			station_name = item["station_name"].to_s
			lon = item["lon"].to_f
			lat = item["lat"].to_f
			if stations.key?(group_code)
				stations[group_code].add(station_code, line_code, station_name, lon, lat)
			else
				stations[group_code] = StationGroup.new(group_code, station_code, line_code, station_name, lon, lat)
			end
		end
		return true	
	end
	return false
end

def load_all(closed_stations_file=nil)
	if closed_stations_file == nil
		puts "Error > specify closed_stations_file path."
		return
	end
	lines = Set.new()
	for i in 1..47
		if !load_prefecture(i, lines)
			puts "Warning > fail to search prefecture code:" + i.to_s
		end
	end
	groups = Hash.new()
	lines = lines.to_a
	lines.each do |line|
		puts line
		load_line(line.code, groups)
	end
	stations = []
	groups.each_value do |e|
		puts e
		stations.concat(e.list)
	end
	closed = ClosedStations.new(closed_stations_file, lines, stations)
	lines.concat(closed.closed_line)
	stations.concat(closed.closed_station)
	file = File.open(LINES_OUT, "w")
	file.puts("[")
	file.puts(lines.map{|e| e.to_json}.join(",\n"))
	file.puts("]")
	file.close
	puts "write line list. size:%d file:%s" % [lines.length, LINES_OUT] 
	
	file = File.open(STATIONS_OUT, "w")
	file.puts("[")
	file.puts(stations.map{|e| e.to_json}.join(",\n"))
	file.puts("]")
	file.close
	puts "write all station list. size:%d file:%s" % [stations.length, STATIONS_OUT] 
	while !stations.empty?
		top = stations[0]
		list = []
		lon = (top.longitude / STEP).floor * STEP
		lat = (top.latitude / STEP).floor * STEP
		stations.delete_if do |station|
			if station.inside?(lon, lat)
				list.push(station.to_json)
				next true
			end
			next false
		end
		path = STATION_OUT % [lon, lat]
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

class ClosedStations
	attr_reader:closed_line, :closed_station
	def initialize(path, lines, stations)
		@line = Hash.new()
		lines.each do |e|
			@line[e.name] = e.code
		end
		@station_set = Set.new()
		stations.each do |station|
			@station_set.add(station.code)
		end
		@closed_line = []
		@closed_station = []
		File.open(path,"r:utf-8") do |file|
			file.each_line do |line|
				if line[0] != "#"
					data = line.split("\t")
					if data.length == 4
						station_name = data[0]
						line_name = data[1]
						lon = data[3].to_f
						lat = data[2].to_f
						if @line.has_key?(line_name)
							@closed_station.push(Station.new(
								get_station_code(),
								nil,
								station_name,
								lon,lat,
								@line[line_name]
							))
						else
							new_line = Line.new(get_line_code(line_name), line_name, true)
							@closed_line.push(new_line)
							@closed_station.push(Station.new(
								get_station_code(),
								nil,
								station_name,
								lon,lat,
								new_line.code
							))
						end
					else
						puts "Warning > invalid data line : " + line
					end
				end
			end
		end
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
		while @line.value?(@line_code)
			@line_code += 1
		end
		@line[name] = @line_code
		return @line_code
	end
end


class StationCompletion
  def initialize(path)
    str = ""
    File.open(path, "r:utf-8") do |f|
      f.each_line{|l| str += l}
    end
    @station = Hash.new
    JSON.parse(str).each do |e|
      s = Station.new(e)
      if @station.key?(s.code)
        puts "code duplicated " + s.code.to_s
        return
      end
      @station[s.code] = s
    end
  end
  
  def complete(path)
    str = ""
    out = []
    File.open(path, "r:utf-8") do |f|
      f.each_line{|l| str += l}
    end
    pattern = /(.+?"code":([0-9]{7}))(?!,"station")/m
    cnt = 0
    while ( m = str.match(pattern))
      cnt += 1
      out.push(m[1])
      s = @station[m[2].to_i]
      if s == nil
        puts "station not found : " + m[2]
        return
      end
      out.push(",\"station\":\"%s\"" % s.name)
      str = m.post_match
    end
    out.push(str)
    f = File.open(path, "w")
    out.each{|e| f.print(e)}
    f.close
    puts "%d station found at %s" % [cnt, path]
  end
end