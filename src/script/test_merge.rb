load("src/script/utils.rb")
require "minitest/autorun"

STATION_FIELD = [
  "code",
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
  "attr",
#  "lines", update < extra
# "next" and "voronoi" may change due to other stations' changes
]

LINE_FIELD = [
  "code",
  "name",
  "name_kana",
  "name_formal",
  #"station_size", update < extra
  "company_code",
  "color",
  "symbol",
  "closed",
  "closed_date",
  #"station_list", update < extra
  "north",
  "south",
  "east",
  "west",
  "polyline_list",
]

class MergeTest < Minitest::Test
  def setup()
    data = read_json("out/data.json")
    @version = data["version"]
    @stations = data["stations"]
    @station_map = Hash.new
    @stations.each do |s|
      @station_map[s["id"]] = s
      @station_map[s["code"]] = s
    end
    @lines = data["lines"]

    @log = "## detected diff from `master` branch  \n\n"
  end

  def normalize_value(key, value, station_map)
    if key == "lines"
      # Array of Int
      return value.sort
    elsif key == "station_list"
      # code => id
      value.each do |item|
        item["id"] = station_map[item["code"]]["id"]
      end
      return value
    else
      return value
    end
  end

  def format_md(key, value, station_map)
    if key == "polyline_list"
      return "`{..data..}`"
    elsif key == "station_list"
      value.map! do |e|
        s = station_map[e.delete("id")]
        name = s["name"]
        if numbering = format_numbering(s)
          next "#{name}(#{numbering})"
        else
          next name
        end
      end
    end
    if value.kind_of?(Array) || value.kind_of?(Hash)
      return "`#{JSON.dump(value)}`"
    elsif value.kind_of?(Numeric) || value.kind_of?(String) || value == true || value == false
      return value.to_s
    elsif value == nil
      return "nil"
    end
    raise "unexpected type #{value} #{value.class}"
  end

  def check_diff(tag, id, old, current, fields)
    fields.each do |key|
      old_value = normalize_value(key, old[key], @old_station_map)
      new_value = normalize_value(key, current[key], @station_map)
      if old_value != new_value
        old_value = format_md(key, old_value, @old_station_map)
        new_value = format_md(key, new_value, @station_map)
        @log << "- **#{tag}** id:#{id} name:#{current["name"]} #{key}:#{old_value}=>#{new_value}\n"
      end
    end
  end

  def check_equal(update, extra, fields)
    fields.each do |key|
      update_value = update[key]
      extra_value = extra[key]
      if update_value && extra_value
        assert_equal update_value, extra_value, "not equal name:#{update["name"]} key:#{key}"
      else
        assert !update_value && !extra_value, "lack of field(#{key}) update:#{update_value} extra:#{extra_value} name:#{update["name"]}"
      end
    end
  end

  def is_subset(child, parent, name)
    child.each do |item|
      assert parent.include?(item), "array not subset. name:#{name} child:#{child} parent:#{parent}"
    end
  end

  def test_diff
    # load old version data from
    data = read_json("artifact/master.json")
    old_version = data["version"]
    assert old_version < @version, "version err"
    @old_station_map = Hash.new
    old_stations = data["stations"]
    old_stations.each do |s|
      @old_station_map[s["id"]] = s
      @old_station_map[s["code"]] = s
    end
    old_lines = data["lines"]

    # map of new stations and lines
    stations = Hash.new
    lines = Hash.new
    @stations.each { |s| stations[s["id"]] = s }
    @lines.each { |l| lines[l["id"]] = l }

    old_stations.each do |old|
      id = old["id"]
      station = stations.delete(id)
      assert station, "station not found old:#{JSON.dump(old)}"
      check_diff("station", id, old, station, STATION_FIELD)
    end
    old_lines.each do |old|
      id = old["id"]
      line = lines.delete(id)
      assert line, "line not found old:#{JSON.dump(old)}"
      check_diff("line", id, old, line, LINE_FIELD)
    end
    stations.each_value do |station|
      @log << "- **station** new station #{format_md(station)}\n"
    end
    lines.each_value do |line|
      @log << "- **line** new line #{format_md(line)}\n"
    end
  end

  def test_subset
    # load whole data from
    data = read_json("artifact/extra.json")
    assert_equal data["version"], @version, "version err"

    stations = Hash.new
    lines = Hash.new
    data["stations"].each { |s| stations[s["id"]] = s }
    data["lines"].each { |l| lines[l["id"]] = l }

    @stations.each do |s|
      assert s.fetch("impl", true), "not impl #{JSON.dump(s)} at update"
      station = stations.delete(s["id"])
      assert station, "station not found, but in subset:#{JSON.dump(s)}"
      assert station.fetch("impl", true), "not impl #{JSON.dump(station)} at extra"
      check_equal(s, station, STATION_FIELD)
      is_subset(s["lines"], station["lines"], s["name"])
    end
    @lines.each do |l|
      assert l.fetch("impl", true), "not impl #{l["name"]} at update"
      line = lines.delete(l["id"])
      assert line, "station not found, but in subset:#{l["name"]}"
      assert line.fetch("impl", true), "not impl #{line["name"]} at extra"
      check_equal(l, line, LINE_FIELD)
      assert l["station_size"] <= line["station_size"], "station_size mismatch #{l["name"]}"
      is_subset(l["station_list"], line["station_list"], l["name"])
    end
  end

  def teardown()
    File.open("artifact/diff.md", "w") { |f| f.write(@log) }
    File.open(".github/workflows/diff.md", "w") do |f|
      # python str::format で使用するtemplate
      f.write(@log.gsub("{", "{{").gsub("}", "}}"))
    end
  end
end
