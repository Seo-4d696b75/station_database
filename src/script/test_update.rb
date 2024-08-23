load('src/script/io.rb')
require 'minitest/autorun'
require 'optparse'

TEST_ARGV = ARGV.dup
ARGV.clear

# 異なるバージョンのデータセットを比較して差分を検出する
class SubsetTest < MiniTest::Test
  def setup
    @extra = false
    opt = OptionParser.new
    opt.on('-e', '--extra') { @extra = true }
    opt.parse!(TEST_ARGV)

    @old_dir = @extra ? 'artifact/extra' : 'artifact/main'
    @new_dir = @extra ? 'out/extra' : 'out/main'
    @log_file = @extra ? 'diff.extra.md' : 'diff.md'
    @log_title = @extra ? 'extraデータセットの差分' : 'mainデータセットの差分'

    # load a new dataset
    @stations = read_json "#{@new_dir}/station.json"
    @lines = read_json_lines(@new_dir, station_list: true, polyline: true)
    @log = {}
  end

  def check_diff(tag, old, current, fields)
    fields.each do |key|
      old_value = normalize_value key, old[key]
      new_value = normalize_value key, current[key]
      next unless old_value != new_value

      old_value = format_md old[key], key
      new_value = format_md current[key], key

      messages = @log[tag]
      unless messages
        messages = []
        @log[tag] = messages
      end
      messages << "#{key}: #{old_value}=>#{new_value}"
    end
  end

  def test_update
    # load old version data from
    @old_station_map = {}
    old_stations = read_json "#{@old_dir}/station.json"
    old_stations.each do |s|
      @old_station_map[s['id']] = s
      @old_station_map[s['code']] = s
    end
    old_lines = read_json_lines(@old_dir, station_list: true, polyline: true)

    # map of new stations and lines
    stations = {}
    lines = {}
    @stations.each { |s| stations[s['id']] = s }
    @lines.each { |l| lines[l['id']] = l }

    # constrain: old dataset is a subset of new dataset
    # any station item in old dataset must also be included in new dataset

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

    old_stations.each do |old|
      id = old['id']
      station = stations.delete(id)
      # extra　データセット固有の駅に関しては削除を許容する（一時的な対応）
      assert station || old['extra'], "新バージョンのデータセットに駅が見つかりません #{old['name']}"
      if station
        tag = {
          'name' => "変更: #{station['name']}(#{station['code']})",
          'type' => 'station'
        }
        check_diff tag, old, station, station_fields
      else
        tag = {
          'name' => "削除: #{old['name']}(#{old['code']})",
          'type' => 'station'
        }
        @log[tag] = nil
      end
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
      polyline
    ]

    old_lines.each do |old|
      id = old['id']
      line = lines.delete(id)
      assert line, "新バージョンのデータセットに路線が見つかりません #{old['name']}"
      tag = {
        'name' => "変更: #{line['name']}(#{line['code']})",
        'type' => 'line'
      }
      check_diff tag, old, line, line_fields
    end

    stations.each_value do |station|
      tag = {
        'name' => "追加: #{station['name']}(#{station['code']})",
        'type' => 'station'
      }
      @log[tag] = nil
    end
    lines.each_value do |line|
      tag = {
        'name' => "追加: #{line['name']}(#{line['code']})",
        'type' => 'line'
      }
      @log[tag] = nil
    end
  end

  def teardown
    log = "## #{@log_title}  \n\n"

    if @log.empty?
      log << "差分はありません  \n"
    else
      log << "<details><summary>#{@log.size}件の差分があります</summary>\n\n"
      line_log = @log.select { |tag, _| tag['type'] == 'line' }
      unless line_log.empty?
        log << "### 路線  \n"
        line_log.each do |tag, messages|
          log << "- #{tag['name']}  \n"
          messages&.each do |m|
            log << "  - #{m}  \n"
          end
        end
      end

      log << "\n\n"

      station_log = @log.select { |tag, _| tag['type'] == 'station' }
      unless station_log.empty?
        log << "### 駅  \n"
        station_log.each do |tag, messages|
          log << "- #{tag['name']}  \n"
          messages&.each do |m|
            log << "  - #{m}  \n"
          end
        end
      end
    end

    log << "</details>\n\n"

    File.open("artifact/#{@log_file}", 'w') { |f| f.write(log) }
  end

  # normalized given value so that comparison with "==" operator can be performed as expected.
  def normalize_value(key, value)
    if key == 'lines'
      # Array of Int
      value.sort
    elsif key == 'station_list'
      # code => id
      # Note: 駅名・駅コード等は変化するためidで確認する
      value.map do |item|
        id = item['id']
        n = item['numbering']
        d = { 'id' => id }
        d['numbering'] = n.join('/') if n
        d
      end
    else
      value
    end
  end

  def format_md(value, key)
    value = '`{..data..}`' if key == 'polyline'

    if key == 'station_list'
      value = value.map do |e|
        name = e['name']
        n = e['numbering']
        n ? "#{name}(#{n.join(',')})" : name
      end
    end

    if value.is_a?(Array) || value.is_a?(Hash)
      return "`#{JSON.dump(value)}`"
    elsif value.is_a?(Numeric) || value.is_a?(String) || value == true || value == false
      return value.to_s
    elsif value.nil?
      return 'null'
    end

    raise "unexpected type #{value} #{value.class}"
  end
end
