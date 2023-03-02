# src/*.csvファイルを入力としてデータ整合性の確認・データの自動補完を行います
# オプション
# -i [--impl]: "impl"=trueのデータのみ対象にします
# -d [--dst] DIR: DIRを指定するとbuildしたjsonファイル群を出力します（補完作業なし） 
#                 DIRの指定がない場合はインタラクションモードで実行します（補完作業あり）

load("src/script/format.rb")

require "net/http"
require "optparse"
require "dotenv"

STATION_FIELD = [
  "code",
  "id",
  "name",
  "original_name",
  "name_kana",
  "lat",
  "lng",
  "prefecture",
  "postal_code",
  "address",
  "closed",
  "open_date",
  "closed_date",
  "impl",
  "attr",
]

LINE_FIELD = [
  "code",
  "id",
  "name",
  "name_kana",
  "name_formal",
  "station_size",
  "company_code",
  "color",
  "symbol",
  "closed",
  "closed_date",
  "impl",
]

REGISTER_FIELDS = [
  "station_code", "line_code", "index", "numbering", "impl",
]

Dotenv.load "src/.env.local"
API_KEY = ENV["GOOGLE_GEOCODING_API_KEY"]

$interaction = false
$impl = true
$dst = nil
opt = OptionParser.new
opt.on("-e", "--extra") { $impl = false }
opt.on("-i", "--interaction") { $interaction = true }
opt.on("-d", "--dst VALUE") { |v| $dst = v }
opt.parse!(ARGV)
ARGV.clear()

def get_address(station)
  print "get address of station:#{station["name"]} > "

  uri = URI.parse("https://maps.googleapis.com/")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  https.verify_depth = 5
  res = https.start { |w| w.get("/maps/api/geocode/json?latlng=#{station["lat"]},#{station["lng"]}&key=#{API_KEY}&language=ja") }
  assert_equal res.code, "200", "response from /maps/api/geocode/json"
  data = JSON.parse(res.body)
  assert_equal data["status"], "OK", "response:\n#{JSON.pretty_generate(data)}"
   
  data = data["results"][0]

  puts "address: #{data["formatted_address"]} #{data}"
  # 郵便番号
  list = data["address_components"].select { |c| c["types"].include?("postal_code") }
  assert_equal list.length, 1, "fail to extract postal-code"
  station["postal_code"] = list[0]["long_name"]
  # 住所
  exception = ["postal_code", "country", "bus_station", "train_station", "transit_station"]
  predicate = lambda do |list|
    list.each { |e| return false if exception.include?(e) }
    return true
  end
  address = ""
  previous = nil
  pattern = /^[0-9０-９]+$/
  data["address_components"].select do |c|
    predicate.call(c["types"])
  end.reverse.map { |c| c["long_name"] }.each do |c|
    if previous && previous.match(pattern) && c.match(pattern)
      address << "-"
    end
    address << c
    previous = c
  end
  station["address"] = address
end

