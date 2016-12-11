module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    TRACE_SIZE = 100
    PATH_SIZE = 5

    def initialize
      @positions = []
    end

    def move!
      refresh_positions

      grid = Grid.build(units: units, center: me, radius: game.wizard_vision_range, size: 15)

      path_finder = PathFinder.new grid: grid
      path = path_finder.find(from: grid.mapper.to_grid(me.x, me.y), to: grid.mapper.to_grid(600, 3200))

      next_point = path[1]
      return if next_point.nil?

      next_point_real = Point.new(*grid.mapper.from_grid(next_point.x, next_point.y))

      puts next_point_real.inspect

      move.speed, move.strafe_speed = dummy_go_to next_point_real

      debug if ENV['DEBUG']
    end

    private

    MAX_SEED = 10

    def dummy_go_to(point)
      speed = MAX_SEED * Math::cos(me.angle_to_unit(point))
      strafe_speed = MAX_SEED * Math::sin(me.angle_to_unit(point))

      [speed, strafe_speed]
    end

    def units
      (wizards + world.buildings + world.minions + world.trees)
    end

    def wizards
      world.wizards.find_all { |w| w.id != me.id }
    end

    def current_target
      (world.wizards + world.buildings + world.minions).flatten.find_all do |unit|
        unit.enemy_to? me
      end.sort_by { |u| u.distance_to_unit(me) }.first
    end

    def debug
      puts "#{world.tick_index} me:(x:#{me.x},y:#{me.y},a:#{me.angle}) move:(s:#{move.speed},st:#{move.strafe_speed},t:#{move.turn})"
    end

    def refresh_positions
      @positions << Point.new(me.x, me.y)

      while @positions.size > TRACE_SIZE
        @positions.shift
      end
    end

    def best_move
      world_states = generate_world_states

      best_moves = generate_moves.sort_by do |moves|
        wizard = me.clone

        moves.each_with_index do |move, i|
          world_states[i].apply_move wizard, move
        end

        rating = evalution_func(world_states[PATH_SIZE], wizard)

        rating
      end.last

      best = best_moves.first

      best.turn = me.angle_to_unit(current_target) if current_target

      best
    end

    def generate_world_states
      states = {}
      states[0] = AiBot::WorldState.new(units: (world.trees + world.minions + world.wizards + world.buildings - [me]), width: world.width, height: world.height, tick: world.tick_index, game: game)

      (1..PATH_SIZE).each do |i|
        states[i] = states[i-1].next
      end

      states
    end

    def generate_moves
      TrackGenerator.new(depth: PATH_SIZE).generate
    end

    def evalution_func(ai_world, wizard)
      v = EvalutionFunctionTop.new(world: ai_world, wizard: wizard, positions: @positions, game: game, current_target: current_target).calc

      v
    end
  end
end
