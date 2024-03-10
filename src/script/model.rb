# frozen_string_literal: true

load('src/script/utils.rb')

# Hash wrapper for Station model
class Station
  CSV_FILEDS = %w[
    code
    id
    name
    original_name
    name_kana
    lat
    lng
    prefecture
    postal_code
    address
    closed
    open_date
    closed_date
    extra
    attr
  ].freeze

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

  def self.csv_fields(extra)
    fields = CSV_FILEDS.dup
    fields.delete('extra') unless extra
    fields
  end

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
