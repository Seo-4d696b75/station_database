load("../../script/utils.rb")
require "optparse"

def j2w(pos)
  phi = pos["lat"] * Math::PI / 180
  lambda = pos["lng"] * Math::PI / 180
  dx = -146.414
  dy = 507.337
  dz = 680.507
  a = 6377397.155
  f = 1 / 299.152813
  da = 6378137 - a
  df = 1 / 298.257223 - f
  e2 = 2 * f - f ** 2
  v = a / Math.sqrt(1 - e2 * Math.sin(phi) ** 2)
  rho = a * (1 - e2) / (1 - e2 * Math.sin(phi) ** 2) ** (1.5)
  dphi = (-dx * Math.sin(phi) * Math.cos(lambda) - dy * Math.sin(phi) * Math.sin(lambda) + dz * Math.cos(phi) + (f * da + a * df) * Math.sin(2 * phi)) / rho
  dlambda = (-dx * Math.sin(lambda) + dy * Math.cos(lambda)) / (v * Math.cos(phi))
  return {
           "lat" => ((phi + dphi) * 180 / Math::PI),
           "lng" => ((lambda + dlambda) * 180 / Math::PI),
         }
end

class DataParser
  def initialize(data)
    @data = data
  end

  def parse()
    opt = OptionParser.new
    @lat = 0
    @lng = 0
    opt.on("-j") { |v| @j = v }
    opt.on("--lat VAL") { |v| @lat = v.to_f }
    opt.on("--lng VAL") { |v| @lng = v.to_f }
    opt.parse!(ARGV)

    puts "lat:#{@lat} lng:#{@lng}"

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
      pos = {
        "lat" => e["CURVE_LAT"].to_f,
        "lng" => e["CURVE_LNG"].to_f,
      }
      convert_coordinate(pos)
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
    pos = convert_coordinate({ "lat" => lat, "lng" => lng })
    @stations << ",NULL,#{name},#{name},,#{pos["lat"].fixed(6)},#{pos["lng"].fixed(6)}"
  end

  def convert_coordinate(pos)
    pos = j2w(pos) if @j
    return {
             "lat" => (pos["lat"] + @lat).round(6),
             "lng" => (pos["lng"] + @lng).round(6),
           }
  end
end

DataParser.new(read_json("data.json")).parse
