require "minitest/autorun"
require "set"
load("src/script/utils.rb")

class FormatTest < Minitest::Test
  def setup()
    data = read_json("out/data.json")
    @stations = data["stations"]
    @lines = data["lines"]

    # check id/code duplication
    @id_set = Set.new
    @station_map = Hash.new
    @line_map = Hash.new
    @stations.each do |s|
      assert @id_set.add?(s["id"]), "id duplicated #{JSON.dump(s)}"
      assert !@station_map.key?(s["code"]), "station code duplicated #{JSON.dump(s)}"
      assert !@station_map.key?(s["name"]), "station name duplicated #{JSON.dump(s)}"
      @station_map[s["code"]] = s
      @station_map[s["name"]] = s
    end
    @lines.each do |line|
      assert @id_set.add?(line["id"]), "id duplicated #{line["name"]}"
      assert !@line_map.key?(line["code"]), "line code duplicated #{line["name"]}"
      assert !@line_map.key?(line["name"]), "line name duplicated #{line["name"]}"
      @line_map[line["code"]] = line
      @line_map[line["name"]] = line
    end
  end

  def test_station
    pref_cnt = Array.new(48, 0)
    @stations.each do |station|
      code = station["code"]
      id = station["id"]
      name = station["name"]
      name_original = station["original_name"]
      name_kana = station["name_kana"]
      closed = !!station["closed"]
      lng = station["lng"]
      lat = station["lat"]
      pref = station["prefecture"]
      post = station["postal_code"]
      address = station["address"]
      attribute = station["attr"]
      lines = station["lines"]
      next_station = station["next"]
      voronoi = station["voronoi"]
      # check field value
      assert code && code.kind_of?(Integer), "invalid code #{JSON.dump(station)}"
      assert id && id.kind_of?(String) && id.match(/^[0-9a-f]{6}$/), "invalid id #{JSON.dump(station)}"
      assert name && name.kind_of?(String) && name.length > 0, "invalide name #{JSON.dump(station)}"
      assert !name_original || (name_original.kind_of?(String) && name_original.length > 0 && name.include?(name_original)), "invalide original name #{JSON.dump(station)}"
      assert name_kana && name_kana.kind_of?(String) && name_kana.match(/[\p{hiragana}（・）]+/), "invalid name_kana #{JSON.dump(station)}"
      assert lng && lng.kind_of?(Float) && lat && lat.kind_of?(Float), "invalid coordinate #{JSON.dump(station)}"
      assert pref && pref.kind_of?(Integer) && pref > 0 && pref <= 47, "invalid pref #{JSON.dump(station)}"
      assert post && post.kind_of?(String) && post.match(/[0-9]{3}-[0-9]{4}/), "invalid postal_code #{JSON.dump(station)}"
      assert address && address.kind_of?(String) && address.length > 0, "invalid address #{JSON.dump(station)}"
      assert ["eco", "heat", "cool", "unknown"].include?(attribute), "invalid attr #{JSON.dump(station)}"
      assert lines && lines.kind_of?(Array) && lines.length > 0, "invalid lines #{JSON.dump(station)}"
      assert next_station && next_station.kind_of?(Array) && next_station.length > 0, "invalid next #{JSON.dump(station)}"
      assert voronoi, "invalid voronoi #{JSON.dump(station)}"

      pref_cnt[pref] += 1
      assert closed == (attribute == "unknown"), "invalid attr<=>closed value #{JSON.dump(station)}"
      lines.each do |code|
        assert @line_map.key?(code), "line code #{code} not found at lines #{JSON.dump(station)}"
      end
      assert closed || lines.map { |code| @line_map[code] }.select { |l| !l["closed"] }.length > 0, "non-closed station must be in non-closed line #{JSON.dump(station)}"
      next_station.each do |n|
        assert code != n && @station_map.key?(n), "station code #{n} not found at next #{JSON.dump(station)}"
      end
    end
    csv_each_line("src/check/prefecture.csv") do |fields|
      code = fields["code"].to_i
      name = fields["name"]
      size = fields["size"].to_i
      assert_equal size, pref_cnt[code], "station size in pref mismatch at #{name}"
    end
  end

  def test_line
    @lines.each do |line|
      code = line["code"]
      id = line["id"]
      name = line["name"]
      name_kana = line["name_kana"]
      closed = !!line["closed"]
      symbol = line["symbol"]
      color = line["color"]
      station_size = line["station_size"]
      station_list = line["station_list"]
      polyline = line["polyline_list"]

      # check field value
      assert code && code.kind_of?(Integer), "invalid code #{name}"
      assert id && id.kind_of?(String) && id.match(/^[0-9a-f]{6}$/), "invalid id #{name}"
      assert name && name.kind_of?(String) && name.length > 0, "invalide name #{name}"
      assert name_kana && name_kana.kind_of?(String) && name_kana.match(/[\p{hiragana}（・）]+/), "invalid name_kana #{name}"
      assert !symbol || (symbol.kind_of?(String) && symbol.length > 0), "invalid symbol #{name}"
      assert !color || (color.kind_of?(String) && color.match(/#[0-9A-F]{6}/)), "invalid color #{name}"
      assert_equal station_size, station_list.length, "station size mismatch  #{name}"
      assert closed || polyline, "non-closed line must have polyline data #{name}"
      assert !polyline || (line["north"] && line["south"] && line["east"] && line["west"]), "polyline boundary needed #{name}"
      station_list.each do |item|
        s = @station_map[item["code"]]
        assert s && s["lines"].include?(code), "invalid station item:#{item["code"]} at"
      end
    end

    csv_each_line("src/check/line.csv") do |fields|
      name = fields["name"]
      size = fields["size"].to_i
      line = @line_map[name]
      assert line && line["station_size"] == size, "station size mismatch #{name}"
    end
  end
end
