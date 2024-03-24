load('src/script/io.rb')
require 'minitest/autorun'

# mainデータセットの駅・路線がextraデータセットのサブセットか確認する
#  駅： out/*/station.json
#  路線： out/*/line.json
class SubsetTest < MiniTest::Test
  def setup
    # mainデータセットの読み込み
    @stations = read_json 'out/main/station.json'
    @station_map = {}
    @stations.each do |s|
      @station_map[s['id']] = s
      @station_map[s['code']] = s
    end
    @lines = read_json_lines('out/main', station_list: true)
  end

  def check_equal(main, extra, fields)
    fields.each do |key|
      main_value = main[key]
      extra_value = extra[key]
      if !main_value.nil? && !extra_value.nil?
        case key
        when 'lines'
          is_subset(main_value, extra_value, extra)
        when 'station_size'
          assert main_value <= extra_value, "登録駅数に不整合があります extra:#{extra_value} update:#{JSON.dump(main)}"
        when 'station_list'
          is_subset(main_value, extra_value, extra)
        else
          # その他のfieldは完全な等価性を要求する
          assert_equal main_value, extra_value, "値が一致しません name:#{main['name']} key:#{key}"
        end
      else
        # 両方nullのみ許可する
        assert !main_value && !extra_value,
               "値が欠損しています key:#{key} main:#{main_value} extra:#{extra_value} name:#{main['name']}"
      end
    end
  end

  def is_subset(child, parent, data)
    child.each do |item|
      assert parent.include?(item), "Listがサブセットではありません \nitem:#{item}\nparent:#{parent} \n@#{JSON.dump(data)}"
    end
  end

  def test_subset
    # extraデータセットを読み込み
    stations = {}
    lines = {}
    read_json('out/extra/station.json').each do |s|
      stations[s['id']] = s
    end
    read_json_lines('out/extra', station_list: true).each do |l|
      lines[l['id']] = l
    end

    # "voronoi" は他の駅の座標点が変化すると影響を受けるため無視する
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
      lines
      attr
      postal_code
      address
      open_date
      closed_date
      extra
    ]
    @stations.each do |s|
      assert !s['extra'], "mainデータセットにextra駅は含みません #{JSON.dump(s)}"
      station = stations.delete(s['id'])
      assert station, "extraデータセットに駅が見つかりません main:#{JSON.dump(s)}"
      assert !station['extra'], "mainデータセットに含まれる駅はextraデータセットでもextra=falseです #{JSON.dump(station)}"
      check_equal s, station, station_fields
    end

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
      closed_date
      station_list
      extra
    ]
    @lines.each do |l|
      assert !l['extra'], "mainデータセットにextra路線は含みません #{l['name']}"
      line = lines.delete(l['id'])
      assert line, "extraデータセットに路線が見つかりません main:#{l['name']}"
      assert !line['extra'], "mainデータセットにextra路線は含みません #{line['name']}"
      check_equal l, line, line_fields
    end

    stations.each_value do |s|
      assert s['extra'], "extraデータセットに追加できる駅はextra=trueです #{JSON.dump(s)}"
    end
    lines.each_value do |l|
      assert l['extra'], "extraデータセットに追加できる路線はextra=trueです #{JSON.dump(l)}"
    end
  end
end
