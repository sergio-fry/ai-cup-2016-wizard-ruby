module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    def move!
      m = best_move

      move.speed = m.speed
      move.turn = m.turn
    end

    private

    def best_move
      ai_world = AiBot::World.init_from(world)

      generate_moves.sort_by do |move|
        -evalution_func(simulate(ai_world, move))
      end.first
    end

    def generate_moves
      (-3..4).map do |speed|
        m = Move.new
        m.speed = speed

        m
      end
    end

    def simulate(ai_world, move)
      w = ai_world.clone
      w.tick! me.id => move

      w
    end

    def evalution_func(ai_world)
      wizard = ai_world.unit_by_id me.id

      [wizard.y, ai_world.height - wizard.y].min
    end

  end
end
