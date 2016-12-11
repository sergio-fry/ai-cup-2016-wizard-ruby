module AiBot
  class PathFinder
    def initialize(grid:)
      @grid = grid
    end

    def find(from:, to:)
      from_node = @grid.node_at(*from)
      to_node = @grid.node_at(*to)

      d = 0
      marks = {}
      marks[from_node] = 0

      next_nodes = @grid.neighbors_for(from_node)

      until marks.keys.include?(to_node)
        d += 1

        next_nodes.each do |node|
          marks[node] = d
        end

        next_nodes = next_nodes.map { |node| @grid.neighbors_for(node) }.flatten - marks.keys
        break if next_nodes.empty?
      end

      return [] unless marks.keys.include?(to_node)

      inversed_path = [to_node]

      current = to_node

      until current == from_node
        next_node = @grid.neighbors_for(current).find do |node|
          marks[node] == marks[current] - 1
        end

        inversed_path << next_node

        current = next_node
      end

      inversed_path.reverse!
    end
  end
end
