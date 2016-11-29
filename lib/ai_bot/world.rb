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

    def refresh_moving_units
      @moving_units = units.find_all { |u| (u.speed_x.abs + u.speed_y.abs) > 0 }
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
      # move my wizard only
      @moves.map { |id, _| unit_by_id(id) }.each do |unit|
        new_position = Point.new(unit.x + unit.speed_x, unit.y + unit.speed_y)

        collision = units.any? do |u|
          min_dist = (u.radius + unit.radius) + 10

          u.id != unit.id &&
            (u.x - new_position.x).abs < min_dist &&
            (u.y - new_position.y).abs < min_dist &&
            u.distance_to_unit(new_position) < min_dist
        end

        next if collision

        unit.x = new_position.x
        unit.y = new_position.y
      end
    end

    def clone_units
      @wizards = @wizards.map(&:clone)
    end
  end
end
