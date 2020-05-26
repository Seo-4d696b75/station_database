load('script/utils.rb')

station_fields = [
  "code",
  "id",
  "name",
  "name_kana",
  "lat",
  "lng",
  "prefecture",
  "postal_code",
  "address",
  "closed",
  "open_date",
  "closed_date",
  "impl",
  "attr"
]

line_fields = [
  'code',
  'id',
  'name',
  'name_kana',
  'name_formal',
  'station_size',
  'company_code',
  'color',
  'symbol',
  'closed',
  'closed_date',
  'impl'
]


stations = []
station_code_set = Set.new
station_name_set = Set.new
id_set = IDSet.new
pref_cnt = Array.new(48, 0)


API_KEY = read('api_key.txt')


def get_address(station)
	print "get address of station:#{station['name']} > "
	data = nil
	file = "details/address/#{station['code']}.json"
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

def write_csv(fields,records)
  File.open('station.csv','w:utf-8') do |file|
    file.puts(fields.join(','))
    records.each do |s|
      file.puts(fields.map do |f|
        value = s[f]
        value = '1' if value==true
        value = '0' if value==false
        value = 'NULL' if value==nil
        next value
      end.join(','))
    end
  end
end

$csv_no = -1
$csv_line = nil
$csv_file = nil
def csv_each_line(name)
  $csv_file = name
  File.open(name,'r:utf-8') do |file|
    header = []
    file.each_line.each_with_index do |line,i|
      $csv_no = i+1
      if i == 0
        header = line.chomp.split(',')
        next
      end
      $csv_line = line
      line = line.chomp.split(',')
      csv_err("col size mismatch. #{line.length} <=> hader:#{header.length} ") if line.length!=header.length
      data = {}
      header.each_with_index{|f,i| data[f] = line[i]}
      $csv_line = data
      yield(data)
    end
  end
end

def csv_err(mes)
  puts "Error > #{mes} at file#{$csv_file}:#{$csv_no}\n#{$csv_line}"
  exit(0)
end

def read_boolean(data,key)
  value = data[key]
  if value && value == '0'
    return false
  elsif value && value = '1'
    return true
  else
    csv_err("invalid '#{key} value")
    return nil
  end
end

def read_date(data,key)
  value = data[key]
  if value && value == 'NULL'
    return nil
  elsif value && value.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)
    return value
  else
    csv_err("invalid '#{key}' value")
    return nil
  end
end

def read_value(data,key)
  value = data[key]
  if value && value == 'NULL'
    return nil
  elsif value && value.length > 0
    return value
  else
    csv_err("empty '#{key}' value")
    return nil
  end
end

puts "read station info."
csv_each_line('station.csv') do |fields|
  csv_err("col size != 14") if fields.length != 14
  code = fields['code'].to_i
  csv_err('code duplicate') if !station_code_set.add?(code)
  id = read_value(fields,'id')
  if id
    if id.match(/^[0-9a-f]{6}/)
      csv_err('id duplicate') if !id_set.add?(id)
    else
      csv_err('invalide id value')
    end
  end
  impl = read_boolean(fields,'impl')
  
  name = read_value(fields,"name")
  name_kana = read_value(fields,"name_kana")
  # 駅メモしようでは駅名重複なし
  csv_err('name duplicated') if impl && !station_name_set.add?(name)
  lat = fields['lat'].to_f
  lng = fields['lng'].to_f
  pref = fields['prefecture'].to_i
  csv_err('invalid prefecture value') if pref < 1 || pref > 47
  pref_cnt[pref] += 1 if impl
  closed = read_boolean(fields,"closed")
  attr = read_value(fields,"attr")
  csv_err('invalid attr value') if attr!='eco' && attr!='heat' && attr!='cool' && attr!='unknown'
  csv_err('closed <=> attr') if impl && closed != (attr=='unknown')
  csv_err('attr not defined in not impl station') if !impl && attr
  postal_code = read_value(fields,"postal_code")
  address = read_value(fields,"address")
  station = {}
  station['code'] = code
  station['id'] = id
  station['name'] = name
  station['name_kana'] = name_kana
  station['lat'] = lat
  station['lng'] = lng
  station['prefecture'] = pref
  station['attr'] = attr
  station['postal_code'] = postal_code
  station['address'] = address
  station['impl'] = impl
  station['closed'] = closed
  station['open_date'] = read_date(fields,"open_date")    
  station['closed_date'] = read_date(fields,"closed_date")
    
  stations << station
end

impl_size = stations.select{|s| s['impl']}.length
puts "station size: #{stations.length} (impl #{impl_size})"


print "check impl station size in each prefecture..."
csv_each_line('check/prefecture.csv') do |fields|
  code = fields['code'].to_i
  name = fields['name']
  size = fields['size'].to_i
  if size != pref_cnt[code]
    puts "Error > station size(impl) mismatch actual:#{pref_cnt[code]} expected:#{line}"
    exit(0)
  end
end
puts "OK"


puts "read line info."
lines = []
line_name_set = Set.new
line_code_set = Set.new
csv_each_line("line.csv") do |fields|
  csv_err('fields size != 12') if fields.length != 12
  code = fields['code'].to_i
  csv_err("line code duplicated") if !line_code_set.add?(code)
  id = read_value(fields,'id')
  if id
    if id.match(/^[0-9a-f]{6}/)
      csv_err('id duplicate') if !id_set.add?(id)
    else
      csv_err('invalid id value')
    end
  end
  name = read_value(fields,'name')
  csv_err('line name duplicated.') if !line_name_set.add?(name)
  name_kana = read_value(fields,'name_kana')
  name_formal = read_value(fields, "name_formal")
  station_size = fields['station_size'].to_i
  company_code = read_value(fields,'company_code')
  company_code = company_code.to_i if company_code
  color = read_value(fields,'color')
  symbol = read_value(fields,'symbol')
  closed = read_boolean(fields,"closed")
  impl = read_boolean(fields,"impl")
  closed_date = read_date(fields,"closed_date")
  puts "Warning > line closed date not defined #{name}" if closed && !closed_date
  csv_err('line not closed, but date defined') if !closed && closed_date

  line = {}
  line['code'] = code
  line['id'] = id
  line['name'] = name
  line['name_kana'] = name_kana
  line['name_formal'] = name_formal
  line['station_size'] = station_size
  line['company_code'] = company_code
  line['color'] = color
  line['symbol'] = symbol
  line['closed'] = closed
  line['impl'] = impl
  line['closed_date'] = closed_date

  lines << line
end

impl_size = lines.select{|s| s['impl']}.length
puts "lins size: #{lines.length} (impl #{impl_size})"


puts "add id to new station/line time."
write_id = false
(stations + lines).each do |s|
  if !s['id']
    s['id'] = id_set.get()
    write_id = true
  end
end
if write_id
  write_csv(station_fields,stations)
  write_csv(line_fields,lines)
  puts "id added and saved."
end

puts "add post&address value if needed."
stations.each do |station|
  write = false
  if !station['postal_code'] || !station['address']
    get_address(station)
    write = true
  end
  if !station['postal_code'].match(/[0-9]{3}-[0-9]{4}/)
    puts "Error > invalide post code: #{JSON.dump(station)}"
    exit(0)
  end
  write_csv(station_fields,stations) if write
end

puts "All done."