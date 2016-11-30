module AiBot
  class EvalutionFunction
    attr_reader :world, :wizard, :positions

    def initialize(world, wizard, positions)
      @world = world
      @wizard = @world.unit_by_id wizard.id
      @positions = positions
    end

    def calc
      close_units = world.units.reject { |u| u.id == wizard.id }
        .find_all { |u| wizard.distance_to_unit(u) < 300 }

      collision_score = close_units.map { |u| distance_score(u) }.inject(&:+) || 0


      stop_penalty = positions.last.distance_to(wizard) <= 0.1 ? 1 : 0

      -1 * edges_score - 1 * collision_score + 0.0001 * new_places_score # - 100 * stop_penalty
    end

    private

    def new_places_score
      return 0 if positions.size == 0

      new_places = positions.map do |position|
        wizard.distance_to_unit position
      end.inject(&:+) / positions.size
    end

    def edges_score
      d = [
        wizard.x,
        wizard.y,
        world.width - wizard.x,
        world.height - wizard.y
      ].min

      return 0 if d > 100

      (d < 1) ? 1000 : 1 / d ** 2
    end

    def distance_score(unit, max_distance=nil)
      r = unit.respond_to?(:radius) ? unit.radius : 0
      d = (wizard.distance_to_unit(unit) - r - wizard.radius)

      (d < 1) ? 1000 : 1 / d ** 2
    end
  end
end
