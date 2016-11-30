module AiBot
  class WorldState
    def initialize(previous: nil, units: [], tick: 0)
      @previous = previous
      @next = nil
      @tick = tick

      @moving_units = units.find_all { |u| (u.speed_x.abs + u.speed_y.abs) > 0 }
      @standing_units = units - @moving_units

      @units_hash = Hash[units.map { |unit| [unit.id, unit] }]
    end

    def units
      @standing_units + @moving_units
    end

    def tick!(me, move)
      @next = self.class.new(previous: self, units: @standing_units + moved_units_on_next_tick, tick: @tick + 1)

      new_me = apply_speed(me.clone, move)

      @next
    end

    def unit_by_id(id)
      @units_hash[id]
    end

    private

    def moved_units_on_next_tick
      arr = []

      @moving_units.each do |unit|
        new_unit = unit.clone

        new_unit.instance_variable_set(:'@x', unit.x + unit.speed_x)
        new_unit.instance_variable_set(:'@y', unit.y + unit.speed_y)

        arr << new_unit
      end

      arr
    end

    def apply_speed(unit, move)
      unit.instance_variable_set(:'@speed_x', move.speed * Math.cos(unit.angle))
      unit.instance_variable_set(:'@speed_y', move.speed * Math.sin(unit.angle))

      unit
    end

    def refresh_position(units, collision: false)
      # move my wizard only
      @moves.map { |id, _| unit_by_id(id) }.each do |unit|
        new_position = Point.new(unit.x + unit.speed_x, unit.y + unit.speed_y)

        collision = units.any? do |u|
          min_dist = (u.radius + unit.radius) + 1

          u.id != unit.id &&
            (u.x - new_position.x).abs < min_dist &&
            (u.y - new_position.y).abs < min_dist &&
            u.distance_to_unit(new_position) < min_dist
        end

        next if collision
        next if new_position.x < unit.radius
        next if new_position.y < unit.radius
        next if new_position.x > width - unit.radius
        next if new_position.y > height - unit.radius

        unit.x = new_position.x
        unit.y = new_position.y
      end
    end
  end
end
