
i=ARGV[0].to_i
Dir.glob("Screenshot*.jpg").sort{|a,b| a<=>b}.each do |e|
	File.rename(e,"#{i}.jpg")
	puts "#{e} => #{i}.jpg"
	i+=1
end