load("../script/utils.rb")

class KMLParser
  def initialize(data)
    @data = data
  end

  def parse()
    @lines = []
    @stations = []
    @data.map { |e| e["features"] }.flatten.each do |e|
      if e["type"] != "Feature"
        puts "unknown type #{e["type"]}"
        exit(0)
      end
      parse_feature(e)
    end

    File.open("station.csv", "a") do |file|
      @stations.each { |str| file.puts(str) }
    end
    data = {
      "name" => "",
      "origin" => "www.pcpulab.mydns.jp",
      "point_list" => @lines,
    }
    File.open("polyline.json", "w") do |file|
      file.puts(format_json(data, flat_array: ["points"]))
    end
    File.open("polyline.txt", "w") do |file|
      @lines.each do |line|
        file.puts "#{line["start"]} #{line["end"]}"
        line["points"].each do |pos|
          file.puts "#{pos["lat"]},#{pos["lng"]}"
        end
        file.puts ""
      end
    end
  end

  def parse_feature(data)
    prop = data["properties"]
    if prop.key?("駅名")
      parse_station(data)
    else
      parse_polyline(data)
    end
  end

  def parse_polyline(data)
    geo = data["geometry"]
    prop = data["properties"]
    if geo["type"] != "LineString"
      puts "unknown polyline type"
      exit(0)
    end
    points = geo["coordinates"].map do |e|
      parse_coordinate(e)
    end
    @lines << {
      "start" => prop["路線名"],
      "end" => prop["区間"],
      "points" => points,
    }
  end

  def parse_point(data)
    geo = data["geometry"]
    if geo["type"] != "Point"
      puts "unknonw point #{JSON.dump(data)}"
      exit(0)
    end
    return parse_coordinate(geo["coordinates"])
  end

  def parse_station(data)
    prop = data["properties"]
    name = prop["駅名"]
    if m = name.match(/<a .+?>(.+?)<\/a>/)
      name = m[1]
    end
    if m = name.match(/^(.+?)駅.?/)
      name = m[1]
    end
    pos = parse_point(data)
    @stations << ",NULL,#{name},#{name},,#{pos["lat"].fixed(6)},#{pos["lng"].fixed(6)}"
  end

  def parse_coordinate(data)
    if data.kind_of?(Array) && data.length >= 2
      if data[0] > 100 && data[1] < 50
        return { "lat" => data[1], "lng" => data[0] }
      end
    end
    puts "unknown coordinate #{JSON.dump(data)}"
    exit(0)
  end
end

KMLParser.new(read_json("kml.json")).parse
