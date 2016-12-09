module AiBot
  class EvalutionFunction
    MAX_EDGE_DIST = 100
    MAX_CORNER_DIST = 300

    EDGE_SCORE = -1
    CORNER_SCORE = -2
    COLLISION_SCORE = -1
    SAFE_DISTANCE_FROM_ENEMY_SCORE = -10
    LOOK_AT_TARGET_SCORE = 0

    attr_reader :world, :wizard, :positions, :game, :current_target

    def initialize(game:, world:, wizard:, positions:, current_target:)
      @game = game
      @world = world
      @wizard = wizard
      @positions = positions
      @current_target = current_target
    end

    def calc
      EDGE_SCORE * edges_score +
        CORNER_SCORE * corner_score +
        COLLISION_SCORE * collision_score +
        SAFE_DISTANCE_FROM_ENEMY_SCORE * keep_safe_distance_score + 
        LOOK_AT_TARGET_SCORE * look_at_target_score
    end

    private

    def look_at_target_score
      return 0 if current_target.nil?

      angle = wizard.angle_to_unit(current_target)

      angle == 0 ? 1000 : 1.0 / angle.abs
    end

    def closest_enemy
      enemies.sort_by do |unit|
        wizard.distance_to_unit(unit)
      end.first
    end

    def keep_safe_distance_score
      return 0 if closest_enemy.nil?

      dist = closest_enemy.distance_to_unit wizard
      safe_distance = Utils.safe_distance_from(game: game, unit: closest_enemy, wizard: wizard)

      v = safe_distance - dist

      v = [0, v].max
      v = [safe_distance, v].min

      v + 50
    end

    def enemies(klass=LivingUnit)
      world.units.find_all do |unit|
        unit.enemy_to?(wizard)
      end.reject do |unit|
        klass.is_a?(Array) ? klass.none? { |k| unit.is_a?(k) } : !unit.is_a?(klass)
      end
    end

    def collision_score
      close_units = world.units
        .find_all { |u| wizard.distance_to_unit(u) < 300 }

      close_units.map { |u| distance_score(u) }.inject(&:+) || 0
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

    def corner_score
      [
        Point.new(0, 0),
        Point.new(0, world.height),
        Point.new(world.width, 0),
        Point.new(world.width, world.height),
      ].map do |projection|
        distance_score(projection, max_distance: MAX_CORNER_DIST)
      end.inject(&:+)
    end

    def distance_score(unit, max_distance: nil)
      r = unit.respond_to?(:radius) ? unit.radius : 0
      d = (wizard.distance_to_unit(unit) - r - wizard.radius)

      return 0 if d > max_distance unless max_distance.nil?

      (d < 1) ? 999999 : 1 / d ** 2
    end
  end
end
