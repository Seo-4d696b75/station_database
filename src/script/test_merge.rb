load("src/script/utils.rb")
require "minitest/autorun"

class MergeTest < Minitest::Test
  def setup()
    # load old version data from artifact
    data = read_json("artifact/data.json")
    @old_version = data["version"]
    @old_stations = data["stations"]
    @old_lines = data["lines"]
    data = read_json("out/data.json")
    @stations = Hash.new
    data["stations"].each { |s| @stations[s["id"]] = s }
    @lines = Hash.new
    data["lines"].each { |l| @lines[l["id"]] = l }

    @log = File.open("artifact/log.txt", "w")
  end

  def test_id
    @old_stations.each do |old|
      id = old["id"]
      station = @stations.delete(id)
      assert station, "station not found old:#{JSON.dump(old)}"
      if old["name"] != station["name"]
        @log.puts("[station] name changed. id:#{id} #{old["name"]}=>#{station["name"]}")
      end
      if old["code"] != station["code"]
        @log.puts("[station] code changed. id:#{id} name:#{station["name"]} #{old["code"]}=>#{station["code"]}")
      end
    end
    @old_lines.each do |old|
      id = old["id"]
      line = @lines.delete(id)
      assert line, "line not found old:#{JSON.dump(old)}"
      if old["name"] != line["name"]
        @log.puts("[line] name changed. id:#{id} #{old["name"]}=>#{line["name"]}")
      end
      if old["code"] != line["code"]
        @log.puts("[line] code changed. id:#{id} name:#{line["name"]} #{old["code"]}=>#{line["code"]}")
      end
    end
    @stations.each_value do |station|
      @log.puts("[station] new station added. #{JSON.dump(station)}")
    end
    @lines.each_value do |line|
      @log.puts("[line] new line added. #{JSON.dump(line)}")
    end
  end

  def teardown()
    @log.close
  end
end
