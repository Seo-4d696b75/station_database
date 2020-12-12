load("../../script/utils.rb")

class DataParser
  def initialize(data)
    @data = data
  end

  def parse()
    @lines = []
    @stations = []
    @data["sectionLines"].each do |item|
      parse_polyline(item)
    end
    @data["stationLines"].each do |item|
      parse_station(item)
    end

    File.open("station.csv", "w") do |file|
      @stations.each { |str| file.puts(str) }
    end
    data = {
      "name" => "",
      "origin" => "rail-history.org",
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

  def parse_polyline(data)
    name = data["ROSEN_NAME"]
    points = data["curveLines"].map do |e|
      {
        "lat" => e["CURVE_LAT"].to_f,
        "lng" => e["CURVE_LNG"].to_f,
      }
    end
    @lines << {
      "start" => name,
      "end" => name,
      "points" => points,
    }
  end

  def parse_station(data)
    name = data["STATION_NAME"].to_s
    lat = data["POINT_LAT"].round(6)
    lng = data["POINT_LNG"].round(6)
    @stations << ",NULL,#{name},#{name},,#{lat.fixed(6)},#{lng.fixed(6)}"
  end
end

DataParser.new(read_json("data.json")).parse
