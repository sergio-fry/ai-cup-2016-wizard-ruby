require './model/wizard'
require './model/game'
require './model/move'
require './model/world'

MAP_SIZE = 4000

class Line
  attr_reader :start, :end
  def initialize(x1, y1, x2, y2)
    @start = Point.new x1, y1
    @end = Point.new x2, y2
  end

  def include?(point, epsilon=0.1)
    delta = (start.y - self.end.y) * point.x + (self.end.x - start.x) * point.y + (start.x * self.end.y - self.end.x * start.y)

    delta.abs < epsilon
  end

  def to_s
    "Line(#{start}-#{self.end})"
  end

  def mirror
    Line.new (MAP_SIZE - self.start.y), (MAP_SIZE - self.start.x), (MAP_SIZE - self.end.y), (MAP_SIZE - self.end.x)
  end
end

class Router
  WAYPOINT_RADIUS = 50
  attr_reader :waylines

  def initialize(waylines)
    @waylines = waylines
  end

  def next_waypoint(position)
    current_wayline(position).end rescue nil
  end

  def previous_waypoint(position)
    current_wayline(position, :backword).start rescue nil
  end

  def mirror
    waylines_mirror = waylines.map do |line|
      line.mirror
    end.to_a

    self.class.new waylines_mirror
  end

  private

  def current_wayline(position, direction=:forward)
    if @current_direction != direction
      @current_direction = direction
      @previous_waypoint = nil
    end

    unless @current_wayline.nil? 
      endpoint = direction == :forward ? @current_wayline.end : @current_wayline.start

      if endpoint.distance_to(position) < WAYPOINT_RADIUS
        @previous_wayline = @current_wayline
      end
    end

    @current_wayline = waylines.reject do |line|
      line == @previous_wayline
    end.sort_by do |line|
      #projection_of_point_to_line(position, line).distance_to(position)
      distance_from_point_to_line(position, line)
    end.first

    @current_wayline
  end

  def distance_from_point_to_line(point, line)
    x1, y1 = line.start.x, line.start.y
    x2, y2 = line.end.x, line.end.y

    a = (y1 - y2)
    b = (x2 - x1)
    c = (x1 * y1 - x2 * y1)

    (a * point.x + b * point.y + c).abs / Math::sqrt(a ** 2 + b ** 2)
  end

  def projection_of_point_to_line(point, line)
    a = line.start
    b = line.end
    s = point

    k = ((s.x - a.x) * (b.x - a.x) + (s.y - a.y) * (b.y - a.y)) / ((b.x - a.x) ** 2 + (b.y - a.y) ** 2)

    Point.new(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k)
  end
end

class Cache
  attr_accessor :tick

  def initialize
    @data = {}
    @meta = {}
  end

  def fetch(key, options={}, &block)
    return read(key) if exists? key

    v = yield

    write key, v, options
  end

  def write(key, value, options={})
    expires_in = options[:expires_in]
    @data[key.to_s] = value
    @meta[key.to_s] = { expires_in: expires_in, created_at: tick }

    value
  end

  def read(key)
    return unless @data.has_key? key.to_s
    delete(key) if age(key) > @meta[key.to_s][:expires_in].to_i
    @data[key.to_s]
  end

  def exists?(key)
    !read(key).nil?
  end

  def delete(key)
    @data.delete key.to_s
    @meta.delete key.to_s
  end

  def age(key)
    tick - @meta[key.to_s][:created_at]
  end
end

