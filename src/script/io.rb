load('src/script/json.rb')
load('src/script/csv.rb')
load('src/script/polyline.rb')
require 'json'
require 'minitest'

# use assert outside minitest
include Minitest::Assertions
class << self
  attr_accessor :assertions
end
self.assertions = 0

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

def read_json_lines(dir, station_list: false, polyline: false)
  read_json("#{dir}/line.json").map do |line|
    if station_list
      detail = read_json "#{dir}/line/#{line['code']}.json"
      # 最低限の路線登録情報だけ確認する
      line['station_list'] = detail['station_list'].map do |r|
        {
          'id' => r['id'],
          'code' => r['code'],
          'name' => r['name'],
          'numbering' => r['numbering']
        }
      end
    end
    if polyline
      path = "#{dir}/polyline/#{line['code']}.json"
      line['polyline'] = read_json path if File.exist? path
    end
    line
  end
end

def read_csv_stations(path)
  list = []
  read_csv path do |fields|
    assert_equal fields.length, 15
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

    list << station
  end
  list
end

def read_csv_lines(path)
  list = []
  read_csv path do |fields|
    assert_equal fields.length, 12
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

# CSVを書き出す
class Array
  def write_station_csv(name, extra)
    fields = %w[
      code id name original_name name_kana lat lng prefecture postal_code address closed open_date closed_date extra attr
    ]
    fields.delete('extra') unless extra
    write_csv name, fields, self
  end

  def write_line_csv(name, extra)
    fields = %w[
      code id name name_kana name_formal station_size company_code color symbol closed closed_date extra
    ]
    fields.delete('extra') unless extra
    write_csv name, fields, self
  end

  def write_register_csv(name, extra)
    fields = %w[
      station_code line_code index numbering extra
    ]
    fields.delete('extra') unless extra
    write_csv name, fields, self
  end
end

# JSON Arrayを書き出す
class Array
  # 駅一覧
  def write_station_json(file, extra)
    fields = %w[
      code
      id
      name
      original_name
      name_kana
      closed
      lat
      lng
      prefecture
      lines
      attr
      postal_code
      address
      open_date
      closed_date
      voronoi
      extra
    ]
    array = map { |s| normalize_hash s, fields, extra }
    str = format_json(array, flat_array: [:root])
    File.write file, str
  end

  # 路線一覧
  def write_line_json(file, extra)
    fields = %w[
      code
      id
      name
      name_kana
      name_formal
      station_size
      company_code
      closed
      color
      symbol
      closed_date
      extra
    ]
    array = map { |l| normalize_hash l, fields, extra }
    str = format_json(array, flat_array: [:root])
    File.write file, str
  end

  # ドロネー分割
  def write_delaunay_json(file)
    fields = %w[
      code name lat lng next
    ]
    array = map { |n| normalize_hash n, fields, false }
    str = format_json(array, flat_array: [:root])
    File.write file, str
  end

  # 図形計算の入力（一時ファイル）
  def write_diagram_json(file)
    fields = %w[
      code name lat lng
    ]
    array = map { |n| normalize_hash n, fields, false }
    str = format_json(array, flat_array: [:root])
    File.write file, str
  end
end

# JSON Objectを書き出す
class Hash
  # 路線詳細
  def write_line_detail_json(file, extra)
    line_fields = %w[
      code
      id
      name
      name_kana
      name_formal
      station_size
      company_code
      closed
      color
      symbol
      station_list
      closed_date
      extra
    ]
    hash = normalize_hash self, line_fields, extra
    station_fields = %w[
      code
      id
      name
      original_name
      name_kana
      closed
      lat
      lng
      prefecture
      numbering
      lines
      attr
      postal_code
      address
      open_date
      closed_date
      voronoi
      extra
    ]
    hash['station_list'].map! do |s|
      normalize_hash s, station_fields, extra
    end
    str = format_json(hash, flat_array: ['station_list'])
    File.write file, str
  end

  # kd-tree（全体木）
  def write_tree_json(file)
    fields = %w[
      code
      name
      lat
      lng
      left
      right
    ]
    hash = {
      'root' => self['root'],
      'node_list' => self['node_list'].map { |n| normalize_hash n, fields, false }
    }
    str = format_json(hash, flat_array: ['node_list'])
    File.write file, str
  end

  # kd-tree（部分木）
  def write_tree_segment_json(file, extra)
    fields = %w[
      code
      id
      name
      original_name
      name_kana
      closed
      lat
      lng
      left
      right
      segment
      prefecture
      lines
      attr
      postal_code
      address
      open_date
      closed_date
      voronoi
      extra
    ]
    hash = {
      'name' => self['name'],
      'root' => self['root'],
      'node_list' => self['node_list'].map { |n| normalize_hash n, fields, extra }
    }
    str = format_json(hash, flat_array: ['node_list'])
    File.write file, str
  end

  # 路線ポリライン
  def write_polyline_json(file)
    f = self['point_list'].map do |value|
      p = value['points'].map do |e|
        [e['lng'].round(5), e['lat'].round(5)]
      end
      d = {
        'type' => 'Feature',
        'geometry' => {
          'type' => 'LineString',
          'coordinates' => p
        },
        'properties' => {
          'start' => value['start'],
          'end' => value['end']
        }
      }
      d['properties']['closed'] = true if value['closed']
      next d
    end
    hash = {
      'type' => 'FeatureCollection',
      'features' => f,
      'properties' => {
        'name' => self['name'],
        'north' => self['north'],
        'south' => self['south'],
        'east' => self['east'],
        'west' => self['west']
      }
    }
    str = format_json(hash, flat_key: ['coordinates'])
    File.write file, str
  end
end
