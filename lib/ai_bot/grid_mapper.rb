module AiBot
  class GridMapper
    attr_reader :x0, :y0, :cell_size, :center
    def initialize(center:, radius: WIZARD_VISION_RANGE, size: MATRIX_SIZE)
      @cell_size = radius.to_f * 2 / size
      @x0 = center.x - radius
      @y0 = center.y - radius
      @center = center
    end

    def to_grid(x, y)
      [(x - x0) / cell_size - 0.5, (y - y0) / cell_size - 0.5]
    end

    def from_grid(x, y)
      [x0 + x * cell_size + cell_size / 2, y0 + y * cell_size + cell_size / 2]
    end
  end
end
