module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    def move!
      puts "#{world.tick_index} #{my_position}"
      move.speed = 1.5
    end

    def my_position
      Point.new me.x, me.y
    end
  end
end
