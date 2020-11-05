load("src/script/utils.rb")
require "minitest/autorun"

STATION_FIELD = [
  "code",
  "name",
  #"original_name",
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
  "north",
  "south",
  "east",
  "west",
  "polyline",
]

def format_md(value)
  if value.kind_of?(Array) || value.kind_of?(Hash)
    return "`#{JSON.dump(value)}`"
  elsif value.kind_of?(Numeric) || value.kind_of?(String) || value == true || value == false
    return value.to_s
  end
  raise "unexpected type #{value} #{value.class}"
end

class MergeTest < Minitest::Test
  def setup()
    # load old version data from artifact
    data = read_json("artifact/data.json")
    @old_version = data["version"]
    @old_stations = data["stations"]
    @old_lines = data["lines"]
    data = read_json("out/data.json")
    @stations = Hash.new
    data["stations"].each { |s| @stations[s["id"]] = s }
    @lines = Hash.new
    data["lines"].each { |l| @lines[l["id"]] = l }

    @log = "## detected diff from `master` branch  \n\n"
  end

  def check_diff(tag, id, old, current, fields)
    fields.each do |key|
      old_value = old[key]
      new_value = current[key]
      if old_value != new_value
        @log << "- **#{tag}** id:#{id} name:#{current["name"]} #{key}:#{format_md(old_value)}=>#{format_md(new_value)}\n"
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
      @log << "- **station** new station #{format_md(station)}\n"
    end
    @lines.each_value do |line|
      @log << "- **line** new line #{format_md(line)}\n"
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
