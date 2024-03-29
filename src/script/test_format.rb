require "minitest/autorun"
load("src/script/format.rb")
require "optparse"

opt = OptionParser.new
opt.on("-s", "--src VALUE") { |v| SRC = v }
opt.parse!(ARGV)
ARGV.clear()

class CSVFormatTest < FormatTest
  def setup()
    data = read_json(SRC)
    @stations = data["stations"]
    @lines = data["lines"]
    self.check_init()
  end

  def test_all()
    self.check_station()
    self.check_line()
  end
end
