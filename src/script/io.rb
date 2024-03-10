load('src/script/model.rb')
require 'json'

Encoding.default_external = 'UTF-8'

def read_json(path)
  str = ''
  File.open(path, 'r:utf-8') do |file|
    file.each_line do |line|
      str << line
    end
  end
  JSON.parse(str)
end

def read_csv_stations
  list = []
  csv_each_line 'src/station.csv' do |fields|
    csv_err('col size != 15') if fields.length != 15
    code = fields['code'].to_i
    id = fields.str('id')
    extra = fields.boolean('extra')

    name = fields.str('name')
    name_original = fields.str('original_name')
    name_kana = fields.str('name_kana')
    lat = fields['lat'].to_f
    lng = fields['lng'].to_f
    pref = fields['prefecture'].to_i
    closed = fields.boolean('closed')
    attr = fields.str('attr')
    postal_code = fields.str('postal_code')
    address = fields.str('address')
    station = {}
    station['code'] = code
    station['id'] = id
    station['name'] = name
    station['original_name'] = name_original
    station['name_kana'] = name_kana
    station['lat'] = lat
    station['lng'] = lng
    station['prefecture'] = pref
    station['attr'] = attr
    station['postal_code'] = postal_code
    station['address'] = address
    station['extra'] = extra
    station['closed'] = closed
    station['open_date'] = fields.date('open_date')
    station['closed_date'] = fields.date('closed_date')
    station['lines'] = []

    puts "Warning > may be invalid suffix of name:#{name_original}" if name_original.end_with?('駅', '停留所', '乗降場')

    list << Station.new(station)
  end
  list
end

def read_csv_lines
  list = []
  csv_each_line 'src/line.csv' do |fields|
    csv_err('fields size != 12') if fields.length != 12
    code = fields['code'].to_i
    id = fields.str('id')
    name = fields.str('name')
    name_kana = fields.str('name_kana')
    name_formal = fields.str('name_formal')
    station_size = fields['station_size'].to_i
    company_code = fields.str('company_code')
    company_code = company_code.to_i if company_code
    color = fields.str('color')
    symbol = fields.str('symbol')
    closed = fields.boolean('closed')
    extra = fields.boolean('extra')
    closed_date = fields.date('closed_date')

    puts "Warning > line closed date not defined #{name}" if closed && !closed_date

    line = {}
    line['code'] = code
    line['id'] = id
    line['name'] = name
    line['name_kana'] = name_kana
    line['name_formal'] = name_formal
    line['station_size'] = station_size
    line['company_code'] = company_code
    line['color'] = color
    line['symbol'] = symbol
    line['closed'] = closed
    line['extra'] = extra
    line['closed_date'] = closed_date

    list << line
  end
  list
end

def write_csv(file, fields, records)
  File.open(file, 'w:utf-8') do |file|
    file.puts(fields.join(','))
    records.each do |s|
      file.puts(fields.map do |f|
        value = s[f]
        value = '1' if value == true
        value = '0' if value == false
        value = 'NULL' if value.nil?
        # 座標値は小数点以下６桁までの有効数字
        value = format('%.06f', value.round(6)) if value.is_a?(Float) && %w[lat lng].include?(f)
        next value
      end.join(','))
    end
  end
end

$csv_no = -1
$csv_line = nil
$csv_file = nil

class CSVLine
  attr_reader :length

  def initialize(header, line)
    @length = line.length
    @data = {}
    @header = header
    header.each_with_index { |f, i| @data[f] = line[i] } if header
    line.each_with_index { |e, i| @data[i] = e }
  end

  def [](key)
    @data[key]
  end

  def []=(key, value)
    if key.is_a?(Integer)
      raise IndexError.new if key < 0 || key >= length

      @data[key] = value
      @data[@header[key]] = value if @header
    elsif key.is_a?(String)
      raise StandardError.new('header not set') unless @header

      idx = @header.index(key)
      raise IndexError.new('key not found in headers') unless idx
      raise IndexError.new if idx < 0 || idx >= length

      @data[idx] = value
      @data[key] = value
    else
      raise StandardError.new('invalid key type')
    end
  end

  def boolean(key)
    value = self[key]
    if value && value == '0'
      false
    elsif value && value == '1'
      true
    else
      csv_err("invalid '#{key} value")
      nil
    end
  end

  def date(key)
    value = self[key]
    if value && value == 'NULL'
      nil
    elsif value && value.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)
      value
    else
      csv_err("invalid '#{key}' value")
      nil
    end
  end

  def str(key)
    value = self[key]
    if value && value == 'NULL'
      nil
    elsif value && value.length > 0
      value
    else
      csv_err("empty '#{key}' value")
      nil
    end
  end
end

def csv_each_line(name, has_header = true)
  $csv_file = name
  File.open(name, 'r:utf-8') do |file|
    header = nil
    file.each_line.each_with_index do |line, i|
      $csv_no = i + 1
      if i == 0 && has_header
        header = line.chomp.split(',')
        next
      end
      $csv_line = line
      line = line.chomp.split(',')
      csv_err("col size mismatch. #{line.length} > hader:#{header.length} ") if header && line.length > header.length
      data = CSVLine.new(header, line)
      $csv_line = data
      yield(data)
    end
  end
end

def csv_err(mes)
  assert false, "#{mes} at csv file #{$csv_file}:#{$csv_no}\n#{$csv_line}"
end
