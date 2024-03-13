# src/**/* ファイルを入力としてデータ整合性の確認・データの自動補完を行います

load('src/script/io.rb')
load('src/script/geocoding.rb')
load('src/script/idset.rb')

puts 'reading station.csv line.csv'
station_list = read_csv_stations
line_list = read_csv_lines

puts 'checking station/line id'
ids = IDSet.new
(station_list + line_list).select { |s| s['id'] }.each do |s|
  assert ids.add?(s['id']), "id duplicated #{JSON.dump(s)}"
end
(station_list + line_list).reject { |s| s['id'] }.each do |s|
  s['id'] = ids.get
  puts "id added\n#{JSON.dump(s)}"
end

puts 'checking station/line code, name'
station_map = {}
line_map = {}
coordinates = Set.new
station_list.each do |s|
  assert !station_map.key?(s['code']), "駅コードが重複 #{JSON.dump(s)}"
  assert !station_map.key?(s['name']), "駅名が重複 #{JSON.dump(s)}"
  pos = [s['lng'], s['lat']]
  assert coordinates.add?(pos), "駅の緯度・経度が重複 #{JSON.dump(s)}"
  station_map[s['code']] = s
  station_map[s['name']] = s
end
line_list.each do |line|
  assert !line_map.key?(line['code']), "路線コードが重複 #{JSON.dump(line)}"
  assert !line_map.key?(line['name']), "路線名画重複 #{JSON.dump(line)}"
  line_map[line['code']] = line
  line_map[line['name']] = line
end

puts 'checking station address, postal_code'
station_list.each do |station|
  fetch_address(station) if !station['postal_code'] || !station['address']
end

# write csv file
station_list.write_station_csv 'src/station.csv', true
line_list.write_line_csv 'src/line.csv', true

puts 'checking line registration'

impl_size_map = {}
read_csv 'src/check/line.csv' do |fields|
  name = fields['name']
  size = fields['size'].to_i
  impl_size_map[name] = size
end

line_list.each do |line|
  # 路線の登録駅情報
  path = "src/line/#{line['code']}.json"
  assert File.exist?(path), "file:#{path} not found. line:#{JSON.dump(line)}"
  details = read_json path
  assert_equal line['name'], details['name'],
               "路線詳細の駅名が異なります #{details['name']} (#{line['code']}.json)"
  # 登録駅数の確認
  size = line['station_size']
  assert_equal size, details['station_list'].length, "路線詳細の登録駅数が異なります #{details['name']} (#{line['code']}.json)"
  # 登録駅の駅コード・駅名の変化があれば更新する
  write = false
  # 駅メモ登録駅数
  impl_size = 0
  details['station_list'].each do |r|
    station_code = r['code']
    station_name = r['name']
    # 駅の名前解決
    station = nil
    assert (station = station_map[station_name]) || (station = station_map[station_code]),
           "路線詳細の登録駅が見つかりません #{station_name}(#{station_code}) at #{details['name']} (#{line['code']}.json)"
    if station_code != station['code']
      # 駅名の重複なしのため駅名一致なら同値
      puts "路線登録駅のコードを自動修正します #{station_name}@#{line['name']}(#{line['code']}) #{station_code}=>#{station['code']}"
      r['code'] = station['code']
      write = true
    elsif station_name != station['name']
      # 駅名変更は慎重に
      print "路線登録駅の名称に変更があります #{station_code}@#{line['name']}(#{line['code']}) #{station_name}=>#{station['name']}"
      print ' OK? Y/N =>'
      assert gets.chomp.match(/^[yY]?$/), 'abort'
      r['name'] = station['name']
      write = true
    end

    # `extra`属性の曖昧性を解消
    # src/*.csv extra: 路線・駅自体のextra属性
    # src/line/*.json .station_list[].extra:
    #   路線(extra=true)における駅(extra=true)の登録のうち、
    #   駅メモ実装には含まれない登録のみextra=trueを指定している
    extra = station['extra'] || line['extra'] || r['extra']

    impl_size += 1 unless extra

    # 駅要素側にも登録路線を記憶
    station['lines'] << line['code']
  end

  # 駅メモ実装の登録駅数を確認
  if !line['extra']
    assert impl_size_map.key?(line['name']), "路線登録駅の確認数が見つかりません check/line.csv @#{line['name']}"
    assert_equal impl_size_map[line['name']], impl_size,
                 "路線詳細の登録駅数と確認駅数（check/line.csv）が異なります @#{line['name']}"
  else
    assert_equal 0, impl_size, "路線(extra)の登録駅はすべてextra=trueです @#{line['name']}"
  end

  next unless write

  # 更新あるなら駅登録詳細へ反映
  File.open(path, 'w:utf-8') do |f|
    f.write(format_json(details, flat_array: ['station_list']))
  end
end

puts 'checking polyline'
polyline_ignore = []
read_csv 'src/check/polyline_ignore.csv' do |line|
  polyline_ignore << line.str('name')
end
line_list.each do |line|
  path = "src/polyline/#{line['code']}.json"
  unless File.exist?(path)
    assert polyline_ignore.include?(line['name']),
           "路線ポリラインが見つかりません.欠損を許可する場合は src/check/polyline.csv への追加が必要です line:#{JSON.dump(line)}"
  end
end

pattern_id = /^[0-9a-f]{6}$/
pattern_kana = /^[\p{hiragana}ー・\p{P}\s]+$/
pattern_date = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
pattern_color = /^#[0-9A-F]{6}$/
pattern_post = /^[0-9]{3}-[0-9]{4}$/

