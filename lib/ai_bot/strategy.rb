module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    def move!
      attrs = {
        life: me.life,
        mana: me.mana,
        vision_range: me.vision_range,
        cast_range: me.cast_range,
        xp: me.xp,
        level: me.level,
        remaining_action_cooldown_ticks: me.remaining_action_cooldown_ticks,
        remaining_cooldown_ticks_by_action: me.remaining_cooldown_ticks_by_action,
      }
      puts "#{world.tick_index} #{attrs.inspect}"
    end

    def my_position
      Point.new me.x, me.y
    end
  end
end
