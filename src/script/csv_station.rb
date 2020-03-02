
require 'json'
require 'set'
require 'nkf'
Encoding.default_external = 'UTF-8'

file_dir = ARGV[0]

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
##	(3) 駅codeはその駅グループcodeと同じ駅code・駅名をもつ駅があるならばそのcode、
##      存在しないならば同じ駅名をもつ駅のcodeのうち最も小さい値で代表させる
##
##  データファイルのエンコーディングはUTF-8を前提としているので注意
##======================================

## カタカナ＞ひらがな　の変換を定義
# https://qiita.com/y_minowa/items/c204992e4665a8687d4a
class String
	def to_hiragana()
		return NKF.nkf("-w --hiragana", self)
	end
end


#"group_code"に対応したStationオブジェクトの集合
#同一"group_code"でも異なる駅名の場合は別扱いしたいので、
#その場合はフィールド値の@listが複数要素もつ
class StationGroup
	attr_reader :code, :list
	def initialize(group_code, s)
		@list = [Station.new(group_code,s)]
		@code = group_code
	end
	def add(s)
		@list.each do |e|
			if e.is_same?(@code, s)
				return
			end
		end
		#異なる駅名の場合
		@list.push(Station.new(@code, s))
	end
end


class Station
	attr_reader :data
	def initialize(group_code,data)
		@data = data
		@match = (group_code == data['code'])
		@data['lines'] = [data.delete('line_code')]
	end
	def is_same?(group_code, s)
		if @data['name'] == s['name']
			#同一駅だった場合(違う路線上の駅として参照されたとき)
			if !@match
				#規則(3)参照
				if group_code == s['code']
					@data['code'] = s['code']
					@match = true
				else
					if s['code'] < @data['code']
						@data['code'] = s['code']
					end
				end
			end
			#路線の追加
			@data['lines'] << s['line_code']
			return true
		end
		return false
	end
	def to_s()
		JSON.dump(@data)
	end
end


field_list = [
	'station_cd',
	'station_g_cd',
	'station_name',
	'station_name_k',
	'station_name_r',
	'line_cd',
	'pref_cd',
	'post',
	'add',
	'lon',
	'lat',
	'open_ymd',
	'close_ymd',
	'e_status',
	'e_sort'
]


def add_item(cells, groups)
	status = cells[13].to_i
	# 運用前はスキップ
	if status == 1 then return end
	group_code = cells[1].to_i
	# 無料データでは欠損のあるフィールド（color_*, type）は無視
	# 路線名は変更が多いのでかなは無視
	item = {
		'code'=>cells[0].to_i,
		'name'=>cells[2],
		'line_code'=>cells[5].to_i,
		'prefecture'=>cells[6].to_i,
		'postal_code'=>cells[7],
		'address'=>cells[8],
		'lng'=>cells[9].to_f,
		'lat'=>cells[10].to_f
	}
	# 廃止 status == 2
	if status == 2
		item['closed'] = true
		if cells[12] == ''
			# puts "station #{item['code']} #{item['name']} is closed, but no close-date"
		else
			item['close_date'] = cells[12]
			puts "station #{item['code']} #{item['name']} was closed on #{cells[12]}"
		end
		if cells[11] != ''
			item['open_date'] = cells[11]
		end
	end
	if groups.key?(group_code)
		groups[group_code].add(item)
	else
		groups[group_code] = StationGroup.new(group_code, item)
	end
end

groups = {}

puts "read csv:#{ARGV[0]}"
File.open(ARGV[0], "r:utf-8") do |f|
	cnt = -1
	f.each_line do |l|
		cnt += 1
		if cnt == 0
			# check fileds
			header = l.chomp.split(',')
			if header.length != field_list.length
				puts "fields cnt mismatch."
				exit(0)
			end
			header.each_with_index do |f,i|
				if f != field_list[i]
					puts "field name mismatch #{f} <> #{field_list[i]}"
					exit(0)
				end
			end
			puts "read headers. field size:#{header.length}"
		else
			add_item( l.chomp.split(','), groups)
		end
	end
	puts "csv data size:#{cnt}"
end

stations = []
groups.each_value{|e| stations.concat(e.list)}
puts "station size:#{stations.length}"


File.open(ARGV[1],"w:utf-8") do |f|
	str = "[\n  "
	str += stations.map{|e| JSON.dump(e.data)}.join(",\n  ")
	str += "\n]"
	f.write(str)
end
puts "write into file:#{ARGV[1]}"