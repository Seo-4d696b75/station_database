require 'net/http'
require 'json'
require 'set'

RESPONSE_HEADER = "\nif(typeof(xml)=='undefined') xml = {};\nxml.data = "
RESPONSE_FOOTER = "\nif(typeof(xml.onload)=='function') xml.onload(xml.data);\n"
API_PREFECTURE = "http://www.ekidata.jp/api/p/%d.json"
API_LINE = "http://www.ekidata.jp/api/l/%d.json"
LINES_OUT = "lines_raw.json"
STATIONS_OUT = "stations_raw.json"


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

def load_all()
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
		stations.concat(e.list)
	end
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
	puts "fin"
	return true
end

puts "get all the data from ekidata.jp"
load_all()