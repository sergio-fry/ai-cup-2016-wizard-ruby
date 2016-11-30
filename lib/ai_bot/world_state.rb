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

    def next
      @next ||= self.class.new(previous: self, units: @standing_units + moved_units_on_next_tick, tick: @tick + 1)
    end

    def apply_move(unit, move)
      unit_new = unit.clone

      apply_move_speed unit_new, move
      apply_move_turn unit_new, move
      update_position unit_new, detect_collision: true

      unit_new
    end

    def unit_by_id(id)
      @units_hash[id]
    end

    private

    def moved_units_on_next_tick
      arr = []

      @moving_units.each do |unit|
        new_unit = unit.clone

        update_position(unit, detect_collision: false)

        arr << new_unit
      end

      arr
    end

    def apply_move_speed(unit, move)
      unit.instance_variable_set(:'@speed_x', move.speed * Math.cos(unit.angle))
      unit.instance_variable_set(:'@speed_y', move.speed * Math.sin(unit.angle))

      unit
    end

    def apply_move_turn(unit, move)
      unit.instance_variable_set :'@angle', Utils.normalize_angle(unit.angle + move.turn) 
    end

    def update_position(unit, detect_collision: false)
      new_position = Point.new(unit.x + unit.speed_x, unit.y + unit.speed_y)

      if detect_collision
        collision = units.any? do |u|
          min_dist = u.radius + unit.radius

          u.id != unit.id &&
            (u.x - new_position.x).abs < min_dist &&
            (u.y - new_position.y).abs < min_dist &&
            u.distance_to_unit(new_position) < min_dist
        end

        next if collision
      end

      next if new_position.x < unit.radius
      next if new_position.y < unit.radius
      next if new_position.x > width - unit.radius
      next if new_position.y > height - unit.radius

      new_unit.instance_variable_set(:'@x', unit.x + new_position.speed_x)
      new_unit.instance_variable_set(:'@y', unit.y + new_position.speed_y)
    end
  end
end
