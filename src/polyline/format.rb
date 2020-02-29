require 'json'
Encoding.default_external = "utf-8"
REGEX_GROUP = /<coordinates>(.+?)<\/coordinates>/m
REGEX_ITEM = /([0-9\.]+),([0-9\.]+),0/

class Point
   attr_reader:lon, :lat
  def initialize(lon,lat)
    @lon = lon
    @lat = lat
  end
  def to_s()
    return "{\"lon\":%.6f,\"lat\":%.6f}" % [@lon, @lat]
  end
end

class Station
  attr_reader:code, :lat, :lon
  def initialize(data)
    o = JSON.parse(data)
    @lon = o["lon"].to_f
    @lat = o["lat"].to_f
    @code = o["code"]
  end
  
  def measure(point)
    return (point.lon-lon)**2 + (point.lat-lat)**2
  end
  def to_s()
    return "{\"station\":%d}" % @code
  end
end


def solve(path,list_path)
  str = ""
  File.open(path, "r:utf-8") do |file|
    file.each_line do |line|
      str += line
    end
  end
  stations = []
  File.open(list_path, "r:utf-8") do |file|
    file.each_line do |line|
      stations.push(Station.new(line))
    end
  end
  if m = str.match(REGEX_GROUP)
    points = []
    puts "---------------------------"
    m = m[1].match(REGEX_ITEM)
    while m!=nil
      p = Point.new(m[1].to_f,m[2].to_f)
      puts "%.6f,%.6f" % [p.lat, p.lon]
      points.push(p)
      m = m.post_match.match(REGEX_ITEM)
    end
    puts "-----------------------------"
    while !stations.empty?
      s = stations.delete_at(0)
      list = points.sort{|e1,e2| s.measure(e1) <=> s.measure(e2)}
      i = [points.index(list[0]), points.index(list[1])].max
      points[i] = s
    end
    points.each{|e| "  " + puts e.to_s + ","}
    return nil
  else
    puts "no coordinates group found."
  end
end