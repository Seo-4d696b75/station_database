load("script/utils.rb")

require "net/http"
require "minitest/autorun"

STATION_FIELD = [
  "code",
  "id",
  "name",
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

API_KEY = read("api_key.txt")

def get_address(station)
  print "get address of station:#{station["name"]} > "
  data = nil
  file = "details/address/#{station["code"]}.json"
  if !data
    uri = URI.parse("https://maps.googleapis.com/")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5
    https.ca_file = "cacert.pem"
    res = https.start { |w| w.get("/maps/api/geocode/json?latlng=#{station["lat"]},#{station["lng"]}&key=#{API_KEY}&language=ja") }
    assert_equal res.code, "200", "response from /maps/api/geocode/json"
    data = JSON.parse(res.body)
    assert_equal data["status"], "OK", "response:\n#{JSON.pretty_generate(data)}"
    h = {}
    h["station"] = station["name"]
    h["lat"] = station["lat"]
    h["lng"] = station["lng"]
    h["plus_code"] = data["plus_code"]
    h["results"] = data["results"]
    File.open("details/address/#{station["code"]}.json", "w") { |f| f.write(JSON.pretty_generate(h)) }
    data = data["results"][0]
    puts "GeocodeAPI success."
  end
  puts "address: #{data["formatted_address"]}"
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

class CSVTest < Minitest::Test
  def setup
    @stations = []
    @station_map = {}
    @station_code_set = Set.new
    @station_name_set = Set.new
    @id_set = IDSet.new
    @pref_cnt = Array.new(48, 0)

    @lines = []
    @line_name_set = Set.new
    @line_code_set = Set.new
  end

  def test_csv
    read_station()
    check_prefecture_cnt()
    read_line()
    check_id()
    check_address()
    check_line_details()
    check_register()
  end

  def teardown
    print "Write station register.csv..."
    File.open("register.csv", "w") do |file|
      @register.each { |e| file.puts(e.join(",")) }
    end
    puts "OK"

    print "Write to json files..."
    File.open("solved/line.json", "w") do |f|
      list = @lines.select { |line| line.delete("impl") }.map do |line|
        line.delete_if do |key, value|
          value == nil || (key == "closed" && !value)
        end
        sort_hash(line)
      end
      f.write(format_json(list, flat: true))
    end
    File.open("solved/station.json", "w") do |f|
      list = @stations.select { |s| s.delete("impl") }.map do |s|
        s.delete_if do |key, value|
          value == nil || (key == "closed" && !value)
        end
        sort_hash(s)
      end
      f.write(format_json(list, flat: true))
    end
    puts "OK"

    puts "All done."
  end

  def read_station
    puts "read station info."
    csv_each_line("station.csv") do |fields|
      csv_err("col size != 14") if fields.length != 14
      code = fields["code"].to_i
      csv_err("code duplicate") if !@station_code_set.add?(code)
      id = read_value(fields, "id")
      if id
        if id.match(/^[0-9a-f]{6}/)
          csv_err("id duplicate") if !@id_set.add?(id)
        else
          csv_err("invalide id value")
        end
      end
      impl = read_boolean(fields, "impl")

      name = read_value(fields, "name")
      name_kana = read_value(fields, "name_kana")
      # 駅メモしようでは駅名重複なし
      csv_err("name duplicated") if impl && !@station_name_set.add?(name)
      lat = fields["lat"].to_f
      lng = fields["lng"].to_f
      pref = fields["prefecture"].to_i
      csv_err("invalid prefecture value") if pref < 1 || pref > 47
      @pref_cnt[pref] += 1 if impl
      closed = read_boolean(fields, "closed")
      attr = read_value(fields, "attr")
      csv_err("invalid attr value") if attr != "eco" && attr != "heat" && attr != "cool" && attr != "unknown"
      csv_err("closed <=> attr") if impl && closed != (attr == "unknown")
      csv_err("attr not defined in not impl station") if !impl && attr
      postal_code = read_value(fields, "postal_code")
      address = read_value(fields, "address")
      station = {}
      station["code"] = code
      station["id"] = id
      station["name"] = name
      station["name_kana"] = name_kana
      station["lat"] = lat
      station["lng"] = lng
      station["prefecture"] = pref
      station["attr"] = attr
      station["postal_code"] = postal_code
      station["address"] = address
      station["impl"] = impl
      station["closed"] = closed
      station["open_date"] = read_date(fields, "open_date")
      station["closed_date"] = read_date(fields, "closed_date")

      # 登録路線用
      station["lines"] = []
      @stations << station
      @station_map[code] = station
      @station_map[name] = station if impl
    end

    impl_size = @stations.select { |s| s["impl"] }.length
    puts "station size: #{@stations.length} (impl #{impl_size})"
  end

  def check_prefecture_cnt
    print "check impl station size in each prefecture..."
    csv_each_line("check/prefecture.csv") do |fields|
      code = fields["code"].to_i
      name = fields["name"]
      size = fields["size"].to_i
      assert_equal size, @pref_cnt[code], "station size(impl) mismatch"
    end
    puts "OK"
  end

  def read_line
    puts "read line info."
    csv_each_line("line.csv") do |fields|
      csv_err("fields size != 12") if fields.length != 12
      code = fields["code"].to_i
      csv_err("line code duplicated") if !@line_code_set.add?(code)
      id = read_value(fields, "id")
      if id
        if id.match(/^[0-9a-f]{6}/)
          csv_err("id duplicate") if !@id_set.add?(id)
        else
          csv_err("invalid id value")
        end
      end
      name = read_value(fields, "name")
      csv_err("line name duplicated.") if !@line_name_set.add?(name)
      name_kana = read_value(fields, "name_kana")
      name_formal = read_value(fields, "name_formal")
      station_size = fields["station_size"].to_i
      company_code = read_value(fields, "company_code")
      company_code = company_code.to_i if company_code
      color = read_value(fields, "color")
      symbol = read_value(fields, "symbol")
      closed = read_boolean(fields, "closed")
      impl = read_boolean(fields, "impl")
      closed_date = read_date(fields, "closed_date")
      puts "Warning > line closed date not defined #{name}" if closed && !closed_date
      csv_err("line not closed, but date defined") if !closed && closed_date

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
    write_id = false
    (@stations + @lines).each do |s|
      if !s["id"]
        s["id"] = id_set.get()
        write_id = true
      end
    end
    if write_id
      write_csv("station.csv", STATION_FIELD, @stations)
      write_csv("line.csv", LINE_FIELD, @lines)
      puts "id added and saved."
    end
  end

  def check_address
    puts "add post&address value if needed."
    @stations.each do |station|
      write = false
      if !station["postal_code"] || !station["address"]
        get_address(station)
        write = true
      end
      assert station["postal_code"].match(/[0-9]{3}-[0-9]{4}/), "invalide post code: #{JSON.dump(station)}"
      write_csv("station.csv", STATION_FIELD, @stations) if write
    end
  end

  def check_line_details
    print "check line details: station-list, polyline..."
    @lines.each do |line|
      # 路線の詳細情報
      path = "details/line/#{line["code"]}.json"
      assert File.exists?(path), "file:#{path} not fount. line:#{JSON.dump(line)}"
      # 路線ポリラインは廃線のみ欠損許す
      path = "polyline/solved/#{line["code"]}.json"
      assert File.exists?(path) || line["closed"], "polyline not found. line:#{JSON.dump(line)}"
    end
    puts "OK"
  end

  def check_register
    puts "checking station-list"

    line_impl_size = {}
    csv_each_line("check/line.csv") do |fields|
      name = fields["name"]
      size = fields["size"].to_i
      line_impl_size[name] = size
    end
    @register = []
    @register << ["station_code", "line_code", "index", "numbering"]
    @lines.each do |line|
      path = "details/line/#{line["code"]}.json"
      details = read_json(path)
      assert_equal line["name"], details["name"], "name mismatch(details). file:#{line["code"]}.json line:#{JSON.dump(line)}"
      # 登録駅数の確認
      size = line["station_size"]
      assert_equal size, details["station_list"].length, "station list size mismatch at #{JSON.dump(line)}"
      line_code = line["code"]
      symbol = line["symbol"]
      impl_size = 0

      write = false
      details["station_list"].map!.each_with_index do |s, i|
        station_code = s["code"]
        station_name = s["name"]
        # 名前解決
        station = nil
        assert (station = @station_map[station_name]) || (station = @station_map[station_code]), "station not found #{station_name}(#{station_code}) at station_list #{JSON.dump(line)}"
        if station_code != station["code"] && station["impl"]
          # 駅メモでは駅名の重複なしのため駅名一致なら同値
          puts "station code changed. #{station_name}@#{line["name"]} #{station_code}=>#{station["code"]}"
          station_code = station["code"]
          s["code"] = station["code"]
          write = true
        elsif station_name != station["name"] && station["imp"]
          # 駅名変更は慎重に
          print "station name changed. #{station_code}@#{line["name"]} #{station_name}=>#{station["name"]} Is this OK? Y/N =>"
          assert gets.chomp.match(/[yY]/), "abort"
          station_name = station["name"]
          s["name"] = station["name"]
          write = true
        elsif station_code != station["code"] || station_name != station["name"]
          assert false, "fail to solve station item. specified:#{station_name}(#{station_code}) <=> found:#{JSON.dump(station)} at station_list #{JSON.dump(line)}"
        end
        impl_size += 1 if station["impl"]
        # 駅要素側にも登録路線を記憶
        station["lines"] << line["code"] if station["impl"] && line["impl"]
        index = i + 1
        # 駅ナンバリングを文字列表現
        numbering = "NULL"
        if s.key?("numbering")
          numbering = s["numbering"].map do |n|
            value = ""
            if n.key?("symbol")
              value << n["symbol"]
            elsif symbol
              value << symbol
            end
            value << n["index"]
            next value
          end.join("/")
        end
        @register << [station_code, line_code, index, numbering]
        next sort_hash(s)
      end

      # 更新あるなら路線詳細へ反映
      if write
        File.open(path, "w:utf-8") do |f|
          f.write(format_json(details, flat_array: ["station_list"]))
        end
      end
      # 登録駅数の再度確認
      if line["impl"]
        size = line_impl_size[line["name"]]
        assert size, "line:#{line["name"]} not found at check/line. at station_list #{JSON.dump(line)}"
        assert_equal size, impl_size, "station size(impl) mismatch at station_list #{JSON.dump(line)}"
        line["station_size"] = size
      end
    end
    # 路線登録されているか
    @stations.each do |station|
      station["lines"].uniq!
      assert station["lines"].length > 0, "station not registered in any line. #{JSON.dump(station)}"
    end
  end
end
