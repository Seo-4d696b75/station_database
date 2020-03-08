
Encoding.default_external = 'UTF-8'


Dir.glob("./polyline/raw/*.json").each do |n|
	str = ''
	File.open(n,'r') {|f| f.each_line{|l| str += l}}
	str.gsub!('"lon"', '"lng"')
	File.open(n,"w"){|f| f.write(str)}
end
