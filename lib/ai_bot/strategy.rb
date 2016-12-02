module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    TRACE_SIZE = 100
    PATH_SIZE = 3

    def initialize
      @positions = []
    end

    def move!
      refresh_positions

      m = best_move
      move.speed = m.speed
      move.turn = m.turn

      debug if ENV['DEBUG']
    end

    private

    def current_target
      (world.wizards + world.buildings + world.minions).flatten.find_all do |unit|
        unit.enemy_to? me
      end.sort_by { |u| u.distance_to_unit(me) }.first
    end

    def debug
      puts "#{world.tick_index}, me: (#{me.x},#{me.y}), angle: #{me.angle} speed: #{move.speed}, angle: #{move.turn}"
    end

    def refresh_positions
      @positions << Point.new(me.x, me.y)

      while @positions.size > TRACE_SIZE
        @positions.shift
      end
    end

    def best_move
      world_states = generate_world_states

      best_moves = generate_moves.repeated_combination(PATH_SIZE).reject{ |moves| reject_move_sequence?(moves) }.sort_by do |moves|

        wizard = me.clone

        moves.each_with_index do |move, i|
          world_states[i].apply_move wizard, move
        end

        rating = evalution_func(world_states[PATH_SIZE], wizard)

        rating
      end.last

      best_moves.first
    end

    def generate_world_states
      states = {}
      states[0] = AiBot::WorldState.new(units: (world.trees + world.minions + world.wizards + world.buildings - [me]), width: world.width, height: world.height, tick: world.tick_index, game: game)

      (1..PATH_SIZE).each do |i|
        states[i] = states[i-1].next
      end

      states
    end

    def reject_move_sequence?(moves)
      moves.any? { |m| m.speed != moves.first.speed } ||
        (0..moves.size-2).any? { |i| moves[i].turn * moves[i+1].turn < 0 }
    end

    def generate_moves
      [ 0, game.wizard_max_turn_angle, -game.wizard_max_turn_angle ].map do |angle|
        [-3, 0, 4].map do |speed|
          m = Move.new
          m.speed = speed
          m.turn = angle

          m
        end
      end.flatten
    end

    def evalution_func(ai_world, wizard)
      v = EvalutionFunction.new(world: ai_world, wizard: wizard, positions: @positions, game: game, current_target: current_target).calc

      v
    end
  end
end
