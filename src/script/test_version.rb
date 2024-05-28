require 'minitest/autorun'
require 'dotenv'

# データセットのバージョン指定を確認する
class VersionTest < Minitest::Test
  def test_version
    old_version = Dotenv.parse('artifact/.env')['VERSION'].to_i
    new_version = Dotenv.parse('src/.env')['VERSION'].to_i
    assert old_version, '旧バージョンが不明です'
    assert new_version, '新バージョンが不明です'
    assert_operator new_version, :>, old_version, 'バージョンの不整合'
    puts "バージョン #{old_version} > #{new_version}"
  end
end
