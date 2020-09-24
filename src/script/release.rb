require "json"

version = ARGV[0].to_i
size = File.size("out/data.json")

info = {
  "version": version,
  "size": ("%.2fMB" % (size.to_f / 2 ** 20)),
  "url": "https://raw.githubusercontent.com/Seo-4d696b75/station_database/master/out/data.json",
}

File.open("latest_info.json", "w") do |file|
  file.puts(JSON.pretty_generate(info))
end
