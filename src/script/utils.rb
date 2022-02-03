require "json"
require "set"
require "securerandom"

Encoding.default_external = "UTF-8"

PATTERN_ID = /^[0-9a-f]{6}$/
PATTERN_KANA = /^[\p{hiragana}ー・\p{P}\s]+$/
PATTERN_POST = /^[0-9]{3}-[0-9]{4}$/
PATTERN_DATE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
PATTERN_COLOR = /^#[0-9A-F]{6}$/

class Float
  def fixed(digit)
    format = "%%.%df" % digit
    return format % self.round(digit)
  end
end

def read(path)
  str = ""
  File.open(path, "r:utf-8") do |file|
    file.each_line do |line|
      str << line
    end
  end
  return str
end

def read_json(path)
  str = ""
  File.open(path, "r:utf-8") do |file|
    file.each_line do |line|
      str << line
    end
  end
  return JSON.parse(str)
end

def flatten_data(obj, list)
  if children = obj["data"]
    children.each { |child| flatten_data(child, list) }
  else
    list << obj
  end
end

def read_data(path)
  root = read_json(path)
  list = []
  flatten_data(root, list)
  return list
end

class IDSet
  def initialize
    @id = Set.new
  end

  def add?(e)
    id = nil
    id = e if e.kind_of?(String)
    id = e["id"] if e.kind_of?(Hash)
    if id
      if id.match(/[0-9a-f]{6}/)
        if @id.add?(id)
          return true
        else
          puts "Error > id:#{id} duplicated  item:#{e}"
        end
      else
        puts "Error > invalid id item:#{e}"
      end
    else
      puts "Error > no id item:#{e}"
    end
    return false
  end

  def get
    while true
      id = SecureRandom.hex(3)
      if @id.add?(id)
        return id
      end
    end
  end
end

def format_json_obj(obj, flat: false, flat_key: [], flat_array: [], depth: 0)
  str = "{"
  str << "\n" + ("  " * (depth + 1)) if !flat
  sep = flat ? "," : ",\n" + ("  " * (depth + 1))
  str << obj.to_a.map do |e|
    key, value = e
    value = format_json_value(
      key, value,
      flat: flat,
      flat_key: flat_key,
      flat_array: flat_array,
      depth: depth + 1,
    )
    value = "\"#{key}\":#{value}"
  end.join(sep)
  str << "\n" + ("  " * depth) if !flat
  str << "}"
  str
end

def format_json_array(array, flat: false, flat_element: false, flat_key: [], flat_array: [], depth: 0)
  str = "["
  str << "\n" + ("  " * (depth + 1)) if !flat
  sep = flat ? "," : ",\n" + ("  " * (depth + 1))
  str << array.map do |value|
    format_json_value(
      nil, value,
      flat: flat || flat_element,
      flat_key: flat_key,
      flat_array: flat_array,
      depth: (depth + 1),
    )
  end.join(sep)
  str << "\n" + ("  " * depth) if !flat
  str << "]"
  return str
end

def format_json_value(key, value, flat: false, flat_key: [], flat_array: [], depth: 0)
  case true
  when value.kind_of?(String)
    return "\"#{value.to_s}\""
  when value.kind_of?(Integer) || value == true || value == false
    return value.to_s
  when value == nil
    return "null"
  when value.kind_of?(Hash)
    return format_json_obj(
             value,
             flat: flat || flat_key.include?(key),
             flat_key: flat_key,
             flat_array: flat_array,
             depth: depth,
           )
  when value.kind_of?(Array)
    return format_json_array(
             value,
             flat: flat || flat_key.include?(key),
             flat_element: flat_array.include?(key),
             flat_key: flat_key,
             flat_array: flat_array,
             depth: depth,
           )
  when value.kind_of?(Float) && (key == "lat" || key == "lng")
    # 座標値は小数点以下６桁までの有効数字
    return value.round(6)
  when value.kind_of?(Float)
    return value.to_s
  end
  raise "unexpected json value key:#{key} value:#{JSON.dump(value)}"
end

# JSON.dumpに代わるカスタムエンコーダー
#
# ルートになるオブジェクトは特別に`:root`をkeyとして扱う
# @param data 文字列に変換するオブジェクト
# @param flat_key Array<String|Symbol> 指定したkeyに対するjson objectは１行で出力
# @param flat_array Array<String|Symbol> 指定したkeyに対するArrayの各要素にあるjson objectを１行で出力
def format_json(data, flat_key: [], flat_array: [])
  format_json_value(
    :root, data,
    flat: flat_key.include?(:root),
    flat_key: flat_key,
    flat_array: flat_array,
    depth: 0,
  )
end

def sort_hash(data)
  keys = [
    "code",
    "left",
    "right",
    "segment",
    "id",
    "name",
    "original_name",
    "name_kana",
    "name_formal",
    "station_size",
    "company_code",
    "closed",
    "lat",
    "lng",
    "prefecture",
    "numbering",
    "lines",
    "color",
    "symbol",
    "station_list",
    "north",
    "south",
    "east",
    "west",
    "point_list",
    "attr",
    "postal_code",
    "address",
    "open_date",
    "closed_date",
    "next",
    "voronoi",
    "start",
    "end",
    "delta_lat",
    "delta_lng",
    "points",
  ]
  data.sort do |a, b|
    a = keys.find_index(a[0])
    b = keys.find_index(b[0])
    if a
      next b ? a <=> b : -1
    else
      next b ? 1 : 0
    end
  end.to_h
end

def write_csv(file, fields, records)
  File.open(file, "w:utf-8") do |file|
    file.puts(fields.join(","))
    records.each do |s|
      file.puts(fields.map do |f|
        value = s[f]
        value = "1" if value == true
        value = "0" if value == false
        value = "NULL" if value == nil
        # 座標値は小数点以下６桁までの有効数字
        value = ("%.06f" % value) if value.kind_of?(Float) && (f == "lat" || f == "lng")
        next value
      end.join(","))
    end
  end
end

$csv_no = -1
$csv_line = nil
$csv_file = nil

def csv_each_line(name)
  $csv_file = name
  File.open(name, "r:utf-8") do |file|
    header = []
    file.each_line.each_with_index do |line, i|
      $csv_no = i + 1
      if i == 0
        header = line.chomp.split(",")
        next
      end
      $csv_line = line
      line = line.chomp.split(",")
      csv_err("col size mismatch. #{line.length} <=> hader:#{header.length} ") if line.length != header.length
      data = {}
      header.each_with_index { |f, i| data[f] = line[i] }
      $csv_line = data
      yield(data)
    end
  end
end

def csv_err(mes)
  assert false, "#{mes} at csv file #{$csv_file}:#{$csv_no}\n#{$csv_line}"
end

def read_boolean(data, key)
  value = data[key]
  if value && value == "0"
    return false
  elsif value && value == "1"
    return true
  else
    csv_err("invalid '#{key} value")
    return nil
  end
end

def read_date(data, key)
  value = data[key]
  if value && value == "NULL"
    return nil
  elsif value && value.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)
    return value
  else
    csv_err("invalid '#{key}' value")
    return nil
  end
end

def read_value(data, key)
  value = data[key]
  if value && value == "NULL"
    return nil
  elsif value && value.length > 0
    return value
  else
    csv_err("empty '#{key}' value")
    return nil
  end
end
