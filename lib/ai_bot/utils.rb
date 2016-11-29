module AiBot
  module Utils
    def normalize_angle(angle)
      sign = angle / angle.abs

      while angle.abs > Math::PI
        angle += -sign * 2 * Math::PI
      end

      angle
    end

    module_function :normalize_angle
  end
end
