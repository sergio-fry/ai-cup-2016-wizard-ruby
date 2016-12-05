module AiBot
  class TrackGenerator
    def initialize(depth: 10)
      @depth = depth
    end

    def generate
      Enumerator.new do |y|
        [-3, 0, 4].each do |speed|
          [-3, 0, 3].each do |strafe_speed|
            next if (speed.abs + strafe_speed.abs) == 0

            move = Move.new
            move.strafe_speed = strafe_speed
            move.speed = speed

            y << [move] * @depth
          end
        end
      end
    end
  end
end
