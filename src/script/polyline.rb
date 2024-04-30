# validate polyline
#
# line: 路線情報
# polyline: src/polyline/*.json (custom format)
def validate_polyline(line, data)
  assert_equal line['name'], data['name'], "路線ポリラインの路線名が異なります: #{data['name']} vs #{JSON.dump(line)}"

  point_map = {}
  data['point_list'].each do |item|
    validate_point item['start'], item['points'][0], point_map
    validate_point item['end'], item['points'][-1], point_map

    # 重複確認
    previous = nil
    item['points'].each do |p|
      assert p != previous, "路線ポリラインの座標が重複しています #{p}@#{line['name']}(#{line['code']})"
      previous = p
    end
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
  assert list.empty?, "路線ポリラインの各セグメントが連結ではありません. line:#{data['name']} #{JSON.dump(list[0])}"
end

def validate_point(tag, pos, point_map)
  if point_map.key?(tag)
    assert_equal pos, point_map[tag], "路線ポリラインのセグメント末端の座標が一致しません tag:#{tag}"
  else
    point_map[tag] = pos
  end
end
