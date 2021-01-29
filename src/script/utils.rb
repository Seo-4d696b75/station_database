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

def format_json(data, flat_key: [], flat_array: [], flat: false, depth: 0)
  if data.kind_of?(String)
    return "\"#{data.to_s}\""
  elsif data.kind_of?(Numeric) || data == true || data == false
    return data.to_s
  elsif data.kind_of?(Hash)
    return JSON.dump(data) if flat
    str = "{\n"
    str << ("  " * (depth + 1))
    str << data.to_a.map do |e|
      key, value = e
      if value.kind_of?(Array)
        if flat_key.include?(key)
          next "\"#{key}\":#{JSON.dump(value)}"
        else
          value = format_json(
            value,
            flat_key: flat_key,
            flat_array: flat_array,
            flat: flat_array.include?(key),
            depth: (depth + 1),
          )
          next "\"#{key}\":#{value}"
        end
      end
      value = format_json(
        value,
        flat_key: flat_key,
        flat_array: flat_array,
        flat: flat_key.include?(key),
        depth: (depth + 1),
      )
      "\"#{key}\":#{value}"
    end.join(",\n" + ("  " * (depth + 1)))
    str << "\n"
    str << ("  " * depth)
    str << "}"
    return str
  elsif data.kind_of?(Array)
    str = "[\n"
    str << ("  " * (depth + 1))
    str << data.map do |value|
      format_json(
        value,
        flat_key: flat_key,
        flat_array: flat_array,
        flat: flat,
        depth: (depth + 1),
      )
    end.join(",\n" + ("  " * (depth + 1)))
    str << "\n"
    str << ("  " * depth)
    str << "]"
    return str
  else
    raise "invalid json data: " + data.to_s
  end
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