class CSVTest < FormatTest
  def setup
    @stations = []
    @lines = []
    @id_set = IDSet.new

    # read data from csv file, fields validation not checked
    read_station()
    read_line()
    # fill in blank id values, if needed
    check_id()
    # fill in blank address and post-code, if needed
    check_address()

    # save with formatted values
    if $interaction
      write_csv("src/station.csv", STATION_FIELD, @stations)
      write_csv("src/line.csv", LINE_FIELD, @lines)
    end

    self.check_init()

    # read line details from other files
    # registaration of station-line is defined here
    read_line_details()

    if $impl
      # filter impl
      @stations.select! do |s|
        s["lines"].select! { |code| @line_map[code]["impl"] }
        s.delete("impl")
      end
      @lines.select! do |l|
        # station_list edited
        l.delete("impl")
      end
    end
  end

  def test_all()
    self.check_station(false)
    self.check_line(false)
  end

  def teardown
    if $dst
      puts "write csv to #{$dst}/*.csv impl:#{$impl}"
      station_field = STATION_FIELD.dup
      line_field = LINE_FIELD.dup
      register_field = REGISTER_FIELDS.dup
      if $impl
        station_field.delete("impl")
        line_field.delete("impl")
        register_field.delete("impl")
      end
      write_csv("#{$dst}/station.csv", station_field, @stations)
      write_csv("#{$dst}/line.csv", line_field, @lines)
      write_csv("#{$dst}/register.csv", register_field, @register)
      puts "OK"

      print "Write to json files..."
      File.open("build/line#{$impl ? "" : ".extra"}.json", "w") do |f|
        list = @lines.map do |line|
          line.delete_if do |key, value|
            value == nil || key == "station_list"
          end
          sort_hash(line)
        end
        f.write(format_json(list, flat_array: [:root]))
      end
      File.open("build/station#{$impl ? "" : ".extra"}.json", "w") do |f|
        list = @stations.map do |s|
          s.delete_if { |key, value| value == nil }
          sort_hash(s)
        end
        f.write(format_json(list, flat_array: [:root]))
      end
    end

    puts "All done."
  end

  def read_station
    csv_each_line("src/station.csv") do |fields|
      csv_err("col size != 15") if fields.length != 15
      code = fields["code"].to_i
      id = fields.str("id")
      impl = fields.boolean("impl")

      name = fields.str("name")
      name_original = fields.str("original_name")
      name_kana = fields.str("name_kana")
      lat = fields["lat"].to_f
      lng = fields["lng"].to_f
      pref = fields["prefecture"].to_i
      closed = fields.boolean("closed")
      attr = fields.str("attr")
      postal_code = fields.str("postal_code")
      address = fields.str("address")
      station = {}
      station["code"] = code
      station["id"] = id
      station["name"] = name
      station["original_name"] = name_original
      station["name_kana"] = name_kana
      station["lat"] = lat
      station["lng"] = lng
      station["prefecture"] = pref
      station["attr"] = attr
      station["postal_code"] = postal_code
      station["address"] = address
      station["impl"] = impl
      station["closed"] = closed
      station["open_date"] = fields.date("open_date")
      station["closed_date"] = fields.date("closed_date")

      puts "Warning > may be invalid suffix of name:#{name_original}" if name_original.end_with?("駅", "停留所", "乗降場")
      # 登録路線用
      station["lines"] = []
      @stations << station
    end
    impl_size = @stations.select { |s| s["impl"] }.length
    puts "station size: #{@stations.length} (impl #{impl_size})"
  end

  def read_line
    csv_each_line("src/line.csv") do |fields|
      csv_err("fields size != 12") if fields.length != 12
      code = fields["code"].to_i
      id = fields.str("id")
      name = fields.str("name")
      name_kana = fields.str("name_kana")
      name_formal = fields.str("name_formal")
      station_size = fields["station_size"].to_i
      company_code = fields.str("company_code")
      company_code = company_code.to_i if company_code
      color = fields.str("color")
      symbol = fields.str("symbol")
      closed = fields.boolean("closed")
      impl = fields.boolean("impl")
      closed_date = fields.date("closed_date")
      puts "Warning > line closed date not defined #{name}" if closed && !closed_date

      line = {}
      line["code"] = code
      line["id"] = id
      line["name"] = name
      line["name_kana"] = name_kana
      line["name_formal"] = name_formal
      line["station_size"] = station_size
      line["company_code"] = company_code
      line["color"] = color
      line["symbol"] = symbol
      line["closed"] = closed
      line["impl"] = impl
      line["closed_date"] = closed_date

      @lines << line
    end

    impl_size = @lines.select { |s| s["impl"] }.length
    puts "lins size: #{@lines.length} (impl #{impl_size})"
  end

  def check_id
    puts "add id to new station/line time."
    (@stations + @lines).each do |s|
      if !s["id"]
        assert($interaction, "not interaction mode")
        s["id"] = @id_set.get()
      end
    end
  end

  def check_address
    @stations.each do |station|
      if !station["postal_code"] || !station["address"]
        assert($interaction, "not interaction mode")
        get_address(station)
      end
      assert station["postal_code"].match(PATTERN_POST), "invalide post code: #{JSON.dump(station)}"
    end
  end

  def read_line_details
    puts "reading line details..."

    polyline_ignore = [] 
    csv_each_line("src/check/polyline_ignore.csv") do |line|
      polyline_ignore << line.str("name")
    end

    @register = []
    @lines.each do |line|
      # 路線の登録駅情報
      path = "src/line/#{line["code"]}.json"
      assert File.exists?(path), "file:#{path} not found. line:#{JSON.dump(line)}"
      details = read_json(path)
      assert_equal line["name"], details["name"], "name mismatch(details). file:#{line["code"]}.json line:#{JSON.dump(line)}"
      # 登録駅数の確認
      size = line["station_size"]
      assert_equal size, details["station_list"].length, "station list size mismatch at #{JSON.dump(line)}"
      line_code = line["code"]
      impl_size = 0

      write = false
      line["station_list"] = details["station_list"].map.each_with_index do |s, i|
        station_code = s["code"]
        station_name = s["name"]
        impl = s.fetch("impl", true)
        # 名前解決
        station = nil
        assert (station = @station_map[station_name]) || (station = @station_map[station_code]), "station not found #{station_name}(#{station_code}) at station_list #{JSON.dump(line)}"
        if station_code != station["code"]
          # 駅名の重複なしのため駅名一致なら同値
          puts "station code changed. #{station_name}@#{line["name"]}(#{line["code"]}) #{station_code}=>#{station["code"]}"
          assert($interaction, "not interaction mode")
          station_code = station["code"]
          s["code"] = station["code"]
          write = true
        elsif station_name != station["name"]
          # 駅名変更は慎重に
          print "station name changed. #{station_code}@#{line["name"]}(#{line["code"]}) #{station_name}=>#{station["name"]} Is this OK? Y/N =>"
          assert($interaction, "not interaction mode")
          assert gets.chomp.match(/^[yY]?$/), "abort"
          station_name = station["name"]
          s["name"] = station["name"]
          write = true
        elsif station_code != station["code"] || station_name != station["name"]
          assert false, "fail to solve station item. specified:#{station_name}(#{station_code}) <=> found:#{JSON.dump(station)} at station_list #{JSON.dump(line)}"
        end

        index = i + 1
        # 駅ナンバリングを文字列表現
        numbering = "NULL"
        if n = s["numbering"]
          numbering = n.join("/")
        end
        if !$impl || (impl && station["impl"] && line["impl"])
          @register << {
            "station_code" => station_code,
            "line_code" => line_code,
            "index" => index,
            "numbering" => numbering,
            "impl" => (impl && station["impl"]),
          }
        end

        # 路線登録数の確認 impl only
        impl_size += 1 if station["impl"] && impl

        if !$impl || (station["impl"] && impl)
          # only impl# 駅要素側にも登録路線を記憶
          station["lines"] << line["code"]
          next sort_hash(s)
        else
          next nil
        end
      end.compact
      line["station_size"] = line["station_list"].length if $impl

      # 更新あるなら駅登録詳細へ反映
      if write
        assert($interaction, "not interaction mode")
        File.open(path, "w:utf-8") do |f|
          f.write(format_json(details, flat_array: ["station_list"]))
        end
      end

      # 路線ポリラインは廃線,no-implのみ欠損許す
      path = "src/polyline/#{line["code"]}.json"
      if !File.exists?(path)
        assert polyline_ignore.include?(line["name"]) && line["closed"], "polyline not found. line:#{JSON.dump(line)}"
      end
      # no validation
    end
  end
end
