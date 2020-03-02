
Encoding.default_external = 'UTF-8'


Dir.glob("./details/line/*.json").each do |n|
	str = ''
	File.open(n,'r') {|f| f.each_line{|l| str += l}}
	str.gsub!('phonetic', 'name_kana')
	File.open(n,"w"){|f| f.write(str)}
end
