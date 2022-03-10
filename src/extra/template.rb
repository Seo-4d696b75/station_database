lines = []
file = "list.txt"
File.open(file, "r") do |f|
  f.each_line do |line|
    lines << line.chomp
  end
end
File.open(file, "w") do |f|
  lines.each do |line|
    if m = line.match(/\[\[(?<name>.+?)(\|.+?)?\]\]/)
      f.puts(m[:name])
    end
  end
end
