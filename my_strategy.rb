require './model/wizard'
require './model/game'
require './model/move'
require './model/world'

class MyStrategy
  LOW_HP_FACTOR = 0.25
  WAYPOINT_RADIUS = 100

  def initialize
    @waypoints_by_lane = {}
  end

  # @param [Wizard] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    initialize_strategy(me, game)
    initialize_tick(me, world, game, move)

    # Постоянно двигаемся из-стороны в сторону, чтобы по нам было сложнее попасть.
    # Считаете, что сможете придумать более эффективный алгоритм уклонения? Попробуйте! ;)
    move.strafe_speed =  (random_bool ? 1 : -1) * game.wizard_strafe_speed

    # Если осталось мало жизненной энергии, отступаем к предыдущей ключевой точке на линии.
    if me.life < me.max_life * LOW_HP_FACTOR
      go_to previous_waypoint

      return
    end

    nearest_target = get_nearest_target

    if nearest_target != nil
      distance = distance_to(nearest_target)

      if distance <= @me.cast_range
        angle = @me.angle_to(nearest_target.x, nearest_target.y)

        move.turn = angle

        if angle.abs < @game.staff_sector / 2
          @move.action = ActionType::MAGIC_MISSILE
          @move.cast_angle angle
          @move.min_cast_distance = distance - nearest_target.radius + @game.magic_missile_radius
        end

        return
      end
    end

    go_to next_waypoint
  end

  private

  def distance_to(point)
    p1 = Point2D.new(point.x, point.y)
    p2 = Point2D.new(@me.x, @me.y)

    p1.distance_to(p2)
  end

  def get_nearest_target
    targets = []
    targets.concat @world.buildings
    targets.concat @world.wizards
    targets.concat @world.minions

    targets.reject do |target|
      target.faction == Faction::NEUTRAL || target.faction == @me.faction
    end.sort do |target|
      @me.get_distance_to(target.x, target.y)
    end.first
  end

  def next_waypoint
    last_waypoint_index = @waypoints.size - 1
    last_waypoint = @waypoints[last_waypoint_index]

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

  def go_to(point)
    angle = @me.get_angle_to(@me.x, @me.y)
    @move.turn = angle

    if angle.abs < @game.staff_sector / 4
      @move.speed = @game.wizard_forward_speed
    end
  end

  def initialize_tick(me, world, game, move)
    @me = me
    @world = world
    @game = game
    @move = move
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
    else
    end
  end

  def random_bool
    @random.rand > 0.5
  end

  class Point2D
    attr_reader :x, :y

    def initialize(x, y)
      @x, @y = x, y
    end

    def distance_to(point)
      (point.x - x) ** 2 + (point.y - y) ** 2
    end
  end
end
