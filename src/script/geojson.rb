load("src/script/utils.rb")

def check_feature(data)
  return false if data["type"] != "Feature"
  return false if !data["properties"].kind_of?(Hash)
  check_geometry(data["geometry"])
end

def check_feature_collection(data)
  return false if data["type"] != "FeatureCollection"
  f = data["features"]
  return false if !f.kind_of?(Array)
  f.each do |e|
    return false if !check_feature(e)
  end
  true
end

def check_geometry(data)
  case data["type"]
  when "LineString"
    return check_polyline(data)
  when "Polygon"
    return check_polygon(data)
  else
    puts "unknown geometory type:#{data["type"]}"
    return false
  end
  true
end

def check_polyline(data)
  data["coordinates"].each do |p|
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
      return false if !check_point(p)
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
