module AiBot
  class Grid
    def initialize
      @nodes = {}
    end

    def node_at(x, y)
      @nodes.dig(x.to_i, y.to_i)
    end

    def add_node(node)
      @nodes[node.x.to_i] ||= {}
      @nodes[node.x.to_i][node.y.to_i] = node
    end

    def neighbors_for(node)
      [
        node_at(node.x - 1, node.y),
        node_at(node.x, node.y - 1),
        node_at(node.x + 1, node.y),
        node_at(node.x, node.y + 1)
      ].compact
    end
  end
end
