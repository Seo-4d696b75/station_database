def format_json_obj(obj, flat: false, flat_key: [], flat_array: [], depth: 0)
  str = '{'
  str << "\n" + ('  ' * (depth + 1)) unless flat
  sep = flat ? ',' : ",\n" + ('  ' * (depth + 1))
  str << obj.to_a.map do |e|
    key, value = e
    value = format_json_value(
      key, value,
      flat:,
      flat_key:,
      flat_array:,
      depth: depth + 1
    )
    value = "\"#{key}\":#{value}"
  end.join(sep)
  str << "\n" + ('  ' * depth) unless flat
  str << '}'
  str
end

def format_json_array(array, flat: false, flat_element: false, flat_key: [], flat_array: [], depth: 0)
  str = '['
  str << "\n" + ('  ' * (depth + 1)) unless flat
  sep = flat ? ',' : ",\n" + ('  ' * (depth + 1))
  str << array.map do |value|
    format_json_value(
      nil, value,
      flat: flat || flat_element,
      flat_key:,
      flat_array:,
      depth: (depth + 1)
    )
  end.join(sep)
  str << "\n" + ('  ' * depth) unless flat
  str << ']'
  str
end

def format_json_value(key, value, flat: false, flat_key: [], flat_array: [], depth: 0)
  case true
  when value.is_a?(String)
    return "\"#{value}\""
  when value.is_a?(Integer) || value == true || value == false
    return value.to_s
  when value.nil?
    return 'null'
  when value.is_a?(Hash)
    return format_json_obj(
      value,
      flat: flat || flat_key.include?(key),
      flat_key:,
      flat_array:,
      depth:
    )
  when value.is_a?(Array)
    return format_json_array(
      value,
      flat: flat || flat_key.include?(key),
      flat_element: flat_array.include?(key),
      flat_key:,
      flat_array:,
      depth:
    )
  when value.is_a?(Float) && %w[lat lng].include?(key)
    # 座標値は小数点以下６桁までの有効数字
    return value.round(6)
  when value.is_a?(Float)
    return value.to_s
  end
  raise "unexpected json value key:#{key} value:#{JSON.dump(value)}"
end

# JSON.dumpに代わるカスタムエンコーダー
#
# ルートになるオブジェクトは特別に`:root`をkeyとして扱う
# @param data 文字列に変換するオブジェクト
# @param flat_key Array<String|Symbol> 指定したkeyに対するjson objectは１行で出力
# @param flat_array Array<String|Symbol> 指定したkeyに対するArrayの各要素にあるjson objectを１行で出力
def format_json(data, flat_key: [], flat_array: [])
  format_json_value(
    :root, data,
    flat: flat_key.include?(:root),
    flat_key:,
    flat_array:,
    depth: 0
  )
end

def normalize_hash(src, keys, extra)
  dst = {}
  keys.each do |key|
    # mainデータセットでは`extra`属性不要
    next if !extra && key == 'extra'

    # 指定したkeyの定義を確認（value=nilでもkeyの定義を要求する）
    raise "value for key:#{key} not set in #{JSON.dump(src)}" unless src.key?(key)

    value = src[key]
    # nullはkey-value自体を削除
    dst[key] = value unless value.nil?
  end
  dst
end
