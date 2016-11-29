module AiBot
  class World
    attr_accessor :wizards, :minions, :trees, :buildings, :tick_index, :height, :width

    def self.init_from(real_world)
      w = AiBot::World.new
      w.wizards = real_world.wizards
      w.minions = real_world.minions
      w.trees = real_world.trees
      w.buildings = real_world.buildings
      w.height = real_world.height
      w.width = real_world.width

      w.tick_index = real_world.tick_index

      w.units.each { |u| u.extend AiBot::Unit }

      w
    end

    def tick!(moves={})
      @moves = moves
      clone_units

      apply_speed
      apply_turns
      refresh_positions

      @tick_index += 1
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

        unit.angle = Utils.normalize_angle(unit.angle + move.turn) 
      end
    end

    def refresh_positions
      units.each do |unit|
        new_position = Point.new unit.x + unit.speed_x, unit.y + unit.speed_y

        collision = units.any? do |u|
          u.id != unit.id && u.distance_to_unit(new_position) < (unit.radius + u.radius)
        end

        unless collision
          unit.x += unit.speed_x
          unit.y += unit.speed_y
        end
      end
    end

    def clone_units
      @wizards = @wizards.map(&:clone)
    end
  end
end
