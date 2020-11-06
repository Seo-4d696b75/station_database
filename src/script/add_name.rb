load("script/utils.rb")
require "set"

SRC_FIELD = [
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
  "attr",
]

DST_FIELD = [
  "code",
  "id",
  "name",
  "original_name",
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
  "attr",
]

src = "station.csv"
dst = "statoin_tmp.csv"
list = []
history = Set.new
duplicated = Hash.new(0)
pref = Set.new

if File.exists?(dst)
  csv_each_line(dst) do |fields|
    csv_err("col size != 14") if fields.length != 15
    list << fields
    history.add(read_value(fields, "id"))
    name = read_value(fields, "name")
    original = read_value(fields, "original_name")
    if name != original
      duplicated[original] = duplicated[original] + 1
    end
  end
end

File.open("prefecture.csv", "r") do |f|
  f.each_line do |line|
    name = line.chomp.split(",")[1]
    if m = name.match(/^(.+)[都府県]$/)
      name = m[1]
    end
    pref.add(name)
  end
end
pref.add("JR")
pref.add("国鉄")
csv_each_line("raw/company20200309.csv") do |f|
  pref.add(read_value(f, "company_name"))
end

csv_each_line(src) do |fields|
  begin
    csv_err("col size != 14") if fields.length != 14
    if history.add?(read_value(fields, "id"))
      name = read_value(fields, "name")
      original = name
      if m = name.match(/^(?<name>.+?)\((?<suffix>[^\(\)]+)\)$/)
        suffix = m[:suffix]
        original = m[:name]
        if !pref.include?(suffix)
          print "unknown suffix:'#{suffix}' in '#{name}'. remove it?"
          sig = gets.chomp
          if sig.match(/[nT]/)
            original = name
          elsif sig.match(/[qQ]/)
            raise "abort"
          end
        end
      end
      if name != original
        puts "#{name} => #{original}"
        duplicated[original] = duplicated[original] + 1
      end
      fields["original_name"] = original
      list << fields
    end
  rescue => err
    puts err
    write_csv(dst, DST_FIELD, list)
    exit(0)
  end
end

write_csv(dst, DST_FIELD, list)
duplicated.each do |k, v|
  if v == 1
    puts "name:#{k} not duplicated!!"
    #exit(1)
  end
  puts "#{k} x #{v}"
end

puts "All done."
