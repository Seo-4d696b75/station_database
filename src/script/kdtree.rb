class Node
  attr_reader :code, :depth, :left, :right, :lat, :lng, :name

  def initialize(data, depth, map)
    @code = data["code"]
    @lat = data["lat"]
    @lng = data["lng"]
    @name = data["name"]
    @depth = depth
    @left = data["left"] ? Node.new(map[data["left"]], depth + 1, map) : nil
    @right = data["right"] ? Node.new(map[data["right"]], depth + 1, map) : nil
  end

  def serialize(depth = 4)
    segments = []
    root = {}
    segments << root
    root["name"] = "root"
    root["root"] = @code
    list = []
    to_segment(depth, list, segments)
    root["node_list"] = list
    puts "tree-segment name:root depth:#{depth}"
    return segments
  end

  def to_segment(depth, nodes, segments)
    node = { "code" => @code }
    node["name"] = @name
    node["lat"] = @lat
    node["lng"] = @lng
    node["left"] = @left.code if @left
    node["right"] = @right.code if @right
    nodes << node
    if @depth == depth
      name = "segment#{segments.length}"
      node["segment"] = name
      segment = {}
      segments << segment
      segment["name"] = name
      segment["root"] = @code
      list = []
      to_segment(-1, list, nil)
      segment["node_list"] = list
      puts "tree-segment name:#{name} size:#{list.length}"
    else
      if @left
        @left.to_segment(depth, nodes, segments)
      end
      if @right
        @right.to_segment(depth, nodes, segments)
      end
    end
  end
end
