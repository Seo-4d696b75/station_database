require 'json'
require 'optparse'

version = 0
src = ''
dst = ''
opt = OptionParser.new
opt.on('-v', '--version VALUE') { |v| version = v.to_i }
opt.on('-s', '--src VALUE') { |v| src = v }
opt.on('-d', '--dst VALUE') { |v| dst = v }
opt.parse!(ARGV)
ARGV.clear

size = File.size(src)

info = {
  "version": version,
  "size": size
}

File.open(dst, 'w') do |file|
  file.puts(JSON.pretty_generate(info))
end
