load("src/script/utils.rb")
load("src/script/diff.rb")
require "minitest/autorun"
require "optparse"

opt = OptionParser.new
opt.on("-m", "--main VALUE") { |v| MAIN_FILE = v }
opt.on("-e", "--extra VALUE") { |v| EXTRA_FILE = v }
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
]

# these fields are ignored when checking differenct between "update" and "master"
IGNORE = []

class SubsetTest < MiniTest::Test
  def setup()
    # load main dataset
    data = read_json(MAIN_FILE)
    @version = data["version"]
    @stations = data["stations"]
    @station_map = Hash.new
    @stations.each do |s|
      @station_map[s["id"]] = s
      @station_map[s["code"]] = s
    end
    @lines = data["lines"]
  end

  def check_equal(update, extra, fields)
    fields.each do |key|
      update_value = update[key]
      extra_value = extra[key]
      if update_value && extra_value
        case key
        when "lines"
          is_subset(update_value, extra_value, extra)
        when "station_size"
          assert update_value <= extra_value, "station_size extra:#{extra_value} update:#{JSON.dump(update)}"
        when "station_list"
          is_subset(update_value, extra_value, extra)
        else
          # other fields must be completely matched
          assert_equal update_value, extra_value, "not equal name:#{update["name"]} key:#{key}"
        end
      else
        # it is ok that both of them are nil
        assert !update_value && !extra_value, "lack of field(#{key}) update:#{update_value} extra:#{extra_value} name:#{update["name"]}"
      end
    end
  end

  def is_subset(child, parent, data)
    child.each do |item|
      assert parent.include?(item), "array not subset. child:#{child} parent:#{parent} @#{JSON.dump(data)}"
    end
  end

  def test_subset
    # load extra data from
    data = read_json(EXTRA_FILE)
    assert_equal data["version"], @version, "version err"

    # constrain: "IMPL" dataset is a subset of "extra" dataset
    # all the fields of each station item are same or in relationship of sebset.

    # map of superset
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
    end
    @lines.each do |l|
      assert l.fetch("impl", true), "not impl #{l["name"]} at update"
      line = lines.delete(l["id"])
      assert line, "station not found, but in subset:#{l["name"]}"
      assert line.fetch("impl", true), "not impl #{line["name"]} at extra"
      check_equal(l, line, LINE_FIELD)
    end
    # remain item must be "impl" == false
    stations.each do |id, s|
      assert !s.fetch("impl", true), "impl station #{JSON.dump(s)} not included in update"
    end
    lines.each do |id, l|
      assert !l.fetch("impl", true), "impl line #{JSON.dump(l)} not include in update"
    end
  end
end
