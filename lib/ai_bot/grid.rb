module AiBot
  class Grid
    attr_reader :nodes, :size
    attr_accessor :mapper

    def initialize(size:)
      @nodes = {}
      @size = size
    end

    def all_nodes
      nodes.values.map { |row| row.values }.flatten
    end

    def nodes_reachable_from(x, y)
      start_node = node_at(x, y)

      if start_node.nil?
        start_node = Point.new(x, y)
        add_node start_node
      end

      reachable = [start_node]

      next_nodes = neighbors_for(start_node)

      while true 
        reachable.concat next_nodes

        next_nodes = next_nodes.map { |node| neighbors_for(node) }.flatten - reachable
        break if next_nodes.empty?
      end
      
      reachable
    end

    def node_at(x, y)
      @nodes.dig(x.to_i, y.to_i)
    end

    def node_mapped_from(x, y)
      node_at *mapper.to_grid(x, y)
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

    def to_s
      (0..size - 1).to_a.map do |y|
        (0..size - 1).to_a.map { |x| node_at(x, y).nil? ? 1 : 0 }.join(' ')
      end.join("\n")
    end

    def self.build(units:, center:, radius:, size:)
      grid = Grid.new size: size
      grid.mapper = GridMapper.new(center: center, radius: radius, size: size)

      empty_cells = {}

      size.times do |x|
        size.times do |y|
          empty_cells[[x, y]] = Point.new(*grid.mapper.from_grid(x, y))
        end
      end

      # remove out of range
      empty_cells.values.each do |cell|
        if cell.x < 0 || cell.y < 0 || cell.x > 4000 || cell.y > 4000
          empty_cells.delete empty_cells.key(cell)
        end
      end

      # remove filled
      units.each do |unit|
        empty_cells.values.find_all do |cell|
          (cell.x - unit.x).abs < grid.mapper.cell_size / 2 + unit.radius &&
            (cell.y - unit.y).abs < grid.mapper.cell_size / 2 + unit.radius
        end.each do |cell|
          empty_cells.delete empty_cells.key(cell)
        end
      end

      # remove out of radius
      empty_cells.values.each do |cell|
        if cell.distance_to(center) > radius
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
