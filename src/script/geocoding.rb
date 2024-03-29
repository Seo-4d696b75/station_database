require 'dotenv'
require 'net/http'

Dotenv.load 'src/.env.local'
API_KEY = ENV['GOOGLE_GEOCODING_API_KEY']

def fetch_address(station)
  print "get address of station:#{station['name']} > "

  uri = URI.parse('https://maps.googleapis.com/')
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  https.verify_depth = 5
  res = https.start do |w|
    w.get("/maps/api/geocode/json?latlng=#{station['lat']},#{station['lng']}&key=#{API_KEY}&language=ja")
  end
  assert_equal res.code, '200', 'response from /maps/api/geocode/json'
  data = JSON.parse(res.body)
  assert_equal data['status'], 'OK', "response:\n#{JSON.pretty_generate(data)}"

  data = data['results'][0]

  puts "address: #{data['formatted_address']} #{data}"
  # 郵便番号
  list = data['address_components'].select { |c| c['types'].include?('postal_code') }
  assert_equal list.length, 1, 'fail to extract postal-code'
  station['postal_code'] = list[0]['long_name']
  # 住所
  exception = %w[postal_code country bus_station train_station transit_station]
  address = ''
  previous = nil
  pattern = /^[0-9０-９]+$/
  components = data['address_components']
  components.reject! do |c|
    c['types'].any? { |e| exception.include? e }
  end
  components.map! { |c| c['long_name'] }
  components.reverse.each do |c|
    address << '-' if previous&.match(pattern) && c.match(pattern)
    address << c
    previous = c
  end
  station['address'] = address
  station
end
