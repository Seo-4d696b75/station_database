# check there is no contradiction between a new dataset and old one
load("src/script/utils.rb")
require "minitest/autorun"

# these fields of station item will be checked
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
  "lines",
  "impl",
# "next" and "voronoi" may change due to other stations' changes
]

# these fields of line item will be checked
LINE_FIELD = [
  "code",
  "name",
  "name_kana",
  "name_formal",
  "station_size",
  "company_code",
  "color",
  "symbol",
  "closed",
  "closed_date",
  "station_list",
  "polyline_list",
  "impl",
]

# these fields are ignored
IGNORE = [
  "code",
  "lines",
  "polyline_list",
]

class MergeTest < Minitest::Test
  def setup()
    # load old version data from artifact
    data = read_json("artifact/data.json")
    @old_version = data["version"]
    @old_station_map = Hash.new
    @old_stations = data["stations"]
    @old_stations.each do |s|
      @old_station_map[s["id"]] = s
      @old_station_map[s["code"]] = s
    end
    @old_lines = data["lines"]
    data = read_json("out/data.json")
    @stations = Hash.new
    @station_map = Hash.new
    data["stations"].each do |s|
      @stations[s["id"]] = s
      @station_map[s["id"]] = s
      @station_map[s["code"]] = s
    end
    @lines = Hash.new
    data["lines"].each { |l| @lines[l["id"]] = l }

    @log = "## detected diff from `extra` branch  \n\n"
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

  def format_md(value, key = nil, station_map = nil)
    if key == "polyline_list"
      return "`{..data..}`"
    elsif key == "station_list"
      value.map! do |e|
        s = station_map[e.delete("id")]
        name = s["name"]
        if n = s["numbering"]
          next "#{name}(#{n.join("/")})"
        else
          next name
        end
      end
    elsif key == "line" || key == "station"
      return "#{value["name"]}(#{value["code"]})"
    end
    if value.kind_of?(Array) || value.kind_of?(Hash)
      return "`#{JSON.dump(value)}`"
    elsif value.kind_of?(Numeric) || value.kind_of?(String) || value == true || value == false
      return value.to_s
    elsif value == nil
      return "null"
    end
    raise "unexpected type #{value} #{value.class}"
  end

  def check_diff(tag, id, old, current, fields)
    fields.each do |key|
      next if IGNORE.include?(key)
      old_value = normalize_value(key, old[key], @old_station_map)
      new_value = normalize_value(key, current[key], @station_map)
      if old_value != new_value
        old_value = format_md(old_value, key, @old_station_map)
        new_value = format_md(new_value, key, @station_map)
        @log << "- **#{tag}** id:#{id} name:#{current["name"]} #{key}:#{old_value}=>#{new_value}\n"
      end
    end
  end

  def test_id
    @old_stations.each do |old|
      id = old["id"]
      station = @stations.delete(id)
      assert station, "station not found old:#{JSON.dump(old)}"
      check_diff("station", id, old, station, STATION_FIELD)
    end
    @old_lines.each do |old|
      id = old["id"]
      line = @lines.delete(id)
      assert line, "line not found old:#{JSON.dump(old)}"
      check_diff("line", id, old, line, LINE_FIELD)
    end
    @stations.each_value do |station|
      @log << "- **station** new station #{format_md(station, "station")}\n"
    end
    @lines.each_value do |line|
      @log << "- **line** new line #{format_md(line, "line")}\n"
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
