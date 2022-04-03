load("src/script/utils.rb")
load("src/script/diff.rb")
require "minitest/autorun"
require "optparse"

opt = OptionParser.new
opt.on("-o", "--old VALUE") { |v| OLD_FILE = v }
opt.on("-n", "--new VALUE") { |v| NEW_FILE = v }
opt.on("-l", "--log VALUE") { |v| LOG_FILE = v }
opt.on("-m", "--message VALUE") { |v| LOG_MES = v }
opt.parse!(ARGV)
ARGV.clear()

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

class SubsetTest < MiniTest::Test
  def setup()
    # load a new dataset
    data = read_json(NEW_FILE)
    @version = data["version"]
    @stations = data["stations"]
    @station_map = Hash.new
    @stations.each do |s|
      @station_map[s["id"]] = s
      @station_map[s["code"]] = s
    end
    @lines = data["lines"]

    @log = "## #{LOG_MES}  \n\n"
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

  def test_update
    # load old version data from
    data = read_json(OLD_FILE)
    old_version = data["version"]
    assert old_version <= @version, "version err"
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

    # constrain: old dataset is a subset of new dataset
    # any station item in old dataset must also be included in new dataset

    old_stations.each do |old|
      id = old["id"]
      station = stations.delete(id)
      # extra　データセット固有の駅に関しては削除を許容する（一時的な対応）      
      assert station || !old["impl"], "station not found old:#{JSON.dump(old)}"
      if station
        check_diff("station", id, old, station, STATION_FIELD)
      else
        @log << "- **station** deleted #{format_md(old, key = "station")}\n"
      end
    end
    old_lines.each do |old|
      id = old["id"]
      line = lines.delete(id)
      assert line, "line not found old:#{JSON.dump(old)}"
      check_diff("line", id, old, line, LINE_FIELD)
    end
    stations.each_value do |station|
      @log << "- **station** new station #{format_md(station, key = "station")}\n"
    end
    lines.each_value do |line|
      @log << "- **line** new line #{format_md(line, key = "line")}\n"
    end
  end

  def teardown()
    File.open("artifact/#{LOG_FILE}", "w") { |f| f.write(@log) }
    File.open(".github/workflows/#{LOG_FILE}", "w") do |f|
      # python str::format で使用するtemplate
      f.write(@log.gsub("{", "{{").gsub("}", "}}"))
    end
  end
end
