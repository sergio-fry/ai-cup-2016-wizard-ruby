def build_grid(input)
  size = input.split("\n").first.split.size

  new_grid = AiBot::Grid.new size: size

  input.split("\n").each_with_index do |line, y|
    line.split.each_with_index do |node, x|
      new_grid.add_node AiBot::Point.new(x, y) if node == '0'
    end
  end

  new_grid
end
