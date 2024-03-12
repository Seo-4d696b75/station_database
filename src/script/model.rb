# frozen_string_literal: true

load('src/script/json.rb')
load('src/script/csv.rb')
load('src/script/polyline.rb')

# Hash wrapper for Station model
class Station
  DIAGRAM_FIELDS = %w[
    code
    name
    lat
    lng
  ].freeze

  FIELDS = %w[
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
  ].freeze

  DETAIL_FIELDS = %w[
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
  ].freeze

  DELAUNAY_FIELDS = %w[
    code
    name
    lat
    lng
    next
  ].freeze

  TREE_FIELDS = %w[
    code
    name
    lat
    lng
    left
    right
  ].freeze

  TREE_SEGMENT_FIELDS = %w[
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
  ].freeze

  def initialize(hash)
    @hash = hash
  end

  def [](key)
    @hash[key]
  end

  def []=(key, value)
    @hash[key] = value
  end

  def merge!(hash)
    @hash.merge!(hash)
    self
  end

  def merge(hash)
    Station.new @hash.merge(hash)
  end

  def json(extra)
    normalize_hash @hash, FIELDS, extra
  end

  def detail_json(extra)
    normalize_hash @hash, DETAIL_FIELDS, extra
  end

  def delaunay_json
    normalize_hash @hash, DELAUNAY_FIELDS, false
  end

  def tree_json
    normalize_hash @hash, TREE_FIELDS, false
  end

  def tree_segment_json(extra)
    normalize_hash @hash, TREE_SEGMENT_FIELDS, extra
  end

  def diagram_json
    normalize_hash @hash, DIAGRAM_FIELDS, false
  end
end

# Hash wrapper for line model
class Line
  FIELDS = %w[
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
  ].freeze

  DETAIL_FIELDS = %w[
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
  ].freeze

  def initialize(hash)
    @hash = hash
  end

  def [](key)
    @hash[key]
  end

  def []=(key, value)
    @hash[key] = value
  end

  def json(extra)
    normalize_hash @hash, FIELDS, extra
  end

  def detail_json(extra)
    normalize_hash @hash, DETAIL_FIELDS, extra
  end

  def write_detail_json(file, extra)
    hash = detail_json(extra)
    hash['station_list'].map! { |s| s.detail_json extra }
    str = format_json(hash, flat_array: ['station_list'])
    File.write file, str
  end
end

class Array
  def write_json(file, extra)
    array = map { |e| e.json extra }
    str = format_json(array, flat_array: [:root])
    File.write file, str
  end

  def write_delaunay_json(file)
    array = map(&:delaunay_json)
    str = format_json(array, flat_array: [:root])
    File.write file, str
  end

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

# JSON Object other than Station, Line
class Hash
  def write_tree_json(file)
    hash = {
      'root' => self['root'],
      'node_list' => self['node_list'].map(&:tree_json)
    }
    str = format_json(hash, flat_array: ['node_list'])
    File.write file, str
  end

  def write_tree_segment_json(file, extra)
    hash = {
      'name' => self['name'],
      'root' => self['root'],
      'node_list' => self['node_list'].map { |n| n.tree_segment_json(extra) }
    }
    str = format_json(hash, flat_array: ['node_list'])
    File.write file, str
  end

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
