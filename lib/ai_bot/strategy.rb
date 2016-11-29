module AiBot
  class Strategy
    attr_accessor :me, :world, :game, :move

    def move!
      m = best_move

      move.speed = m.speed
      move.turn = m.turn

      #puts "#{world.tick_index} speed: #{move.speed}, angle: #{move.turn}"
    end

    private

    def best_move
      ai_world = AiBot::World.init_from(world)

      generate_moves.repeated_combination(3).sort_by do |moves|
        -evalution_func(simulate(ai_world, moves))
      end.first.first
    end

    def generate_moves
      [ 0, game.wizard_max_turn_angle, -game.wizard_max_turn_angle ].map do |angle|
        [-3, 4].map do |speed|
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
      wizard = ai_world.unit_by_id me.id

      edges = [
        wizard.x,
        wizard.y,
        ai_world.width - wizard.x,
        ai_world.height - wizard.y
      ].min

      corners = [
        wizard.distance_to_unit(Point.new(0, 0)),
        wizard.distance_to_unit(Point.new(0, 4000)),
        wizard.distance_to_unit(Point.new(4000, 0)),
        wizard.distance_to_unit(Point.new(4000, 4000)),
      ].min

      min_dist_to_unit = ai_world.units.reject { |u| u.id == wizard.id }.map { |u| wizard.distance_to_unit(u) - u.radius - wizard.radius }.min
      collision_penalty = min_dist_to_unit < wizard.radius * 4 ? -wizard.radius / [min_dist_to_unit, 0.00001].max : 0

      #puts "#{edges}, #{corners}, #{collision_penalty}"

      edges + corners * 2 + 10 * collision_penalty
    end

  end
end
