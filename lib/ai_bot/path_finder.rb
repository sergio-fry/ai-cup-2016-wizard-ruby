module AiBot
  class PathFinder
    def initialize(grid:)
      @grid = grid
    end

    def find(from:, to:)



      d = 0
      marks = {}
      marks[from] = 0

      next_nodes = @grid.neighbors_for(from)

      until marks.keys.include?(to)
        d += 1

        next_nodes.each do |node|
          marks[node] = d
        end

        next_nodes = next_nodes.map { |node| @grid.neighbors_for(node) }.flatten - marks.keys
        break if next_nodes.empty?
      end

      return [] unless marks.keys.include?(to)

      inversed_path = [to]

      current = to

      until current == from
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
