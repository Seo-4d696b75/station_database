require 'parallel'

# validate polyline
#
# input: src/polyline/*.json (custom format)
def validate_polylines(lines)
  Parallel.each(lines, in_threads: 4) do |line|
    code = line['code'].to_i
    src = "src/polyline/#{code}.json"
    next unless File.exist?(src)

    data = parse_polyline(read_json(src))
    assert_equal line['name'], data['name'], "name mismatch! src:#{src} name:#{JSON.dump(line)}"

    point_map = {}
    data['point_list'].each do |item|
      check_point item['start'], item['points'][0], point_map
      check_point item['end'], item['points'][-1], point_map
    end

    # ポリラインの各セグメントが正しく連結されているか（互いに到達可能か）確認する
    queue = []
    history = Set.new
    list = data['point_list'].clone
    queue << list[0]['start']
    history.add(list[0]['start'])
    while queue.length.positive?
      tag = queue.shift
      list = list.delete_if do |item|
        # 一部環状線などはループのセグメントあり
        next true if item['end'] == item['start']

        if item['start'] == tag
          queue << item['end'] if history.add?(item['end'])
          next true
        end
        if item['end'] == tag
          queue << item['start'] if history.add?(item['start'])
          next true
        end
        next false
      end
    end
    assert list.empty?, "polyline not enclosed. src:#{src} segment:#{JSON.dump(list[0])}"
  end
end

def validate_point(tag, pos, point_map)
  if point_map.key?(tag)
    assert_equal pos, point_map[tag], "point mismatch tag:#{tag}"
  else
    point_map[tag] = pos
  end
end

def parse_segment(data)
  east = -180
  west = 180
  north = -90
  south = 90
  # 重複防止 & 小数点以下桁数調整
  previous = nil
  data['points'].select! do |pos|
    next false if previous == pos

    previous = pos
    next true
  end
  data['points'].map! do |pos|
    {
      'lat' => pos['lat'].round(5),
      'lng' => pos['lng'].round(5)
    }
  end
  data['points'].each do |pos|
    east = [east, pos['lng']].max
    west = [west, pos['lng']].min
    north = [north, pos['lat']].max
    south = [south, pos['lat']].min
  end
  [data, east, west, north, south]
end

def parse_polyline(data)
  east = -180
  west = 180
  north = -90
  south = 90
  data['point_list'].map! do |item|
    item, e, w, n, s = parse_segment(item)
    east = [east, e].max
    west = [west, w].min
    north = [north, n].max
    south = [south, s].min
    next item
  end
  data['east'] = east
  data['west'] = west
  data['north'] = north
  data['south'] = south
  data
end
