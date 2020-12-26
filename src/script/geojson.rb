load("src/script/utils.rb")

def check_feature(data)
  return false if data["type"] != "Feature"
  return false if data["properties"].kind_of?(Hash)
  check_geometry(data["geometry"])
end

def check_geometry(data)
  case data["type"]
  when "LineString"
    return check_line(data)
  when "Polygon"
    return check_polygon(data)
  else
    puts "unknown geometory type:#{data["type"]}"
    return false
  end
end

def check_line(data)
  data["coordinated"].each do |p|
    return false if !check_point(p)
  end
  return true
end

def check_polygon(data)
  coord = data["coordinates"]
  # assume a single ring
  return false if coord.length != 1
  coord.each do |ring|
    ring.each do |p|
      return false if !check_polygon(p)
    end
    return false if ring[0] != ring[-1]
  end
  true
end

def check_point(p)
  return false if !p.kind_of?(Array)
  return false if p.length != 2
  return false if !p[0].kind_of?(Float)
  return false if !p[1].kind_of?(Float)
  return true
end
