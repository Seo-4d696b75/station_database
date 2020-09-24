require "minitest/autorun"

class CalcTest < Minitest::Test
  def test_add
    assert_equal 2, 1 + 1
  end

  def test_sub
    assert_equal 2 - 1, 2, "subtraction"
  end
end
