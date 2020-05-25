require 'json'

list = []
list << ['station_code','line_code','index','numbering']
Dir.glob("../line/*.json").each do |path|
  str = ""
  File.open(path,"r:utf-8") do |file|
    file.each_line{|line| str << line}
  end
  data = JSON.parse(str)
  line_code = data['code']
  symbol = data['symbol']
  data['station_list'].each_with_index do |s,i|
    station_code = s['code']
    index = i + 1
    numbering = 'NULL'
    if s.key?('numbering')
      numbering = s['numbering'].map do |n|
        value = ""
        if n.key?('symbol')
          value << n['symbol']
        elsif symbol
          value << symbol
        end
        value << n['index']
        next value
      end.join('/')
    end
    list << [station_code,line_code,index,numbering]
  end
end

File.open("station-line.csv","w:utf-8") do |file|
  list.each{|e| file.puts(e.join(','))}
end

