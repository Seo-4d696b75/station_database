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
  previous = nil
  cnt = 0
  data["points"].each do |pos|
    east = [east, pos["lng"]].max
    west = [west, pos["lng"]].min
    north = [north, pos["lat"]].max
    south = [south, pos["lat"]].min
    if previous
      cnt += 1 if previous["lat"] > pos["lat"]
      cnt += 1 if previous["lng"] > pos["lng"]
    end
    previous = pos
  end
  if cnt > data["points"].length / 2
    data["end"] = start
    data["start"] = fin
    data["points"].reverse!
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
  f = {}
  data.each do |key, value|
    if key == "point_list"
      value.map! do |value|
        s = {}
        scale = 100000
        pivot = value["points"][0]
        s["start"] = value["start"]
        s["end"] = value["end"]
        s["lat"] = pivot["lat"]
        s["lng"] = pivot["lng"]
        previous = pivot
        s["delta_lat"] = []
        s["delta_lng"] = []
        value["points"].each do |pos|
          s["delta_lat"] << (pos["lat"] * scale - previous["lat"] * scale).to_i
          s["delta_lng"] << (pos["lng"] * scale - previous["lng"] * scale).to_i
          previous = pos
        end
        next s
      end
    end
    f[key] = value
  end
  return f
end

class PolylineTest < Minitest::Test
  def setup()
    @lines = read_json("src/solved/line.json")
    puts "list size: #{@lines.length}"
  end

  def test_polyline()
    @lines.each do |line|
      code = line["code"].to_i
      src = "src/polyline/raw/#{code}.json"
      dst = "src/polyline/solved/#{code}.json"
      next if File.exists?(dst)
      if File.exists?(src)
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
      file.write(format_json(format_polyline(data), flat_array: ["point_list"]))
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
