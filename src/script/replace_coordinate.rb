load("../script/utils.rb")

stations = []
coordinates = []
list = [
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
csv_each_line("../station.csv") do |fields|
  if fields.length == 15
    if c = coordinates.shift
      lat = c[0].to_f
      lng = c[1].to_f
      fields["lat"] = lat
      fields["lng"] = lng
    end
    stations << fields
  elsif fields.length == 2
    coordinates << fields
  else
    raise StandardError.new("csv fields size")
  end
end
write_csv("../station.csv", list, stations)