class StrategyBase
  WAYPOINT_RADIUS = 100
  LOW_HP_FACTOR = 0.3
  HIGH_HP_FACTOR = 0.7

  PATH_FINDER_SECTORS = 8
  MAX_SEED = 10

  POTENTIALS = {
    Building: -0.3,
    edge: -0.3,
    corner: -1,
    target: 10,
    anti_target: 0,
    default: -1,
  }

  attr_accessor :me, :world, :game, :move

  def initialize
    @bonus_strategy ||= StrategyBonus.new
  end

  def move!
    @bonus_strategy.me = me
    @bonus_strategy.world = world
    @bonus_strategy.game = game
    @bonus_strategy.move = move

    if healthy? && @bonus_strategy.should_search_for_bonus?
      @bonus_strategy.move!
    else
      go_to next_waypoint
      attack current_target
      keep_safe_distance
    end
  end

  private

  def my_position
    Point.new(me.x, me.y)
  end

  def cooldown?
    @me.remaining_cooldown_ticks_by_action[ActionType::MAGIC_MISSILE] > 25
  end

  def tick
    @world.tick_index
  end

  def map_size
    @game.map_size
  end

  def next_waypoint
    return cache.read(:next_waypoint) if cache.exists?(:next_waypoint)

    p = router.next_waypoint Point.new(@me.x, @me.y)

    cache.write(:next_waypoint, p, expires_in: [50, distance_to(p) / 2].min)
  end

  def previous_waypoint
    return cache.read(:previous_waypoint) if cache.exists?(:previous_waypoint)

    p = router.previous_waypoint Point.new(@me.x, @me.y)

    cache.write(:previous_waypoint, p, expires_in: [50, distance_to(p) / 2].min)
  end

  def router
    @router ||= Router.new([
      Line.new(100, map_size - 100, map_size - 200, 200),
    ])
  end

  private

  def cache
    @cache ||= Cache.new
    @cache.tick = tick

    @cache
  end

  def potential_field_value_for place
    objects = (@world.buildings + @world.trees + @world.minions + @world.wizards).reject do |unit|
      me?(unit) || distance_to(unit) > @me.cast_range
    end.map do |unit|
      dist = (place.distance_to(unit) - unit.radius - @me.radius)

      v = (POTENTIALS[unit.class] || POTENTIALS[:default]) / dist ** 2

      case unit
      when Tree
        v = 0 if dist > 1000
      else
        v = 0 if dist > 50
      end

      v
    end.inject(&:+).to_f

    edges = 0
    edges += POTENTIALS[:edge] / (place.x.to_f - @me.radius) ** 2
    edges += POTENTIALS[:edge] / (place.y.to_f - @me.radius) ** 2
    edges += POTENTIALS[:edge] / (map_size - place.x + @me.radius).to_f ** 2
    edges += POTENTIALS[:edge] / (map_size - place.y + @me.radius).to_f ** 2

    corners = 0
    corners += POTENTIALS[:corner] / place.distance_to(Point.new(0, 0))
    corners += POTENTIALS[:corner] / place.distance_to(Point.new(map_size, 0))
    corners += POTENTIALS[:corner] / place.distance_to(Point.new(0, map_size))
    corners += POTENTIALS[:corner] / place.distance_to(Point.new(map_size, map_size))

    objects + edges + corners
  end

  def me?(unit)
    distance_to(unit) < @me.radius
  end

  def keep_safe_distance
    unless nearest_enemy.nil?
      run_away if distance_to(nearest_enemy) < @me.cast_range * 0.7
      run_away if distance_to(nearest_enemy) < @me.cast_range * 1.5 if hurts? 
      run_away unless has_friend_closer_to_enemy?

      # TODO: count safe range for each unit type
    end

    #run_away if cooldown?
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
      nearest_enemy.get_distance_to_unit(unit) < (distance_to(nearest_enemy) - @me.cast_range * 0.1)
    end
  end

  def hurts?
    @me.life < @me.max_life * LOW_HP_FACTOR
  end

  def healthy?
    @me.life > @me.max_life * HIGH_HP_FACTOR
  end

  def run_away
    go_to previous_waypoint
  end

  def nearest_places
    (0..Math::PI * 2).step(Math::PI / PATH_FINDER_SECTORS).map do |angle|
      x1 = Math::cos(angle) * @me.radius + @me.x
      y1 = Math::sin(angle) * @me.radius + @me.y

      Point.new x1, y1
    end
  end

  def attack(unit)
    return if unit.nil?
    return if distance_to(unit) > @me.cast_range

    turn_to unit

    if angle_to(unit).abs < @game.staff_sector / 2

      if distance_to(nearest_enemy) < game.staff_range
        turn_to nearest_enemy
        @move.action = ActionType::STAFF
      elsif distance_to(nearest_tree) < game.staff_range
        turn_to nearest_tree
        @move.action = ActionType::STAFF
      else
        @move.action = ActionType::MAGIC_MISSILE
        @move.cast_angle = angle_to unit
        @move.min_cast_distance = distance_to(unit) - unit.radius + @game.magic_missile_radius
      end
    end
  end

  def nearest_tree
    @world.trees.sort_by do |unit|
      distance_to(unit)
    end.first
  end

  def distance_to(point)
    p1 = Point.new(point.x, point.y)

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

  def nearest_enemy
    enemies.sort_by do |unit|
      distance_to(unit)
    end.first
  end

  def angle_to(point)
    @me.get_angle_to(point.x, point.y)
  end

  def turn_to(point)
    @move.turn = angle_to point
  end

  def mirror_point_of(point)
    Point.new(@me.x + (@me.x - point.x), @me.y + (@me.y - point.y))
  end

  def go_to(point, options={})
    return if point.nil?

    places = nearest_places.sort_by do |place|
      v = potential_field_value_for(place) +
        (POTENTIALS[:target] / place.distance_to(point))

      v
    end

    # go to place with max potential value
    dummy_go_to_with_turn places.last, current_target
  end

  def dummy_go_to_with_turn(point, target)
    turn_to target if target

    @move.strafe_speed = MAX_SEED * Math::sin(@me.angle_to_unit(point))
    @move.speed = MAX_SEED * Math::cos(@me.angle_to_unit(point))
  end
