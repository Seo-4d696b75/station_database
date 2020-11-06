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
    dup_name = Hash.new([])
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
      open_date = station["open_date"]
      closed_date = station["closed_date"]
      impl = station["impl"]
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
      assert !impl || ["eco", "heat", "cool", "unknown"].include?(attribute), "invalid attr #{JSON.dump(station)}"
      assert impl || !attribute, "invalid attr #{JSON.dump(station)}"
      assert lines && lines.kind_of?(Array) && lines.length > 0, "invalid lines #{JSON.dump(station)}"
      assert next_station && next_station.kind_of?(Array) && next_station.length > 0, "invalid next #{JSON.dump(station)}"
      assert voronoi, "voronoi not found #{JSON.dump(station)}"
      assert !open_date || open_date.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/), "invalid open date #{JSON.dump(station)}"
      assert !closed_date || closed_date.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/), "invalid closed date #{JSON.dump(station)}"
      if open_date && closed_date
        assert open_date < closed_date, "open < closed ? #{JSON.dump(station)}"
      end
      assert closed || !closed_date, "not closed but closed-date defined #{JSON.dump(station)}"

      # name and original_name
      if name != name_original
        dup_name[name_original] = [station, *dup_name[name_original]]
      end

      # cnt in each prefecture
      pref_cnt[pref] += 1 if impl

      # 'closed'
      assert !impl || closed == (attribute == "unknown"), "invalid attr<=>closed value #{JSON.dump(station)}"
      # 'lines'
      assert lines.length > 0, "not registered in any line, staion:#{JSON.dump(statoin)}"
      lines.each do |code|
        assert @line_map.key?(code), "line code #{code} not found at lines #{JSON.dump(station)}"
      end
      assert closed || lines.map { |code| @line_map[code] }.select { |l| !l["closed"] }.length > 0, "non-closed station must be in non-closed line #{JSON.dump(station)}"
      # 'next'
      next_station.each do |n|
        assert code != n && @station_map.key?(n), "station code #{n} not found at next #{JSON.dump(station)}"
      end
      # 'voronoi'
      assert voronoi["lat"] && voronoi["lat"].kind_of?(Float), "invalid voronoi::lat #{JSON.dump(station)}"
      assert voronoi["lng"] && voronoi["lng"].kind_of?(Float), "invalid voronoi::lng #{JSON.dump(station)}"
      assert voronoi["delta_lat"] && voronoi["delta_lng"], "voronoi::delta not found #{JSON.dump(station)}"
      assert_equal voronoi["delta_lng"].length, voronoi["delta_lat"].length, "voronoi::delta length mismatch #{JSON.dump(station)}"
    end

    # check name duplication
    dup_name.each do |key, value|
      if s = @station_map[key]
        assert s["impl"] && value.select { |v| v["impl"] }.length == 0, "original_name '#{key}' duplicated, but no suffix in name of #{JSON.dump(s)}"
        # may be value.length == 1
        next
      end
      assert value.length > 1, "original_name '#{key}' not duplicated #{JSON.dump(value[0])}"
    end

    # check cnt in each pref.
    csv_each_line("src/check/prefecture.csv") do |fields|
      code = fields["code"].to_i
      name = fields["name"]
      size = fields["size"].to_i
      assert_equal size, pref_cnt[code], "station size in pref mismatch at #{name}"
    end
  end

  def test_line
    line_impl_size = Hash.new
    csv_each_line("src/check/line.csv") do |fields|
      name = fields["name"]
      size = fields["size"].to_i
      line_impl_size[name] = size
    end

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
      closed_date = line["closed_date"]
      impl = line["impl"]

      # check field value
      assert code && code.kind_of?(Integer), "invalid code #{name}"
      assert id && id.kind_of?(String) && id.match(/^[0-9a-f]{6}$/), "invalid id #{name}"
      assert name && name.kind_of?(String) && name.length > 0, "invalide name #{name}"
      assert name_kana && name_kana.kind_of?(String) && name_kana.match(/[\p{hiragana}（・）]+/), "invalid name_kana #{name}"
      assert !symbol || (symbol.kind_of?(String) && symbol.length > 0), "invalid symbol #{name}"
      assert !color || (color.kind_of?(String) && color.match(/#[0-9A-F]{6}/)), "invalid color #{name}"
      assert_equal station_size, station_list.length, "station size mismatch  #{name}"
      assert !impl || closed || polyline, "non-closed line must have polyline data #{name}"
      assert !polyline || (line["north"] && line["south"] && line["east"] && line["west"]), "polyline boundary needed #{name}"

      # station list
      impl_size = 0
      station_list.each do |item|
        s = @station_map[item["code"]]
        assert s && s["lines"].include?(code), "invalid station item:#{item["code"]} at #{name}"
        impl_size += 1 if s["impl"] && (!item.key?("impl") || !!item["impl"])
      end
      if impl
        size = line_impl_size[name]
        assert size, "line:#{name} not found at check/line. at station_list #{JSON.dump(line)}"
        assert_equal size, impl_size, "station size(impl) mismatch at station_list #{JSON.dump(line)}"
      end

      # date
      assert !closed_date || closed_date.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/), "invalid closed date #{name}"
      assert closed || !closed_date, "not closed but closed-date defined #{name}"
    end

    csv_each_line("src/check/line.csv") do |fields|
      name = fields["name"]
      size = fields["size"].to_i
      line = @line_map[name]
      assert line && line["station_size"] == size, "station size mismatch #{name}"
    end
  end
end
