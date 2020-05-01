require 'net/http'
require 'openssl'
load('script/utils.rb')


# soved された駅データ
puts "read soved station data."
stations = read_json('./solved/station.json')

API_KEY = read('api_key.txt')

def get_address(station)
	print "get address of station:#{station['name']} > "
	data = nil
	file = "details/address/#{station['code']}.json"
	if File.exists?(file)
		data = read_json(file)
		if data['lat'] == station['lat'] && data['lng'] == station['lng']
			data = data['results'][0]
			puts "file found:#{file}"
		else
			data = nil
		end
	end
	if !data
		uri = URI.parse("https://maps.googleapis.com/")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      https.verify_depth = 5
      https.ca_file = "cacert.pem"
      res = https.start { |w| w.get("/maps/api/geocode/json?latlng=#{station['lat']},#{station['lng']}&key=#{API_KEY}&language=ja") }
      if res.code != '200'
        puts "Error > code : " + res.code
        exit(0)
			end
			data = JSON.parse(res.body)
			if data['status'] != 'OK'
				puts "Error > response:\n#{JSON.pretty_generate(data)}"
				exit(0)
			end
			h = {}
			h['station'] = station['name']
			h['lat'] = station['lat']
			h['lng'] = station['lng']
			h['plus_code'] = data['plus_code']
			h['results'] = data['results']
			File.open("details/address/#{station['code']}.json",'w'){|f| f.write(JSON.pretty_generate(h))}
			data = data['results'][0]
			puts "GeocodeAPI success."
	end
	puts "address: #{data['formatted_address']}"
	# 郵便番号
	list = data['address_components'].select{|c| c['types'].include?('postal_code')}
	if list.length != 1
		puts "Error > fail to extract postal-code"
		exit(0)
	end
	station['postal_code'] = list[0]['long_name']
	# 住所
	exception = ['postal_code','county','bus_station','train_station','transit_station']
	predicate = lambda do |list|
		list.each{|e| return false if exception.include?(e)}
		return true
	end
	address = ''
	previous = nil
	pattern = /^[0-9０-９]+$/
	data['address_components'].select do |c|
		predicate.call(c['types'])
	end.reverse.map{|c| c['long_name']}.each do |c|
		if previous && previous.match(pattern) && c.match(pattern)
			address << '-'
		end
		address << c
		previous = c
	end
	station['address'] = address
			
end


puts "check address of each station"
stations.filter{|s| !s.key?('postal_code') || !s.key?('address') }.each{|s| get_address(s)}

# 詳細データの読み込み
puts 'read station details data.'
details = {}
File.open('./details/station.csv','r')  do |f|
	f.each_line do |line|
		if m = line.chomp.match(/^(.+?),(.+?),([0-9]+?),(.+)$/)
			name = m[1]
			kana = m[2]
			prefecture = m[3].to_i
			attribute = m[4]
			details[name] = [kana,prefecture,attribute]
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
	kana, prefecture, attribute = details[name]
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
	if attribute != 'heat' && attribute != 'cool' && attribute != 'eco' && attribute != 'unknown'
		puts "Error > invalid attribute #{attribute} for station:#{s}";
		exit(0)
	end
	closed = s.key?('closed') && s['closed']
	if closed && attribute != 'unknown'
		puts "Error > attr:#{attribute} not accepted for closed:#{s}"
		#exit(0)
	elsif !closed && attribute == 'unknown'
		puts "Error > attr:#{attribute} not accepted for station:#{s}"
		#exit(0)
	end
	s['attr'] = attribute
end

puts "stop"
exit(0)

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

# write
File.open('details/station.json','w') do |f|
	f.write( format_json(stations.map{|e| sort_hash(e)},flat:true))
end
puts "write stations details to file."