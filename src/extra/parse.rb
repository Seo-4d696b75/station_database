# テンプレートや内部リンクなどの構造がないプレーンなテキストを読む
def read_plane(str)
  # 強調マークアップの除去
  src = str
  dst = ""
  while m = src.match(/^(.*?)('{2,5})(.+?)('{2,5})/m)
    if (m[2].length == 2 || m[2].length == 3 || m[2].length == 5) && m[2].length == m[4].length
      dst += m[1]
      dst += m[3]
      src = m.post_match
    else
      dst += m[1]
      dst += m[2]
      src = m[3] + m[4] + m.post_match
    end
  end
  dst += src
  return dst
end



class Param
  attr_reader :key, :value
  # @param key 文字列 or Nil
  # @param value array 文字列またはWikiオブジェクトのリスト
  def initialize(key,value)
    @key = key
    @value = value
  end
  def to_s
    if @key
      return "#{@key} = #{@value.join}"
    else
      return @value.join
    end
  end
end

class WikiTemplate
  attr_reader :name, :params
  def initialize(name,params)
    @name = name
    @params = params
  end
  def to_s
    if @params.length > 0
      return "{{#{@name}|#{@params.join('|')}}}"
    else
      return "{{#{@name}}}"
    end
  end
  def name_include?(name)
    return @name.split(/\s+/).include?(name)
  end
  def get_param(key)
    param = nil
    if key.kind_of?(String)
      @params.each do |p|
        if p.key && p.key == key
          param = p
          break
        end
      end
    elsif key.kind_of?(Integer)
      param = @params[key]
    end
    if param
      param = param.value
      if param.length == 1
        param = param[0] 
      elsif param.length == 0
        param = nil
      end
    end
    return param
  end
end

class InternalLink
  attr_reader :name, :params
  def initialize(name,params)
    @name = name
    @params = params
  end
  # 内部リンクをどう文字列表現するか
  def to_s
    if @params.length > 0
      # 引数最後が表示文字列
      return @params[-1].to_s
    else
      return @name
    end
  end
end


# '|'で区切られた引数をひとつ読み出す
# @param str 検索対象の文字列. 次に出現する引数の区切り文字としての'|'まで進む
# @return array ['読み出された値','残りの文字列']
#               読み出しに失敗した場合は'読み出された値' = nil
#               '残りの文字列'は次に出現する引数の区切り文字としての'|'（存在するなら）を先頭に含む
def read_param(str)
  return [nil,str] if str[0] != '|'
  src = str[1..-1] 
  param_key = nil
  param_value = []
  # '=' を含む場合もある
  if m = src.match(/\A\s*([^\{\[\|\}\]]+?)\s*=\s*/m)
    param_key = m[1]
    src = m.post_match
  end
  # テンプレート引数の区切文字'|'を探すが、
  # 引数に含まれる別テンプレートや内部リンクに由来する'|'と区別すること
  while true
    if m = src.match(/\A([^\|\[\]\{\}]*)\{\{/m)
      # テンプレートは入れ子の場合がある
      param_value << read_plane(m[1]) if m[1].length > 0
      t, src = read_template(m.post_match)
      param_value << t
    elsif m = src.match(/\A([^\|\[\]\{\}]*)\[\[/m)
      # 内部リンク内は入れ子がないと仮定
      param_value << read_plane(m[1]) if m[1].length > 0
      link, src = read_internal_link(m.post_match)
      param_value << link
    else
      break
    end
  end
  m = src.match(/\A([^\|\[\]\{\}]*?)\s*(\||\]\]|\}\})/m)
  param_value << read_plane(m[1]) if m[1].length > 0
  return [Param.new(param_key,param_value), m[2] + m.post_match]
end


# テンプレートを読み出す
# @param str 検索対象
# @return array [WikiTemplate,'残りの文字列']
def read_template(str)
  return [nil,str] if !str
  src = str
  src = src[2..-1] if src[0..1] == "{{"
  if m = src.match(/\A(.+?)\s*(\||\}\})/m)
    # テンプレート名の抽出
    name = m[1]
    src = m[2] + m.post_match
    params = []
    while true
      param, src = read_param(src)
      break if !param
      params << param
    end
    if src[0..1] == "}}"
      return [WikiTemplate.new(name,params),src[2..-1]]
    else
      puts "invalid end token at template: #{str[0..([100,str.length-1].min)]}"
      exit(1)
    end
  else
    puts "invalid start token at template: #{str[0..([100,str.length-1].min)]}"
    exit(1)
  end
end

