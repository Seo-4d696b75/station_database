require "json"
number = ARGV[0]
data = File.read("../polyline/raw/#{number}.json")
src = JSON.parse(data)

def convert_coordinate(lat, lng)
  glat = lat - 0.00010695 * lat + 0.000017464 * lng + 0.0046017
  glng = lng - 0.000046038 * lat - 0.000083043 * lng + 0.010040
  [glat, glng]
end

src["point_list"].map! do |segment|
  segment["points"].map! do |coordinates|
    lat = coordinates["lat"]
    lng = coordinates["lng"]
    lat, lng = convert_coordinate(lat, lng)
    { "lat" => lat, "lng" => lng }
  end
  segment
end

txt = "#{src["name"]}\n\n"
txt << src["point_list"].map do |seg|
  tmp = "#{seg["start"]},#{seg["end"]}\n"
  tmp << seg["points"].map do |pos|
    "#{pos["lat"]},#{pos["lng"]}"
  end.join("\n")
  tmp
end.join("\n\n")
File.write("./polyline.txt", txt)
