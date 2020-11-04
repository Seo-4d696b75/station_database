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

    @log = File.open("artifact/diff.md", "w")
    @log.puts("## detected diff from `master` branch  \n")
  end

  def check_diff(tag, id, old, current, fields)
    fields.each do |key|
      old_value = old[key]
      new_value = current[key]
      if old_value != new_value
        @log.puts("- **#{tag}** `id`:#{id} `name`:#{current["name"]} `#{key}`:#{old_value}=>#{new_value}")
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
      @log.puts("- **station** new station `#{JSON.dump(station)}`")
    end
    @lines.each_value do |line|
      @log.puts("- **line** new line `#{JSON.dump(line)}`")
    end
  end

  def teardown()
    @log.close
  end
end