def read_internal_link(str)
  return [nil,str] if !str
  src = str
  src = src[2..-1] if src[0..1] == "[["
  if m = src.match(/\A(.+?)\s*(\||\]\])/m)
    # リンク記事名の抽出
    name = m[1]
    src = m[2] + m.post_match
    params = []
    while true
      param, src = read_param(src)
      break if !param
      params << param
    end
    if src[0..1] == "]]"
      return [InternalLink.new(name,params),src[2..-1]]
    else
      puts "invalid end token at internal link: #{str[0..([100,str.length-1].min)]}"
      exit(1)
    end
  else
    puts "invalid start token at internal link: #{str[0..([100,str.length-1].min)]}"
    exit(1)
  end
end

def get_info(str)
  while m = str.match(/.*?\{\{/m)
    t, str = read_template(m.post_match)
    return t if t.name_include?('駅情報')
  end
  puts "Error > 駅情報 not found"
  exit(0)
end

def parse_date(obj)
  str = nil
  if obj.kind_of?(String)
    str = obj
  elsif obj.kind_of?(Array)
    str = obj.join
  elsif obj == nil
    return 'NULL'
  else
    puts "Error > unknown date object #{obj}"
    exit(0)
  end
  if m = str.match(/([0-9]{4})年.*?([0-9]+)月([0-9]+)日/)
    date = "%04d-%02d-%02d" % m[1..3]
    return date
  end
  return 'NULL'
end

def parse(template,pref_map)
  name = template.get_param('駅名')
  if m = name.match(/^(.+?)仮?(駅|降車場|乗降場|停留場)$/)
    name = m[1]
  end
  name_kana = template.get_param('よみがな')
  lat = 0
  lng = 0
  if pos = template.get_param('座標')
    pos = pos[0] if pos.kind_of?(Array)
    if pos.name != 'ウィキ座標2段度分秒' || pos.get_param(3) != 'N' || pos.get_param(7) != 'E'
      puts "Error > unknown coordinate system #{pos.name}"
      exit(0)
    end
    lat = (pos.get_param(0).to_f + pos.get_param(1).to_f/60 + pos.get_param(2).to_f/3600).round(6)
    lng = (pos.get_param(4).to_f + pos.get_param(5).to_f/60 + pos.get_param(6).to_f/3600).round(6)
  else 
    lat1 = template.get_param('緯度度')
    lat2 = template.get_param('緯度分')
    lat3 = template.get_param('緯度秒')
    lng1 = template.get_param('経度度')
    lng2 = template.get_param('経度分')
    lng3 = template.get_param('経度秒')
    if lat1&&lat2&&lat3&&lng1&&lng2&&lng3
      lat = (lat1.to_f + lat2.to_f/60 + lat3.to_f/3600).round(6)
      lng = (lng1.to_f + lng2.to_f/60 + lng3.to_f/3600).round(6)
    else
      puts "Warning > coordinate value not found #{name}"
    end
  end
  pref = template.get_param('所在地')
  if pref.kind_of?(String) && m = pref.match(/^(.+?[県都府道])/)
    pref = m[1]
  elsif pref.kind_of?(Array) 
    if pref[0].kind_of?(InternalLink)
      pref = pref[0].name
    elsif pref[0].kind_of?(String)
      pref = pref[0]
    else
      puts "Error > unknown address value at array[0]: #{pref}"
      exit(0)
    end
  else
    puts "Error > unknown address format: #{pref}"
    exit(0)
  end

  if !(pref = pref_map[pref])
    puts "Error > unknown prefecture #{template.get_param('所在地')[0].name}"
    exit(0)
  end
  open_date = parse_date(template.get_param('開業年月日'))
  closed_date = parse_date(template.get_param('廃止年月日'))
  return [
    '','NULL',name,name_kana,
    lat,lng,pref,'NULL','NULL',
    1,open_date,closed_date,0,'NULL'
  ]
end


pref = {}
File.open('../prefecture.csv','r') do |file|
  file.each_line do |line|
    cells = line.chomp.split(',')
    pref[cells[1]] = cells[0].to_i
  end
end
list = []
list << ['code','id','name','name_kana','lat','lng','prefecture','postal_code','address','closed','open_date','closed_date','impl','attr']
File.open("list.txt","r") do |file|
  file.each_line do |line|
    name = line.chomp
    str = ''
    File.open("html/#{name}.html","r") do |f|
      f.each_line{|l| str << l}
    end
    puts name
    str = str.match(/<text.+?>(.+?)<\/text>/m)[1]
    list << parse(get_info(str),pref)
  end
end
File.open("station.csv","w") do |file|
  list.each{|e| file.puts(e.join(','))}
end