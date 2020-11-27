require "minitest/autorun"
load("src/script/format.rb")

class CSVFormatTest < FormatTest
  def setup()
    data = read_json("out/data.json")
    @stations = data["stations"]
    @lines = data["lines"]
    self.check_init()
  end

  def test_station()
    self.check_station()
  end

  def test_line()
    self.check_line()
  end
end
