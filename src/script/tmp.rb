load("src/script/utils.rb")
require "minitest/autorun"

LINE_FIELD = [
  "code",
  "id",
  "name",
  "name_kana",
  "name_formal",
  "station_size",
  "company_code",
  "color",
  "symbol",
  "closed",
  "closed_date",
  "impl",
]

class TmpTest < Minitest::Test
  def setup()
    @lines = []
  end

  def test_line()
    csv_each_line("src/line.csv") do |fields|
      code = fields["code"].to_i
      id = read_value(fields, "id")
      name = read_value(fields, "name")
      name_kana = read_value(fields, "name_kana")
      name_formal = read_value(fields, "name_formal")
      station_size = fields["station_size"].to_i
      company_code = read_value(fields, "company_code")
      company_code = company_code.to_i if company_code
      color = read_value(fields, "color")
      symbol = read_value(fields, "symbol")
      closed = read_boolean(fields, "closed")
      impl = read_boolean(fields, "impl")
      closed_date = read_date(fields, "closed_date")

      path = "src/details/line/#{code}.json"
      data = read_json(path)
      assert_equal name, data["name"], "name mismatchd"
      if symbol && data["symbol"]
        assert_equal symbol, data["symbol"], "symbol mismatched"
      end
      if color && data["color"]
        assert_equal color, data["color"], "color mismatched"
      end
      list = data["station_list"]

      if c = select_one(list, "color")
        color = c if !color
        assert_equal color, c, "color???#{name}"
      end
      if s = select_one(list, "symbol")
        symbol = s if !symbol
        assert_equal symbol, s, "symbol??#{name}"
      end
      list.each do |r|
        parse_numbering(r, symbol)
      end
      data = {
        "name" => name,
        "station_list" => list,
      }
      File.open(path, "w") do |file|
        file.write(format_json(data, flat_array: ["station_list"]))
      end

      line = {}
      line["code"] = code
      line["id"] = id
      line["name"] = name
      line["name_kana"] = name_kana
      line["name_formal"] = name_formal
      line["station_size"] = station_size
      line["company_code"] = company_code
      line["color"] = color
      line["symbol"] = symbol
      line["closed"] = closed
      line["impl"] = impl
      line["closed_date"] = closed_date

      @lines << line
    end
    write_csv("src/line.csv", LINE_FIELD, @lines)
  end

  def teardown()
  end
end

def select_one(list, key)
  s = list.map { |r| r["numbering"] }.compact
  if s.length == list.length
    s = s.flatten.map { |r| r[key] }.compact
    if s.length == list.length
      s = s.uniq
      if s.length == 1
        return s[0]
      end
    end
  end
  nil
end

def parse_numbering(s, line_symbol = nil)
  if s.key?("numbering")
    s["numbering"].map! do |n|
      value = ""
      if n.key?("symbol")
        value << n["symbol"]
      elsif line_symbol
        value << line_symbol
      end
      value << n["index"]
      next value
    end
  end
end
