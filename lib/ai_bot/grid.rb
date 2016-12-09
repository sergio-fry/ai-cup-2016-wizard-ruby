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

    MATRIX_SIZE = 10
    WIZARD_VISION_RANGE = 600

    def self.build(units:, center:, radius: WIZARD_VISION_RANGE, size: MATRIX_SIZE)
      grid = Grid.new

      cell_size = radius.to_f * 2 / size

      empty_cells = {}

      size.times do |x|
        size.times do |y|
          empty_cells[[x, y]] = Point.new(x * cell_size + cell_size / 2, y * cell_size + cell_size / 2)
        end
      end

      units.each do |unit|
        empty_cells.values.find_all do |cell|
          (cell.x - unit.x).abs < cell_size / 2 + unit.radius &&
            (cell.y - unit.y).abs < cell_size / 2 + unit.radius
        end.each do |cell|
          empty_cells.delete empty_cells.key(cell)
        end
      end

      empty_cells.keys.each do |x, y|
        grid.add_node AiBot::Point.new(x, y)
      end

      grid
    end
  end
end
