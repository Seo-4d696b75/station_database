class CSVLine
  attr_reader :length

  def initialize(header, line)
    @length = line.length
    @data = {}
    @header = header
    header&.each_with_index { |f, i| @data[f] = line[i] }
    line.each_with_index { |e, i| @data[i] = e }
  end

  def [](key)
    @data[key]
  end

  def []=(key, value)
    if key.is_a?(Integer)
      raise IndexError if key.negative? || key >= length

      @data[key] = value
      @data[@header[key]] = value if @header
    elsif key.is_a?(String)
      raise StandardError, 'header not set' unless @header

      idx = @header.index(key)
      raise IndexError, 'key not found in headers' unless idx
      raise IndexError if idx.negative? || idx >= length

      @data[idx] = value
      @data[key] = value
    else
      raise StandardError, 'invalid key type'
    end
  end

  def boolean(key)
    value = self[key]
    if value && value == '0'
      false
    elsif value && value == '1'
      true
    else
      raise StandardError, "invalid '#{key}' value"
    end
  end

  def date(key)
    value = self[key]
    if value && value == 'NULL'
      nil
    elsif value&.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)
      value
    else
      raise StandardError, "invalid '#{key}' value"
    end
  end

  def str(key)
    value = self[key]
    if value && value == 'NULL'
      nil
    elsif value&.length&.positive?
      value
    else
      raise StandardError, "empty '#{key}' value"
    end
  end
end

def read_csv(name, has_header = true)
  File.open(name, 'r:utf-8') do |file|
    header = nil
    file.each_line.each_with_index do |line, i|
      if i.zero? && has_header
        header = line.chomp.split(',')
        next
      end
      line = line.chomp.split(',')
      assert !header || line.length == header.length, "col size mismatch file:#{name} line:#{i + 1}"
      data = CSVLine.new(header, line)
      yield(data)
    end
  end
end

def write_csv(name, fields, records)
  File.open(name, 'w:utf-8') do |file|
    file.puts(fields.join(','))
    records.each do |s|
      file.puts(fields.map do |f|
        value = s[f]
        value = '1' if value == true
        value = '0' if value == false
        value = 'NULL' if value.nil?
        # 座標値は小数点以下６桁までの有効数字
        value = format('%.06f', value.round(6)) if value.is_a?(Float) && %w[lat lng].include?(f)
        next value
      end.join(','))
    end
  end
end
