module AiBot
  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x, @y = x.to_f, y.to_f
    end

    def distance_to(point)
      Math::hypot(point.x - @x, point.y - @y)
    end

    def to_s
      "(#{@x.round(3)}, #{@y.round(3)})"
    end

    def ==(point2)
      self.x == point2.x && self.y == point2.y
    end
  end
end
