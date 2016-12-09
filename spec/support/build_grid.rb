def build_grid(input)
  new_grid = AiBot::Grid.new

  input.split("\n").each_with_index do |line, y|
    line.split.each_with_index do |node, x|
      new_grid.add_node AiBot::Point.new(x, y) if node == '0'
    end
  end

  new_grid
end
