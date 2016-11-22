require './model/wizard'
require './model/game'
require './model/move'
require './model/world'

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

class CurrentStrategy
  LOW_HP_FACTOR = 0.35
  WAYPOINT_RADIUS = 100

  # NOTE: could be decreased
  MAGIC_MISSLE_DELAY = 60

  def initialize
    @waypoints_by_lane = {}
    @strafe_direction_counter = 0
    @strafe_direction = 1
  end

  def move(me, world, game, move)
    initialize_strategy(me, game)
    initialize_tick(me, world, game, move)

    go_to next_waypoint
    attack current_target

    run_away if hurts?
    run_away unless has_friend_closer_to_enemy? unless nearest_enemy.nil?
  end

  private

  def current_target
    nearest_enemy
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
    back_to previous_waypoint
    strafe!
  end

  def step_back_from(unit)
    if previous_waypoint.nil?
      back_from unit
    else
      back_to previous_waypoint
    end

    strafe!
  end

  def strafe!
    @move.strafe_speed = strafe_direction * @game.wizard_strafe_speed
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

  def strafe_direction
    @strafe_direction_counter += 1

    if @strafe_direction_counter > @me.radius * 2.2
      @strafe_direction *= -1
      @strafe_direction_counter = 0
    end

    @strafe_direction
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
    @waypoints.last
  end

  def next_waypoint
    last_waypoint_index = @waypoints.size - 1

    waypoint_index = 0
    while waypoint_index < last_waypoint_index
      waypoint_index += 1
      waypoint = @waypoints[waypoint_index]

      if waypoint.distance_to(@me) <= WAYPOINT_RADIUS
        return @waypoints[waypoint_index + 1]
      end

      if last_waypoint.distance_to(waypoint) <= last_waypoint.distance_to(@me)
        return waypoint
      end
    end

    last_waypoint
  end

  def previous_waypoint
    first_waypoint = @waypoints[0]
    waypoint_index = @waypoints.size - 1

    while waypoint_index > 0
      waypoint_index -= 1
      waypoint = @waypoints[waypoint_index]

      if waypoint.distance_to(@me) <= WAYPOINT_RADIUS
        return @waypoints[waypoint_index - 1]
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

  def turned_to?(point)
    angle_to(point).abs < @game.staff_sector / 4
  end

  def mirror_point_of(point)
    Point2D.new(@me.x + (@me.x - point.x), @me.y + (@me.y - point.y))
  end

  def turn_from(point)
    turn_to mirror_point_of(point)
  end

  def turned_from?(point)
    angle_to(mirror_point_of(point)).abs < @game.staff_sector / 4
  end

  def go_to(point, speed: nil)
    turn_to point

    if turned_to?(point)
      @move.speed = (speed || @game.wizard_forward_speed)
    end
  end

  def back_to(point)
    turn_from point

    if turned_from?(point)
      @move.speed = -@game.wizard_backward_speed
    end
  end

  def back_from(point, speed: nil)
    turn_to point

    if turned_to?(point)
      @move.speed = -(speed || @game.wizard_backward_speed)
    end
  end

  def initialize_tick(me, world, game, move)
    @me = me
    @world = world
    @game = game
    @move = move

    @move.action = ActionType::NONE
  end

  def initialize_strategy(me, game)
    if @random == nil
      @random = Random.new(game.random_seed)

      map_size = game.map_size

      @waypoints_by_lane[LaneType::MIDDLE] = [
        Point2D.new(100, map_size - 100),
        random_bool ? Point2D.new(600, map_size - 200) : Point2D.new(200, map_size - 600),
        Point2D.new(800, map_size - 800),
        Point2D.new(map_size - 600, 600),
      ]

      @waypoints_by_lane[LaneType::TOP] = [
        Point2D.new(100, map_size - 100),
        Point2D.new(100, map_size - 400),
        Point2D.new(200, map_size - 800),
        Point2D.new(200, map_size * 0.75),
        Point2D.new(200, map_size * 0.5),
        Point2D.new(200, map_size * 0.25),
        Point2D.new(200, 200),
        Point2D.new(map_size * 0.25, 200),
        Point2D.new(map_size * 0.5, 200),
        Point2D.new(map_size * 0.75, 200),
        Point2D.new(map_size - 200, 200),
      ]

      @waypoints_by_lane[LaneType::BOTTOM] = [
        Point2D.new(100, map_size - 100),
        Point2D.new(400, map_size - 100),
        Point2D.new(800, map_size - 200),
        Point2D.new(map_size * 0.25, map_size - 200),
        Point2D.new(map_size * 0.5, map_size - 200),
        Point2D.new(map_size * 0.75, map_size - 200),
        Point2D.new(map_size - 200, map_size - 200),
        Point2D.new(map_size - 200, map_size * 0.75),
        Point2D.new(map_size - 200, map_size * 0.5),
        Point2D.new(map_size - 200, map_size * 0.25),
        Point2D.new(map_size - 200, 200),
      ]

      case me.owner_player_id
      when 1, 2, 6, 7
        @lane = LaneType::TOP
      when 3, 8
        @lane = LaneType::MIDDLE
      when 4, 5, 9, 10
        @lane = LaneType::BOTTOM
      end

      @waypoints = @waypoints_by_lane[@lane]
    end
  end

  def random_bool
    @random.rand > 0.5
  end
end

class NewStrategy < CurrentStrategy
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
