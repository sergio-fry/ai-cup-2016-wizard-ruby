module AiBot
  class World < World
    attr_accessor :move

    def tick!(moves={})
      @moves = moves
      clone_units

      apply_speed
      apply_turns
      refresh_positions
    end

    def unit_by_id(id)
      units.find { |u| u.id == id }
    end

    def units
      wizards + minions + buildings + trees
    end

    private

    def apply_speed
      @moves.each do |id, move|
        unit = unit_by_id(id)

        unit.speed_x = move.speed * Math.cos(unit.angle)
        unit.speed_y = move.speed * Math.sin(unit.angle)
      end
    end

    def apply_turns
      @moves.each do |id, move|
        unit = unit_by_id(id)

        unit.angle = unit.angle + move.turn
      end
    end

    def refresh_positions
      units.each { |w| w.x += w.speed_x; w.y += w.speed_y }
    end

    def clone_units
      @wizards = @wizards.map(&:clone)
    end
  end
end
