module AiBot
  class WorldState
    attr_reader :tick, :width, :height

    def initialize(previous: nil, units: [], tick: 0, width: 4000, height: 4000)
      @previous = previous
      @next = nil
      @tick = tick
      @width = width
      @height = height

      self.units = units
    end

    def units=(new_units)
      @moving_units = new_units.find_all { |u| (u.speed_x.abs + u.speed_y.abs) > 0 }
      @standing_units = new_units - @moving_units
      @units_hash = Hash[new_units.map { |unit| [unit.id, unit] }]
    end

    def units
      @standing_units + @moving_units
    end

    def next
      @next ||= self.class.new(previous: self, units: @standing_units + moved_units_on_next_tick, tick: @tick + 1)
    end

    def apply_move(unit, move)
      apply_move_speed unit, move
      apply_move_turn unit, move
      update_position unit, detect_collision: true

      unit
    end

    def unit_by_id(id)
      @units_hash[id]
    end

    private

    def moved_units_on_next_tick
      arr = []

      @moving_units.each do |unit|
        new_unit = unit.clone

        update_position(new_unit, detect_collision: false)

        arr << new_unit
      end

      arr
    end

    def apply_move_speed(unit, move)
      unit.speed_x = move.speed * Math.cos(unit.angle)
      unit.speed_y = move.speed * Math.sin(unit.angle)

      unit
    end

    def apply_move_turn(unit, move)
      unit.angle = Utils.normalize_angle(unit.angle + move.turn)
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

        return if collision
      end

      return if new_position.x < unit.radius
      return if new_position.y < unit.radius
      return if new_position.x > width - unit.radius
      return if new_position.y > height - unit.radius
      

      unit.x = new_position.x
      unit.y = new_position.y
    end
  end
end
