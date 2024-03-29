load("src/script/utils.rb")
require "minitest/autorun"
require "set"

def parse_segment(data)
  start = data["start"]
  fin = data["end"]
  east = -180
  west = 180
  north = -90
  south = 90
  # 重複防止 & 小数点以下桁数調整
  previous = nil
  data["points"].select! do |pos|
    next false if previous == pos
    previous = pos
    next true
  end
  data["points"].map! do |pos|
    {
      "lat" => pos["lat"].round(5),
      "lng" => pos["lng"].round(5),
    }
  end
  data["points"].each do |pos|
    east = [east, pos["lng"]].max
    west = [west, pos["lng"]].min
    north = [north, pos["lat"]].max
    south = [south, pos["lat"]].min
  end
  return [data, east, west, north, south]
end

def parse_polyline(data)
  east = -180
  west = 180
  north = -90
  south = 90
  data["point_list"].map! do |item|
    item, e, w, n, s = parse_segment(item)
    east = [east, e].max
    west = [west, w].min
    north = [north, n].max
    south = [south, s].min
    next item
  end
  data["east"] = east
  data["west"] = west
  data["north"] = north
  data["south"] = south
  return data
end

def format_polyline(data)
  f = data["point_list"].map do |value|
    p = value["points"].map do |e|
      [e["lng"].round(5), e["lat"].round(5)]
    end
    d = {
      "type" => "Feature",
      "geometry" => {
        "type" => "LineString",
        "coordinates" => p,
      },
      "properties" => {
        "start" => value["start"],
        "end" => value["end"],
      },
    }
    d["properties"]["closed"] = true if !!value["closed"]
    next d
  end
  {
    "type" => "FeatureCollection",
    "features" => f,
    "properties" => {
      "name" => data["name"],
      "north" => data["north"],
      "south" => data["south"],
      "east" => data["east"],
      "west" => data["west"],
    },
  }
end

CUSTOM_ARGV = ARGV.clone
ARGV.clear

class PolylineTest < Minitest::Test
  def setup()
    @lines = read_json("build/line.extra.json")
    puts "list size: #{@lines.length}"
  end
  
  def test_polyline()
    @lines.each do |line|
      code = line["code"].to_i
      src = "src/polyline/#{code}.json"
      dst = "build/polyline/#{code}.json"
      if File.exists?(src)
        time = File::Stat.new(src).mtime
        time = Time.at(time.to_i)
        puts "#{line["code"]} #{line["name"]}"
        check_polyline(line, src, dst)
      else
        close = !!line["closed"]
        impl = !line.key?("impl") || !!line["impl"]
        assert close || !impl, "file not found line:#{JSON.dump(line)}"
      end
    end
  end
  
  def check_polyline(line, src, dst)
    data = parse_polyline(read_json(src))
    @point_map = Hash.new
    assert_equal line["name"], data["name"], "name mismatch! src:#{src} name:#{JSON.dump(line)}"
    data["point_list"].each do |item|
      check_point(item["start"], item["points"][0])
      check_point(item["end"], item["points"][-1])
    end
    queue = []
    history = Set.new
    list = data["point_list"].clone
    queue << list[0]["start"]
    history.add(list[0]["start"])
    while queue.length > 0
      tag = queue.shift
      list = list.delete_if do |item|
        next true if item["end"] == item["start"]
        if item["start"] == tag
          queue << item["end"] if history.add?(item["end"])
          next true
        end
        if item["end"] == tag
          queue << item["start"] if history.add?(item["start"])
          next true
        end
        next false
      end
    end
    assert list.length == 0, "polyline not enclosed. src:#{src} segment:#{JSON.dump(list[0])}"
    File.open(dst, "w") do |file|
      file.write(format_json(format_polyline(data), flat_key: ["coordinates"]))
    end
  end
  
  def check_point(tag, pos)
    if @point_map.key?(tag)
      assert_equal pos, @point_map[tag], "point mismatch tag:#{tag}"
    else
      @point_map[tag] = pos
    end
  end
end