puts 'checking station'
pref_cnt = Array.new(48, 0)
dup_name = Hash.new([])
station_list.each do |station|
  code = station['code']
  id = station['id']
  name = station['name']
  name_original = station['original_name']
  name_kana = station['name_kana']
  closed = !!station['closed']
  lng = station['lng']
  lat = station['lat']
  pref = station['prefecture']
  post = station['postal_code']
  address = station['address']
  attribute = station['attr']
  lines = station['lines']
  open_date = station['open_date']
  closed_date = station['closed_date']
  extra = !!station['extra']

  # check field value
  assert code && code.is_a?(Integer), "不正な駅コード #{JSON.dump(station)}"
  assert id && id.is_a?(String) && id.match(pattern_id), "不正なid #{JSON.dump(station)}"
  assert name && name.is_a?(String) && name.length.positive?, "不正な駅名 #{JSON.dump(station)}"
  if name_original.end_with?('駅', '停留所', '乗降場')
    names = lines.map { |c| line_map[c]['name'] }.join(',')
    puts "警告 > 駅名の末尾語が不適切な可能性があります:#{name_original} @ #{names}"
  end
  assert !name_original || (name_original.is_a?(String) && name_original.length.positive? && name.include?(name_original)),
         "不正な駅名称(original) #{JSON.dump(station)}"
  assert name_kana, "駅名（カナ）が見つかりません #{JSON.dump(station)}"
  assert name_kana.is_a?(String) && name_kana.match(pattern_kana), "不正な駅名（カナ） #{JSON.dump(station)}"
  assert lng && lng.is_a?(Float) && lat && lat.is_a?(Float), "駅座標の型が不正 #{JSON.dump(station)}"
  assert lng > 127.5 && lng < 146.2, "駅経度の値が範囲外 #{JSON.dump(station)}"
  assert lat > 26 && lat < 45.8, "駅緯度の値が範囲外 #{JSON.dump(station)}"
  assert pref && pref.is_a?(Integer) && pref.positive? && pref <= 47, "不正な都道府県コード #{JSON.dump(station)}"
  assert post && post.is_a?(String) && post.match(pattern_post), "郵便番号が不正 #{JSON.dump(station)}"
  assert address && address.is_a?(String) && address.length.positive?, "住所が不正 #{JSON.dump(station)}"
  assert extra || %w[eco heat cool unknown].include?(attribute), "不正な駅属性 #{JSON.dump(station)}"
  assert !extra || !attribute, "extra駅の駅属性はnullです #{JSON.dump(station)}"
  assert lines && lines.is_a?(Array) && lines.length.positive?, "登録路線が不正 #{JSON.dump(station)}"
  assert !open_date || open_date.match(pattern_date), "不正な開業日 #{JSON.dump(station)}"
  assert !closed_date || closed_date.match(pattern_date), "不正な廃止日 #{JSON.dump(station)}"
  assert open_date < closed_date, "開業日 < 廃止日 #{JSON.dump(station)}" if open_date && closed_date
  assert closed || !closed_date, "廃駅のみ廃止日を定義できます #{JSON.dump(station)}"

  # name and original_name
  dup_name[name_original] = [station, *dup_name[name_original]] if name != name_original

  # cnt in each prefecture
  pref_cnt[pref] += 1 unless extra

  # 'closed'
  assert extra || closed == (attribute == 'unknown'), "廃駅の駅属性はunknownです #{JSON.dump(station)}"
  # 'lines'
  assert lines.length.positive?, "少なくとも１つ以上の路線に登録される必要があります staion:#{JSON.dump(station)}"
  lines.each do |c|
    assert line_map.key?(c), "駅の登録路線が見つかりません 路線コード: #{code} #{JSON.dump(station)}"
  end
  assert closed || lines.map { |c| line_map[c] }.any? { |l| !l['closed'] },
         "現役駅は１つ以上の現役路線に登録される必要があります #{JSON.dump(station)}"
end

# check name duplication
dup_name.each do |key, value|
  s = station_map[key]
  if s
    assert !s['extra'] && value.all? { |v| v['extra'] },
           "駅メモ実装の駅名には重複無し & extra駅の追加で駅名が重複する場合のみ、重複防止の接尾語が省略できます: '#{key}'  #{JSON.dump(s)}"
    # may be value.length == 1
  else
    assert value.length > 1, "駅名とは異なる駅名(original)が登録されていますが重複がありません: '#{key}' #{JSON.dump(value[0])}"
  end
end

# check cnt in each pref.
read_csv 'src/check/prefecture.csv' do |fields|
  code = fields['code'].to_i
  name = fields['name']
  size = fields['size'].to_i
  assert_equal size, pref_cnt[code], "都道府県毎の駅数が異なります #{name}"
end

puts 'checking line'
line_list.each do |line|
  code = line['code']
  id = line['id']
  name = line['name']
  name_kana = line['name_kana']
  closed = !!line['closed']
  symbol = line['symbol']
  color = line['color']
  closed_date = line['closed_date']

  # check field value
  assert code && code.is_a?(Integer), "不正な路線コード #{name}"
  assert id && id.is_a?(String) && id.match(pattern_id), "不正な路線id #{name}"
  assert name && name.is_a?(String) && !name.empty?, "不正な路線名 #{name}"
  puts "警告 > 廃線の廃止日が未定義です #{name}" if closed && !closed_date
  assert name_kana && name_kana.is_a?(String) && name_kana.match(pattern_kana), "不正な路線名（カナ） #{name}"
  assert !symbol || (symbol.is_a?(String) && !symbol.empty?), "不正な路線シンボル #{name}"
  assert !color || (color.is_a?(String) && color.match(pattern_color)), "不正な路線カラー #{name}"

  # date
  assert !closed_date || closed_date.match(pattern_date), "不正な路線廃止日 #{name}"
  assert closed || !closed_date, "廃線のみ廃止日を定義できます #{name}"
end
