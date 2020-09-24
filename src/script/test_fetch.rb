load("src/script/utils.rb")

def extract_meta(data)
  return {
    "id": data["id"],
    "code": data["code"],
    "name": data["name"]
  }
end

data = read_json("out/data.json")
version = data["version"]
stations = data["stations"]
lines = data["lines"]

data = {
  "version": version,
  "stations": stations.map{|s| extract_meta(s)},
  "lines": lines.map{|l| extract_meta(l)}
}

File.open("artifact/data.json","w") do |file|
  file.print(JSON.dump(data))
end
