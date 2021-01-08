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
IGNORE = [
  "code",
  "polyline_list",
]

class SubsetTest < Minitest::Test
  def setup()
    # load a new dataset
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

  def log(message)
    puts message
    @log << message
    @log << "\n"
  end

  def normalize_value(key, value, station_map)
    if key == "lines"
      # Array of Int
      return value.sort
    elsif key == "station_list"
      # code => id
      return value.map do |item|
               station_map[item["code"]]["id"]
             end
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
        log "- **#{tag}** id:#{id} name:#{current["name"]} #{key}:#{old_value}=>#{new_value}"
      end
    end
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

    # constrain: old dataset is a subset of new dataset
    # any station item in old dataset must also be included in new dataset

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
      log "- **station** new station #{format_md(station)}"
    end
    lines.each_value do |line|
      log "- **line** new line #{format_md(line)}"
    end
  end

  def test_subset
    # load whole data from
    data = read_json("artifact/extra.json")
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

  def teardown()
    File.open("artifact/diff.md", "w") { |f| f.write(@log) }
    File.open(".github/workflows/diff.md", "w") do |f|
      # python str::format で使用するtemplate
      f.write(@log.gsub("{", "{{").gsub("}", "}}"))
    end
  end
end
