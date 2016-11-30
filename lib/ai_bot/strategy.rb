module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    TRACE_SIZE = 500
    PATH_SIZE = 4

    def initialize
      @positions = []
    end

    def move!
      refresh_positions

      m = best_move
      move.speed = m.speed
      move.turn = m.turn

      debug

    end

    private

    def debug
      return unless ENV['DEBUG']

      puts "#{world.tick_index}, me: (#{me.x},#{me.y}) speed: #{move.speed}, angle: #{move.turn}"
    end

    def refresh_positions
      @positions << Point.new(me.x, me.y)
      while @positions.size > TRACE_SIZE
        @positions.shift
      end
    end

    def best_move
      ai_world = AiBot::World.init_from(world)

      ai_world2 = AiBot::WorldState.new(units: (world.trees + world.minions + world.wizards + world.buildings - [me]))

      generate_moves.repeated_combination(PATH_SIZE).reject{ |moves| reject_move_sequence?(moves) }.sort_by do |moves|
        -evalution_func(simulate(ai_world, moves))
      end.first.first
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

    def simulate(ai_world, moves)
      w = ai_world.clone

      moves.each do |m|
        w.tick! me.id => m
      end

      w
    end

    def evalution_func(ai_world)
      v = EvalutionFunction.new(ai_world, me, @positions).calc

      v
    end
  end
end
