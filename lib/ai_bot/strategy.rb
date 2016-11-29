module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    def move!
      puts "#{world.tick_index} #{my_position}, #{me.speed_x},#{me.speed_y}, angle:#{me.angle}"

      if world.tick_index == 0
        move.turn = 0.1
      end

      move.speed = 1
    end

    def my_position
      Point.new me.x, me.y
    end
  end
end
