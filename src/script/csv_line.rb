
require 'json'
require 'set'
require 'nkf'
Encoding.default_external = 'UTF-8'

## @date 2020/02
## @author Seo-4d696b75
## 鉄道路線のCSVからJSON形式の中間ファイルに変換する
## 詳しい形式 https://ekidata.jp/doc/line.php


## カタカナ＞ひらがな　の変換を定義
# https://qiita.com/y_minowa/items/c204992e4665a8687d4a
class String

	def to_hiragana()
		return NKF.nkf("-w --hiragana", self)
	end
end


field_list = [
	'line_cd',
	'company_cd',
	'line_name',
	'line_name_k',
	'line_name_h',
	'line_color_c',
	'line_color_t',
	'line_type',
	'lon',
	'lat',
	'zoom',
	'e_status',
	'e_sort'
]

dst = []

def add_item(cells, list)
	status = cells[11].to_i
	# 運用前はスキップ
	if status == 1 then return end
	# 無料データでは欠損のあるフィールド（color_*, type）は無視
	# 路線名は変更が多いのでかなは無視
	item = {
		'code':cells[0].to_i,
		'company_code':cells[1].to_i,
		'name':cells[2],
		'name_formal':cells[4],
		'lng':cells[8].to_f.round(6),
		'lat':cells[9].to_f.round(6),
		'zoom':cells[10].to_i
	}
	# 廃止 status == 2
	if status == 2
		item['closed'] = true
	end
	list << item
end

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
			puts "read headers. filed size:#{header.length}"
		else
			add_item( l.chomp.split(','), dst)
		end
	end
	puts "data size:#{cnt}"
end

File.open(ARGV[1],"w:utf-8") do |f|
	str = "[\n  "
	str += dst.map{|e| JSON.dump(e)}.join(",\n  ")
	str += "\n]"
	f.write(str)
end
puts "write into file:#{ARGV[1]}"