end

class StrategyTop < StrategyBase
  def router
    @router ||= Router.new([
      # TOP main line
      Line.new(200, 3200, 200, 800), # bottom-left -> top-left
      Line.new(200, 800, 800, 200),
      Line.new(800, 200, 3400, 200),

      Line.new(2000, 2000, 500, 500), # middle -> left-top
    ])
  end
end

class StrategyBonus < StrategyBase
  TIME_TO_SEARCH = 1000
  BONUS_PERIOD = 2500

  def initialize
  end

  def move!
    attack current_target
    go_to next_waypoint
    go_to bonus if see_bonus?
  end

  def should_search_for_bonus?
    if tick < 1000
      false
    elsif bonus_has_gone?
      false
    else
      time_before_next_bonus < (TIME_TO_SEARCH / 2) || time_after_previous_bonus < (TIME_TO_SEARCH / 2)
    end
  end

  private

  def time_before_next_bonus
    BONUS_PERIOD - tick % BONUS_PERIOD
  end

  def time_after_previous_bonus
    tick % BONUS_PERIOD
  end

  def router
    @router ||= Router.new([
      # TOP main line
      Line.new(200, 3200, 200, 800),
      Line.new(200, 800, 700, 700),

      Line.new(700, 700, 1100, 1100),
      Line.new(1100, 1100, 1300, 1300),

      Line.new(3400, 200, 800, 200),
      Line.new(800, 200, 700, 700),
    ])
  end

  def bonus
    @world.bonuses.sort_by { |b| distance_to(b) }.first
  end

  def see_bonus?
    v = !@world.bonuses.empty?

    if v
      @bonus_exists = true
    end

    v
  end

  def next_time_to_search_bonus
    n = tick / BONUS_PERIOD 

    t = n * BONUS_PERIOD + (BONUS_PERIOD - TIME_BEFORE_BONUS_BORN)
  end

  def bonus_has_gone?
    v = @bonus_exists && distance_to(Point.new(1200, 1200)) < @me.vision_range && !see_bonus?
    @bonus_exists = false if v

    v
  end
end

class StrategyMiddle < StrategyBase
  def router
    @router ||= Router.new([
      Line.new(600, 3400, 2000, 2000),
      Line.new(2000, 2000, 3400, 600),

      #Line.new(200, 800, 200, 3200),
      #Line.new(200, 800, 200, 3200).mirror,

      #Line.new(200, 200, 2000, 2000),
      #Line.new(200, 200, 2000, 2000).mirror,

      #Line.new(3400, 200, 800, 200),
      #Line.new(3400, 200, 800, 200).mirror,
    ])
  end
end

class StrategyBottom < StrategyTop
  def router
    @router ||= super.mirror
  end
end

class StrategyTreeKiller < StrategyBase
  def move!
    go_to nearest_tree
    turn_to nearest_tree

    if distance_to(nearest_tree) < game.staff_range
      @move.action = ActionType::STAFF
    end
  end
end

class CurrentWizard
  def move!(me, world, game, move)
    initialize_tick(me, world, game, move)
    initialize_strategy
    @strategy.move!
  end

  private

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

    @strategy ||= klass.new
    @strategy.me = @me
    @strategy.world = @world
    @strategy.game = @game
    @strategy.move = @move
  end
end

class NewWizard < CurrentWizard
end

class MyStrategy
  def initialize(algo='current')
    if algo == 'current'
      @wizard = CurrentWizard.new
    else
      @wizard = NewWizard.new
    end
  end

  # @param [Wizard] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    @wizard.move! me, world, game, move
  end
end

class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x, @y = x.to_f, y.to_f
  end

  def distance_to(point)
    Math::hypot(point.x - @x, point.y - @y)
  end

  def mirror
    self.class.new -x, -y
  end

  def to_s
    "(#{@x}, #{@y})"
  end
end
