require 'net/http'
require 'uri'

File.open("list.txt","r") do |file|
  file.each_line do |line|
    cells = line.chomp.split(',')
    path = cells[0]
    name = cells[1]    
    m = path.match(/wiki\/(.+?)$/)
    uri = URI.parse("https://ja.wikipedia.org/wiki/%E7%89%B9%E5%88%A5:%E3%83%87%E3%83%BC%E3%82%BF%E6%9B%B8%E3%81%8D%E5%87%BA%E3%81%97/#{m[1]}")
    puts uri.request_uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri.request_uri)
    res = http.request(req)
    if res.code != '200'
      puts "Error > code : " + res.code
      exit(0)
    end
    File.open("html/#{name}.html","w") do |f|
      f.print(res.body)
    end
  end
end


