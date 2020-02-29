require 'net/http'
require 'openssl'
Encoding.default_external = 'UTF-8'

def get_all(src,des)
  domain = "https://ekimemo.wiki.fc2.com"
  pattern = /^(.+?),(.+)$/
  File.open(src,"r:utf-8") do |file|
    file.each_line do |line|
      m = line.match(pattern)
      path = domain + m[2]
      puts path  
      uri = URI.parse(path)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      https.verify_depth = 5
      https.ca_file = ""
      res = https.start { |w| w.get(m[2]) }
      if res.code != '200'
        puts "Error > code : " + res.code
        next
      end
      name = des + m[1] + ".txt"
      f = File.open(name,"w")
      f.puts(res.body)
      f.close
    end
  end
end

puts "src:\"./list.txt\" des:\"./details/raw/\""
get_all("./details/list.txt","./details/raw/")