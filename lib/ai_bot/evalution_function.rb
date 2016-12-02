module AiBot
  class EvalutionFunction
    MAX_EDGE_DIST = 100

    attr_reader :world, :wizard, :positions

    def initialize(world, wizard, positions)
      @world = world
      @wizard = wizard
      @positions = positions
    end

    def calc
      -1 * edges_score - 1 * collision_score + 0.0001 * new_places_score
    end

    private

    def collision_score
      close_units = world.units
        .find_all { |u| wizard.distance_to_unit(u) < 300 }

      close_units.map { |u| distance_score(u) }.inject(&:+) || 0
    end

    def new_places_score
      return 0 if positions.size == 0

      new_places = positions.map do |position|
        wizard.distance_to_unit position
      end.inject(&:+) / positions.size
    end

    def edges_score
      [
        Point.new(wizard.x, 0),
        Point.new(0, wizard.y),
        Point.new(world.width - wizard.x, 0),
        Point.new(0, world.height - wizard.y),
      ].map do |projection|
        distance_score(projection, max_distance: MAX_EDGE_DIST)
      end.inject(&:+)
    end

    def distance_score(unit, max_distance: nil)
      r = unit.respond_to?(:radius) ? unit.radius : 0
      d = (wizard.distance_to_unit(unit) - r - wizard.radius)

      return 0 if d > max_distance unless max_distance.nil?

      (d < 1) ? 1000 : 1 / d ** 2
    end
  end
end
