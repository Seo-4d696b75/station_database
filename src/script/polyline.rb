load("src/script/utils.rb")
require "minitest/autorun"
require "set"
require "optparse"
require "fileutils"
require "time"

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
  if cnt > data["points"].length
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
        s["lat"] = pivot["lat"].round(5)
        s["lng"] = pivot["lng"].round(5)
        previous = pivot
        s["delta_lat"] = []
        s["delta_lng"] = []
        value["points"].each do |pos|
          s["delta_lat"] << ((pos["lat"].round(5) - previous["lat"].round(5)) * scale).round
          s["delta_lng"] << ((pos["lng"].round(5) - previous["lng"].round(5)) * scale).round
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

    opt = OptionParser.new
    opt.on("-a") { |v| @check_all = v }
    opt.on("-l VAL") { |v| @code = v.to_i }
    opt.parse!(ARGV)

    puts "check_all", !!@check_all

    @checked = {}
    @history_path = "src/polyline/.history"
    FileUtils.remove(@history_path) if @check_all
    if File.exists?(@history_path)
      File.open(@history_path, "r") do |file|
        file.each_line do |line|
          values = line.chomp.split(",")
          next if values.length != 2
          time = Time.parse(values[1])
          code = values[0].to_i
          @checked[code] = time
        end
      end
    end
  end

  def test_polyline()
    begin
      @lines.each do |line|
        code = line["code"].to_i
        src = "src/polyline/raw/#{code}.json"
        dst = "src/polyline/solved/#{code}.json"
        if File.exists?(src)
          time = File::Stat.new(src).mtime
          time = Time.at(time.to_i)
          if !@checked.key?(code) || time > @checked[code]
            print "\r#{line["code"]} #{line["name"]}"
            check_polyline(line, src, dst)
          end
          @checked[code] = time
        else
          close = !!line["closed"]
          impl = !line.key?("impl") || !!line["impl"]
          assert close || !impl, "file not found line:#{JSON.dump(line)}"
        end
      end
    rescue => exception
      puts exception
    ensure
      write_history
    end
  end

  def write_history()
    File.open(@history_path, "w") do |file|
      @checked.each do |key, value|
        file.puts("#{key},#{value.to_s}")
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
