module AiBot
  module Unit
    attr_accessor :x, :y, :speed_x, :speed_y, :angle

    def enemy_to?(unit)
      !(self.faction == Faction::NEUTRAL || self.faction == unit.faction)
    end
  end
end

Unit.include AiBot::Unit
