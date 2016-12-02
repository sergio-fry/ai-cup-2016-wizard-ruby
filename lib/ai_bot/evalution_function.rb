module AiBot
  class EvalutionFunction
    MAX_EDGE_DIST = 100

    EDGE_SCORE = -1
    COLLISION_SCORE = -1
    NEW_PLACES_SCORE = 0.0001
    SAFE_DISTANCE_FROM_ENEMY_SCORE = -10

    attr_reader :world, :wizard, :positions, :game

    def initialize(game:, world:, wizard:, positions:)
      @game = game
      @world = world
      @wizard = wizard
      @positions = positions
    end

    def calc
      EDGE_SCORE * edges_score +
        COLLISION_SCORE * collision_score +
        NEW_PLACES_SCORE * new_places_score +
        SAFE_DISTANCE_FROM_ENEMY_SCORE * distance_from_enemy_score
    end

    private

    def distance_from_enemy_score
      return 0 if enemies.empty?

      enemies.map do |unit|
        distance_score(unit, max_distance: wizard.cast_range * 2)
      end.inject(&:+)
    end

    def enemies(klass=LivingUnit)
      world.units.flatten.find_all do |unit|
        enemy? unit
      end.reject do |unit|
        klass.is_a?(Array) ? klass.none? { |k| unit.is_a?(k) } : !unit.is_a?(klass)
      end
    end

    def enemy?(unit)
      !(unit.faction == Faction::NEUTRAL || unit.faction == wizard.faction)
    end

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
