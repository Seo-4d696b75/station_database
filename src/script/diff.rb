# normalized given value so that comparison with "==" operator can be performed as expected.
def normalize_value(key, value, station_map)
  if key == "lines"
    # Array of Int
    return value.sort
  elsif key == "station_list"
    # code => id
    # Note: code of "same" station may be changed
    return value.map do |item|
             id = station_map[item["code"]]["id"]
             d = { "id" => id }
             if (n = item["numbering"]) && (!IGNORE || !IGNORE.include?("numbering"))
               d["numbering"] = n.join("/")
             end
             next d
           end
  else
    return value
  end
end

def format_md(value, key = nil, station_map = nil)
  if key == "polyline_list"
    return "`{..data..}`"
  elsif key == "station_list"
    value = value.map do |e|
      s = station_map[e["id"]]
      name = s["name"]
      if n = e["numbering"]
        next "#{name}(#{n})"
      else
        next name
      end
    end
  elsif key == "line" || key == "station"
    return "#{value["name"]}(#{value["code"]})"
  end
  if value.kind_of?(Array) || value.kind_of?(Hash)
    return "`#{JSON.dump(value)}`"
  elsif value.kind_of?(Numeric) || value.kind_of?(String) || value == true || value == false
    return value.to_s
  elsif value == nil
    return "null"
  end
  raise "unexpected type #{value} #{value.class}"
end
