# check there is no contradiction between a new dataset and old one
load("src/script/diff.rb")
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
IGNORE = []

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
    @log << "**Ignored keys**: #{IGNORE.join(",")}\n" if IGNORE.length > 0
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
