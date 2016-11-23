require './model/wizard'
require './model/game'
require './model/move'
require './model/world'

class StrategyBase
  def initialize(me, world, game, move)
    @me, @world, @game, @move = me, world, game, move
  end

  def map_size
    @game.map_size
  end
end

class StrategyTop < StrategyBase
  def waypoints
    [
      Point2D.new(100, map_size - 100),
      Point2D.new(200, map_size * 0.25),
      Point2D.new(400, 400),
      Point2D.new(map_size * 0.75, 200),
      Point2D.new(map_size - 200, 200),
    ]
  end
end

class StrategyMiddle < StrategyBase
  def waypoints
    [
      Point2D.new(100, map_size - 100),
      Point2D.new(600, map_size - 200),
      Point2D.new(800, map_size - 800),
      Point2D.new(map_size - 600, 600),
    ]
  end
end

class StrategyBottom < StrategyBase
  def waypoints
    [
      Point2D.new(100, map_size - 100),
      Point2D.new(map_size * 0.75, map_size - 200),
      Point2D.new(map_size - 400, map_size - 400),
      Point2D.new(map_size - 200, map_size * 0.25),
      Point2D.new(map_size - 200, 200),
    ]
  end
end

class CurrentStrategy
  LOW_HP_FACTOR = 0.35
  WAYPOINT_RADIUS = 100

  PATH_FINDER_SECTORS = 8

  POTENTIALS = {
    Building => -2,
    Minion => -0.5,
    Tree => -1,
    Wizard => -0.5,
    edge: -0.3,
    corner: -1,
    target: 10,
    default: -1,
    magic_fix: -3,
  }

  def initialize
    @waypoints_by_lane = {}
  end

  def move(me, world, game, move)
    initialize_tick(me, world, game, move)
    initialize_strategy

    go_to next_waypoint
    attack current_target

    keep_safe_distance
  end

  private

  def point
    Point2D.new @me.x, @me.y
  end

  def potential_field_value_for place, point
    objects = (@world.buildings + @world.trees + @world.minions + @world.wizards).reject do |unit|
      me?(unit) || distance_to(unit) > @me.cast_range
    end.map do |unit|
      (POTENTIALS[unit.class] || POTENTIALS[:default]) / (place.distance_to(unit) - unit.radius - @me.radius) ** 2
    end.inject(&:+).to_f

    edges = 0
    edges += POTENTIALS[:edge] / (place.x.to_f - @me.radius) ** 2
    edges += POTENTIALS[:edge] / (place.y.to_f - @me.radius) ** 2
    edges += POTENTIALS[:edge] / (map_size - place.x + @me.radius).to_f ** 2
    edges += POTENTIALS[:edge] / (map_size - place.y + @me.radius).to_f ** 2

    corners = 0
    corners += POTENTIALS[:corner] / place.distance_to(Point2D.new(0, 0))
    corners += POTENTIALS[:corner] / place.distance_to(Point2D.new(map_size, 0))
    corners += POTENTIALS[:corner] / place.distance_to(Point2D.new(0, map_size))
    corners += POTENTIALS[:corner] / place.distance_to(Point2D.new(map_size, map_size))

    magic_fix = 0
    magic_fix += POTENTIALS[:magic_fix] / place.distance_to(Point2D.new(1000, 1000))
    magic_fix += POTENTIALS[:magic_fix] / place.distance_to(Point2D.new(3000, 3000))

    target = POTENTIALS[:target] / place.distance_to(point)

    objects + edges + corners + target + magic_fix
  end

  def me?(unit)
    distance_to(unit) < @me.radius
  end

  def home
    Point2D.new(400, @game.map_size - 400)
  end

  def keep_safe_distance
    run_away if hurts?
    run_away unless has_friend_closer_to_enemy? unless nearest_enemy.nil?
  end

  def current_target
    reachable_enemies.sort_by do |unit|
      k = case unit
          when Wizard, Building
            1
          else
            3
          end

      k * (unit.life.to_f / unit.max_life)
    end.first
  end

  def reachable_enemies
    enemies.reject do |unit|
      distance_to(unit) > @me.cast_range
    end
  end

  def has_friend_closer_to_enemy?
    friends.any? do |unit|
      nearest_enemy.get_distance_to_unit(unit) < distance_to(nearest_enemy)
    end
  end

  def hurts?
    @me.life < @me.max_life * LOW_HP_FACTOR
  end

  def run_away
    places = nearest_places.sort_by do |place|
      potential_field_value_for(place, point)
    end

    # go to place with max potential value
    dummy_go_to_with_turn home, current_target
  end

  def nearest_places
    (0..Math::PI * 2).step(Math::PI / PATH_FINDER_SECTORS).map do |angle|
      x1 = Math::cos(angle) * @me.radius + @me.x
      y1 = Math::sin(angle) * @me.radius + @me.y

      Point2D.new x1, y1
    end
  end

  def attack(unit)
    return if unit.nil?
    return if distance_to(unit) > @me.cast_range

    turn_to unit
    @move.speed = 0
    @move.strafe_speed = 0

    if angle_to(unit).abs < @game.staff_sector / 2
      @move.action = ActionType::MAGIC_MISSILE
      @move.cast_angle = angle_to unit
      @move.min_cast_distance = distance_to(unit) - unit.radius + @game.magic_missile_radius
    end
  end

  def distance_to(point)
    p1 = Point2D.new(point.x, point.y)

    p1.distance_to(@me)
  end

  def enemies
    units = []
    units.concat @world.buildings
    units.concat @world.wizards
    units.concat @world.minions

    units.flatten.reject do |unit|
      unit.faction == Faction::NEUTRAL || unit.faction == @me.faction
    end
  end

  def friends
    units = []
    units.concat @world.buildings
    units.concat @world.wizards
    units.concat @world.minions

    units.flatten.find_all do |unit|
      unit.faction == @me.faction
    end
  end

  def has_friends_nearby?
    friends.find_all do |unit|
      distance_to(unit) < @me.cast_range * 2
    end.any? do |unit|
      last_waypoint.distance_to(unit) < last_waypoint.distance_to(@me)
    end
  end

  def nearest_enemy
    enemies.sort_by do |unit|
      distance_to(unit)
    end.first
  end

  def last_waypoint
    waypoints.last
  end

  def next_waypoint
    last_waypoint_index = waypoints.size - 1

    waypoint_index = 0
    while waypoint_index < last_waypoint_index
      waypoint_index += 1
      waypoint = waypoints[waypoint_index]

      if waypoint.distance_to(@me) <= WAYPOINT_RADIUS
        return waypoints[waypoint_index + 1]
      end

      if last_waypoint.distance_to(waypoint) <= last_waypoint.distance_to(@me)
        return waypoint
      end
    end

    last_waypoint
  end

  def previous_waypoint
    first_waypoint = waypoints[0]
    waypoint_index = waypoints.size - 1

    while waypoint_index > 0
      waypoint_index -= 1
      waypoint = waypoints[waypoint_index]

      if waypoint.distance_to(@me) <= WAYPOINT_RADIUS
        return waypoints[waypoint_index - 1]
      end

      if first_waypoint.distance_to(waypoint) < first_waypoint.distance_to(@me)
        return waypoint
      end
    end

    first_waypoint
  end

  def angle_to(point)
    @me.get_angle_to(point.x, point.y)
  end

  def turn_to(point)
    @move.turn = angle_to point
  end

  def mirror_point_of(point)
    Point2D.new(@me.x + (@me.x - point.x), @me.y + (@me.y - point.y))
  end

  def go_to(point)
    return if point.nil?

    places = nearest_places.sort_by do |place|
      potential_field_value_for(place, point)
    end

    # go to place with max potential value
    dummy_go_to_with_turn places.last, current_target
  end

  def initialize_tick(me, world, game, move)
    @rndom = Random.new(game.random_seed)
    @me = me
    @world = world
    @game = game
    @move = move

    @move.action = ActionType::NONE
  end

  def initialize_strategy
    klass = case @me.owner_player_id
            when 1, 2, 6, 7
              StrategyTop
            when 3, 8
              StrategyMiddle
            when 4, 5, 9, 10
              StrategyBottom
            end

    @strategy = klass.new(@me, @world, @game, @move)
  end

  def waypoints
    @strategy.waypoints
  end

  def dummy_go_to_with_turn(point, target)
    turn_to target if target

    @move.strafe_speed = 3 * Math::sin(@me.angle_to_unit(point))
    @move.speed = 3 * Math::cos(@me.angle_to_unit(point))
  end

  def map_size
    @game.map_size
  end
end

class NewStrategy < CurrentStrategy
end

class MyStrategy
  def initialize(strategy_name='current')
    if strategy_name == 'current'
      @strategy = CurrentStrategy.new
    else
      @strategy = NewStrategy.new
    end
  end

  # @param [Wizard] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    @strategy.move me, world, game, move
  end
end

class Point2D
  attr_reader :x, :y

  def initialize(x, y)
    @x, @y = x, y
  end

  def distance_to(point)
    Math::hypot(point.x - @x, point.y - @y)
  end

  def mirror
    self.class.new -x, -y
  end
end
