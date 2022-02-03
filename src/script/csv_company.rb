load("script/utils.rb")
require "json"
require "set"
require "nkf"
Encoding.default_external = "UTF-8"

## @date 2020/02
## @author Seo-4d696b75
## 鉄道事業者のCSVからJSON形式の中間ファイルに変換する
## 詳しい形式 https://ekidata.jp/doc/company.php

## カタカナ＞ひらがな　の変換を定義
# https://qiita.com/y_minowa/items/c204992e4665a8687d4a
class String
  def to_hiragana()
    return NKF.nkf("-w --hiragana", self)
  end
end

field_list = [
  "company_cd",
  "rr_cd",
  "company_name",
  "company_name_k",
  "company_name_h",
  "company_name_r",
  "company_url",
  "company_type",
  "e_status",
  "e_sort",
]

dst = []

def add_item(cells, list)
  status = cells[8].to_i
  # 運用前はスキップ
  if status == 1 then return end
  item = {
    'code': cells[0].to_i,
    'rail_code': cells[1].to_i,
    'name': cells[2],
    'name_kana': cells[3].to_hiragana,
    'name_formal': cells[4],
    'name_short': cells[5],
    'url': cells[6],
    'type': cells[7].to_i,
  }
  # 廃止 status == 2
  if status == 2
    item["closed"] = true
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
      header = l.chomp.split(",")
      if header.length != field_list.length
        puts "fields cnt mismatch."
        exit(0)
      end
      header.each_with_index do |f, i|
        if f != field_list[i]
          puts "field name mismatch #{f} <> #{field_list[i]}"
          exit(0)
        end
      end
      puts "read headers. filed size:#{header.length}"
    else
      add_item(l.chomp.split(","), dst)
    end
  end
  puts "data size:#{cnt}"
end

File.open(ARGV[1], "w:utf-8") do |f|
  f.write(format_json(dst, flat_array: [:root]))
end
puts "write into file:#{ARGV[1]}"
