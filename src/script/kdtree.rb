# diagramで計算したkd-treeのparser
class KdTreeNode
  attr_reader :code, :depth, :left, :right, :lat, :lng, :name

  def initialize(data, depth, map)
    @code = data['code']
    @lat = data['lat']
    @lng = data['lng']
    @name = data['name']
    @depth = depth
    @left = data['left'] ? KdTreeNode.new(map[data['left']], depth + 1, map) : nil
    @right = data['right'] ? KdTreeNode.new(map[data['right']], depth + 1, map) : nil
  end

  def serialize(depth = 4)
    segments = []
    root = {}
    segments << root
    root['name'] = 'root'
    root['root'] = @code
    list = []
    to_segment(depth, list, segments)
    root['node_list'] = list
    puts "tree-segment name:root depth:#{depth}"
    segments
  end

  def to_segment(depth, nodes, segments)
    node = {
      'code' => @code,
      'name' => @name,
      'lat' => @lat,
      'lng' => @lng,
      'segment' => nil,
      'left' => @left&.code,
      'right' => @right&.code
    }
    nodes << node
    if @depth == depth
      name = "segment#{segments.length}"
      node['segment'] = name
      segment = {}
      segments << segment
      segment['name'] = name
      segment['root'] = @code
      list = []
      to_segment(-1, list, nil)
      segment['node_list'] = list
      puts "tree-segment name:#{name} size:#{list.length}"
    else
      @left&.to_segment(depth, nodes, segments)
      @right&.to_segment(depth, nodes, segments)
    end
  end
end
