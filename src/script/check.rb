# src/*.csvファイルを入力としてデータ整合性の確認・データの自動補完を行います
# オプション
# -e [--extra]: extraデータセットを対象とします
# -d [--dst] DIR: DIRを指定するとbuildしたjsonファイル群を出力します（補完作業なし）
#                 DIRの指定がない場合はインタラクションモードで実行します（補完作業あり）

# TODO build機能と src/**/* の自動補完機能+test機能を分離する
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
  "extra",
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
  "extra",
]

REGISTER_FIELDS = [
  "station_code", "line_code", "index", "numbering", "extra",
]

Dotenv.load "src/.env.local"
API_KEY = ENV["GOOGLE_GEOCODING_API_KEY"]

$interaction = false
$extra = false
$dst = nil
opt = OptionParser.new
opt.on("-e", "--extra") { $extra = true }
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

    if !$extra
      # filter not extra
      @stations.select! do |s|
        s["lines"].select! { |code| !@line_map[code]["extra"] }
        !s.delete("extra")
      end
      @lines.select! do |l|
        # station_list edited
        !l.delete("extra")
      end
    end
  end

  def test_all()
    self.check_station
    self.check_line
  end

  def teardown
    if $dst
      puts "write csv to #{$dst}/*.csv extra:#{$extra}"
      station_field = STATION_FIELD.dup
      line_field = LINE_FIELD.dup
      register_field = REGISTER_FIELDS.dup
      if !$extra
        station_field.delete("extra")
        line_field.delete("extra")
        register_field.delete("extra")
      end
      write_csv("#{$dst}/station.csv", station_field, @stations)
      write_csv("#{$dst}/line.csv", line_field, @lines)
      write_csv("#{$dst}/register.csv", register_field, @register)
      puts "OK"

      print "Write to json files..."
      File.open("build/line#{$extra ? ".extra" : ""}.json", "w") do |f|
        list = @lines.map do |line|
          line.delete_if do |key, value|
            value == nil || key == "station_list"
          end
          sort_hash(line)
        end
        f.write(format_json(list, flat_array: [:root]))
      end
      File.open("build/station#{$extra ? ".extra" : ""}.json", "w") do |f|
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
      extra = fields.boolean("extra")

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
      station["extra"] = extra
      station["closed"] = closed
      station["open_date"] = fields.date("open_date")
      station["closed_date"] = fields.date("closed_date")

      puts "Warning > may be invalid suffix of name:#{name_original}" if name_original.end_with?("駅", "停留所", "乗降場")
      # 登録路線用
      station["lines"] = []
      @stations << station
    end
    impl_size = @stations.select { |s| !s["extra"] }.length
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
      extra = fields.boolean("extra")
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
      line["extra"] = extra
      line["closed_date"] = closed_date

      @lines << line
    end

    impl_size = @lines.select { |s| !s["extra"] }.length
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

    impl_size_map = Hash.new
    csv_each_line("src/check/line.csv") do |fields|
      name = fields["name"]
      size = fields["size"].to_i
      impl_size_map[name] = size
    end

    polyline_ignore = []
    csv_each_line("src/check/polyline_ignore.csv") do |line|
      polyline_ignore << line.str("name")
    end

    @register = []
    @lines.each do |line|
      # 路線の登録駅情報
      path = "src/line/#{line["code"]}.json"
      assert File.exist?(path), "file:#{path} not found. line:#{JSON.dump(line)}"
      details = read_json(path)
      assert_equal line["name"], details["name"], "name mismatch(details). file:#{line["code"]}.json line:#{JSON.dump(line)}"
      # 登録駅数の確認
      size = line["station_size"]
      assert_equal size, details["station_list"].length, "station list size mismatch at #{JSON.dump(line)}"
      line_code = line["code"]

      # 登録駅の駅コード・駅名の変化があれば更新する
      write = false
      # 登録駅数
      count = 0
      # 駅メモ登録駅数
      impl_size = 0
      line["station_list"] = details["station_list"].map.each_with_index do |s, i|
        station_code = s["code"]
        station_name = s["name"]
        extra = !!s["extra"]
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
        end

        # 駅ナンバリングを文字列表現
        numbering = "NULL"
        if n = s["numbering"]
          numbering = n.join("/")
        end

        # mainデータセットの登録駅に注意
        # src/line/*.json .station_list[].extra: 路線に対する登録
        # src/*.csv extra: 路線・駅自体
        if $extra || (!extra && !station["extra"] && !line["extra"])
          register_extra = extra || station["extra"] || line["extra"]
          count += 1
          @register << {
            "station_code" => station_code,
            "line_code" => line_code,
            "index" => count,
            "numbering" => numbering,
            "extra" => register_extra,
          }
          impl_size += 1 if !register_extra

          # 駅要素側にも登録路線を記憶
          station["lines"] << line["code"]
          next sort_hash(s)
        else
          next nil
        end
      end.compact

      line["station_size"] = line["station_list"].length

      # 駅メモ実装の登録駅数を確認
      if !line["extra"]
        assert impl_size_map.key?(line["name"]), "no staion size found in check/line.csv @#{line["name"]}"
        assert_equal impl_size, impl_size_map[line["name"]], "station size (impl) mismatch vs check/line.csv @#{line["name"]}}"
      else
        assert_equal impl_size, 0, "station size (impl) of extra line must be 0 @#{line["name"]}"
      end

      # 更新あるなら駅登録詳細へ反映
      if write
        assert($interaction, "not interaction mode")
        File.open(path, "w:utf-8") do |f|
          f.write(format_json(details, flat_array: ["station_list"]))
        end
      end

      # 路線ポリラインは廃線,extraのみ欠損許す
      path = "src/polyline/#{line["code"]}.json"
      if !File.exist?(path)
        assert polyline_ignore.include?(line["name"]), "polyline not found. line:#{JSON.dump(line)}"
      end
    end
  end
end
