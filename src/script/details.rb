require 'net/http'
require 'openssl'
Encoding.default_external = 'UTF-8'

def get_all(src,des)
  domain = "https://ekimemo.wiki.fc2.com"
	pattern = /^(.+?),(.+)$/
	cnt = 0
  File.open(src,"r:utf-8") do |file|
    file.each_line do |line|
			m = line.match(pattern)
			if ! m then next end
      path = domain + m[2]
      puts path  
      uri = URI.parse(path)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      https.verify_depth = 5
      https.ca_file = "details/cacert.pem"
      res = https.start { |w| w.get(m[2]) }
      if res.code != '200'
        puts "Error > code : " + res.code
        next
      end
      name = des + m[1] + ".txt"
      f = File.open(name,"w")
      f.puts(res.body)
			f.close
			cnt += 1
		end
		puts "size: #{cnt}"
  end
end

get_all("./details/url_list.txt","./details/raw2/")