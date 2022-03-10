class Node
  attr_reader :code, :depth, :left, :right, :lat, :lng
  attr_accessor :south, :north, :west, :east

  def initialize(data, depth, map)
    @code = data["code"]
    @lat = data["lat"]
    @lng = data["lng"]
    @depth = depth
    @left = data.key?("left") ? Node.new(map[data["left"]], depth + 1, map) : nil
    @right = data.key?("right") ? Node.new(map[data["right"]], depth + 1, map) : nil
  end

  def serialize(depth = 4)
    @west = -180.0
    @south = -90.0
    @east = 180.0
    @north = 90.0
    segments = []
    root = {}
    segments << root
    root["name"] = "root"
    root["root"] = @code
    list = []
    to_segment(depth, list, segments)
    root["station_size"] = list.select { |e| !e.key?("segment") }.length
    root["node_list"] = list
    puts "tree-segment name:root size:#{root["station_size"]} depth:#{depth}"
    return segments
  end

  def to_segment(depth, nodes, segments)
    node = { "code" => @code }
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
      segment["east"] = @east
      segment["west"] = @west
      segment["south"] = @south
      segment["north"] = @north
      list = []
      to_segment(-1, list, nil)
      segment["station_size"] = list.length
      segment["node_list"] = list
      puts "tree-segment name:#{name} size:#{list.length} lng:[#{@west},#{@east}] lat:[#{@south},#{@north}]"
    else
      if @left
        if @depth % 2 == 0
          @left.east = @lng
          @left.west = @west
          @left.south = @south
          @left.north = @north
        else
          @left.east = @east
          @left.west = @west
          @left.south = @south
          @left.north = @lat
        end
        @left.to_segment(depth, nodes, segments)
      end
      if @right
        if @depth % 2 == 0
          @right.east = @east
          @right.west = @lng
          @right.south = @south
          @right.north = @north
        else
          @right.east = @east
          @right.west = @west
          @right.south = @lat
          @right.north = @north
        end
        @right.to_segment(depth, nodes, segments)
      end
    end
  end
end
