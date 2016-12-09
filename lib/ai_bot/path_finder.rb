module AiBot
  class PathFinder
    def initialize(grid:)
      @grid = grid
    end

    def find(from:, to:)
      [from, to]
    end
  end
end
