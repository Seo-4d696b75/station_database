
require 'json'
Encoding.default_external = 'UTF-8'

api_key = 'AIzaSyDKM0E4kfK-2gw4tz4ROyya1kH0SLh3ni8'
url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=41.773709,140.726413&key=AIzaSyDKM0E4kfK-2gw4tz4ROyya1kH0SLh3ni8'

# soved された駅データ
puts "read soved station data."
str = ''
File.open("./solved/station.json","r"){|f| f.each_line{|l| str += l}}
stations = JSON.parse(str)

# 詳細データの読み込み
puts 'read station details data.'
details = {}
File.open('./details/station.csv','r')  do |f|
	f.each_line do |line|
		if m = line.chomp.match(/(.+?),(.+?),([0-9]+)/)
			name = m[1]
			kana = m[2]
			prefecture = m[3].to_i
			details[name] = [kana,prefecture]
		end
	end
end

prefecture_cnt = Array.new(48){|i| 0}

puts 'fill up details for each station'

stations.each do |s|
	name = s['name']
	if !details.key?(name)
		puts "Error > no detail found for #{s}"
		exit(0)
	end
	kana, prefecture = details[name]
	s['name_kana'] = kana
	if s.key?('prefecture')
		if s['prefecture'] != prefecture
			puts "Error > prefecture mismatch #{prefecture}(detail) <> #{s}"
			exit(0)
		end
	else
		s['prefecture'] = prefecture
	end
	prefecture_cnt[prefecture] += 1
end

if details.length != stations.length
	puts "Error > station size mismatch solved:#{details.length} detail:#{details.length}"
	exit(0)
end

# 都道府県での駅数を確認
File.open('./check/prefecture.csv','r') do |f|
	f.each_line do |line|
		if m = line.chomp.match(/([0-9]+),(.+?),([0-9]+)/)
			code = m[1].to_i
			name = m[2]
			size = m[3].to_i
			if prefecture_cnt[code] != size
				puts "Error > size mismatch. prefecture:#{name}, expected:#{size},actual:#{prefecture_cnt[code]}"
				exit(0)
			end
		end
	end
end
puts "All 47 prefecture checked."