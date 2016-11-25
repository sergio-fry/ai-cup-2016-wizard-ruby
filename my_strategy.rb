require './model/wizard'
require './model/game'
require './model/move'
require './model/world'

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
end

class Router
  MAP_SIZE = 4000
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
      Line.new (MAP_SIZE - line.start.y), (MAP_SIZE - line.start.x), (MAP_SIZE - line.end.y), (MAP_SIZE - line.end.x)
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
    Building => -1,
    Minion => -0.1,
    Tree => -0.1,
    Wizard => -0.1,
    edge: -0.3,
    corner: -1,
    target: 10,
    anti_target: 0,
    default: -0.1,
  }

  attr_accessor :me, :world, :game, :move

  def initialize
  end

  def move!
    go_to next_waypoint
    attack current_target

    keep_safe_distance
  end

  private

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
    router.next_waypoint Point.new(@me.x, @me.y)
  end

  def previous_waypoint
    router.previous_waypoint Point.new(@me.x, @me.y)
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
      (POTENTIALS[unit.class] || POTENTIALS[:default]) / (place.distance_to(unit) - unit.radius - @me.radius) ** 2
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
      @move.action = ActionType::MAGIC_MISSILE
      @move.cast_angle = angle_to unit
      @move.min_cast_distance = distance_to(unit) - unit.radius + @game.magic_missile_radius
    end
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
  def move!
    if true #tick < 2000
      super
    else
      @strategy ||= StrategyTopBonus.new
      @strategy.me = me
      @strategy.world = world
      @strategy.game = game
      @strategy.move = move

      @strategy.move!
    end
  end

  def router
    @router ||= Router.new([
      # TOP main line
      Line.new(200, 3200, 200, 800),
      Line.new(200, 800, 800, 200),
      Line.new(800, 200, 3400, 200),
    ])
  end
end

class StrategyTopBonus < StrategyBase
  def move!
    go_to next_waypoint
    attack current_target

    keep_safe_distance

    go_to bonus if see_bonus?
  end

  private

  def run_away
    go_to next_waypoint
  end

  def bonus
    @world.bonuses.sort_by { |b| distance_to(b) }.first
  end

  def see_bonus?
    !@world.bonuses.empty?
  end

  def router
    @router ||= Router.new([
      # from bottom to left-top
      Line.new(100, map_size - 100, 200, 800),
      Line.new(200, 800, 500, 500),

      # from right-top to left-top
      Line.new(map_size - 100, 100, 800, 200),
      Line.new(800, 200, 500, 500),

      # from left-top to bonus
      Line.new(500, 500, 1100, 1100),
    ])
  end

end

class StrategyMiddle < StrategyBase
  def router
    @router ||= Router.new([
      Line.new(600, 3400, 3400, 600),
    ])
  end
end

class StrategyBottom < StrategyTop
  def router
    @router ||= super.mirror
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
