file = 'station.csv'

list = []
File.open(file,"r") do |f|
  f.each_line do |line|
    if m = line.match(/^(.+?)\{\{(.+?)\}\}/)
      name = m[1]
      values = m[2].split('|')
      lat = (values[1].to_f + values[2].to_f/60 + values[3].to_f/3600).round(6)
      lng = (values[5].to_f + values[6].to_f/60 + values[7].to_f/3600).round(6)
      list << ['','NULL',name,'',lat,lng,'','NULL','NULL',1,'','',0,'NULL'].join(',') 
    else
      list << line.chomp
    end
  end
end
File.open(file,"w") do |f|
  list.each{|e| f.puts(e)}
end