file = ARGV[0]
lines = []
File.open(file, "r") do |f|
  f.each_line { |line| lines << line }
end
lines.reverse!
File.open(file, "w") do |f|
  lines.each { |line| f.puts(line) }
end
