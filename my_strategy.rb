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

class Wayline
  def initialize(*points)
    @points = points
  end

  def next_waypoint(position)
    p = nearest_to(position)

    index = @points.find_index(p)

    @points[index + 1]
  end

  def previous_waypoint(position)
    p = nearest_to(position)

    index = @points.find_index(p)

    return nil if index == 0
    @points[index - 1]
  end

  private

  def nearest_to(point)
    @points.sort_by { |p| p.distance_to(point) }.first
  end
end

class Router
  attr_reader :waylines

  def initialize(*waylines)
    @waylines = waylines
  end

  def next_waypoint(position)
    waylines.map { |p| p.next_waypoint(position) }
      .compact.sort_by do |p|
      p.distance_to(position)
    end.first
  end

  def previous_waypoint(position)
    waylines.map { |p| p.previous_waypoint(position) }
      .compact.sort_by do |p|
      p.distance_to(position)
    end.first
  end

  def mirror
    waylines_mirror = waylines.map do |line|
      line.mirror
    end.to_a

    self.class.new waylines_mirror
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
  LOW_HP_FACTOR = 0.3

  PATH_FINDER_SECTORS = 8
  MAX_SEED = 10

  DISTANCE_GAP = 50

  POTENTIALS = {
    Wizard => -1,
    Minion => -0.5,
    Tree => -0.2,
    Building => -0.3,

    edge: -0.3,
    corner: -1,
    target: 5,
    anti_target: 0,
    default: -2,
    enemy_k: 2,
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
      return if tick < 50

      if next_waypoint
        turn_to next_waypoint
        go_to next_waypoint, reason: 'Next waypoint'
      else
        go_to previous_waypoint, reason: 'Prev waypoint'
      end

      attack current_target
      stop unless current_target.nil?
      keep_safe_distance
    end
  end

  private

  def stop
    move.speed = 0
    move.strafe_speed = 0
  end

  def my_position
    Point.new(me.x, me.y)
  end

  def cooldown?
    @me.remaining_cooldown_ticks_by_action[ActionType::MAGIC_MISSILE] > 10
  end

  def tick
    @world.tick_index
  end

  def map_size
    @game.map_size
  end

  def next_waypoint
    cache.fetch(:next_waypoint, expires_in: 50) do
      router.next_waypoint Point.new(@me.x, @me.y)
    end
  end

  def previous_waypoint
    cache.fetch(:previous_waypoint, expires_in: 50) do
      router.previous_waypoint Point.new(@me.x, @me.y)
    end
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

      k = (POTENTIALS[unit.class] || POTENTIALS[:default])
      v = dist <= 0 ? k : k / dist ** 2

      v = 0 if dist > 500

      v *= POTENTIALS[:enemy_k] if enemy?(unit)

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
      run_away(reason: 'too close to minion') if too_close_to_minion?
      run_away(reason: 'has no friend closer to enemy') unless has_friend_closer_to_enemy? # unless healthy?
      run_away(reason: 'hurts') if can_be_damaged? if hurts? 
    end

    #run_away if cooldown? && !current_target.nil?
  end

  def safe_distance_from(unit)
    attack_distance = 0

    attack_distance = case unit
                      when Minion
                        case unit.type
                        when MinionType::ORC_WOODCUTTER
                          game.orc_woodcutter_attack_range
                        when MinionType::FETISH_BLOWDART
                          game.fetish_blowdart_attack_range
                        end
                      when Building
                        unit.attack_range
                      when Wizard
                        unit.cast_range
                      else
                        0
                      end

    attack_distance + @me.radius + unit.radius + DISTANCE_GAP
  end

  def too_close_to_minion?
    enemies(Minion).any? do |unit|
      distance_to(unit) < safe_distance_from(unit)
    end
  end

  def can_be_damaged?
    enemies.any? { |u| distance_to(u) < safe_distance_from(u) }
  end

  def current_target
    reachable_enemies.sort_by do |unit|
      k = case unit
          when Wizard
            3 + Math::hypot(unit.speed_x, unit.speed_y) / game.wizard_forward_speed
          when Building
            6
          when Minion
            2 + Math::hypot(unit.speed_x, unit.speed_y) / game.wizard_forward_speed
          else
            6
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
    # minions are ignored because we a re keeping safe dist from em already
    arr = enemies(Wizard) + enemies(Building)

    return true if arr.empty?

    arr.any? do |enemy|
      distance_to(enemy) > friends.map { |f| f.distance_to_unit(enemy) }.sort.min
    end
  end

  def hurts?
    @me.life < @me.max_life * LOW_HP_FACTOR
  end

  def healthy?
    !hurts?
  end

  def run_away(options={})
    go_to previous_waypoint, reason: (options[:reason] || 'Run away')
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
      if distance_to(nearest_enemy) < (game.staff_range + me.radius + nearest_enemy.radius)
        turn_to nearest_enemy
        @move.action = ActionType::STAFF
      elsif distance_to(nearest_tree) < (game.staff_range + me.radius + nearest_enemy.radius)
        turn_to nearest_tree
        @move.action = ActionType::STAFF
      else
        @move.action = ActionType::MAGIC_MISSILE
        @move.cast_angle = angle_to unit
        @move.min_cast_distance = distance_to(unit) - unit.radius * 2 + @game.magic_missile_radius
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

  def enemies(klass=LivingUnit)
    units = []
    units.concat @world.buildings
    units.concat @world.wizards
    units.concat @world.minions

    units.flatten.find_all do |unit|
      enemy? unit
    end.reject do |unit|
      !unit.is_a?(klass)
    end
  end

  def enemy?(unit)
    !(unit.faction == Faction::NEUTRAL || unit.faction == @me.faction)
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

  def log(tag, msg)
    @logger ||= {}
    @logger[tag] = msg
  end

  def go_to(point, options={})
    return if point.nil?

    log :go_to, "go_to #{point}, pos: (#{me.x.round},#{me.y.round}), #{options[:reason]}"

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
    go_to next_waypoint, reason: 'Seek for bonus'
    go_to(bonus, reason: 'To bonus') if see_bonus?
  end

  def should_search_for_bonus?
    if see_bonus?
      true
    elsif tick < 1000
      false
    elsif bonus_has_gone?
      false
    else
      time_before_next_bonus < (TIME_TO_SEARCH / 2) || time_after_previous_bonus < (TIME_TO_SEARCH / 2)
    end
  end

  private

  def run_away
    return if enemies.empty?

    sum_x, sum_y = 0, 0 

    enemies.each do |unit|
      sum_x += unit.x
      sum_y += unit.y
    end

    dx = me.x - (sum_x.to_f / enemies.size)
    dy = me.y - (sum_y.to_f / enemies.size)

    target = Point.new(me.x + dx, me.y + dy)

    go_to target, reason: 'Run aways (bonus)'
  end

  def time_before_next_bonus
    BONUS_PERIOD - tick % BONUS_PERIOD
  end

  def time_after_previous_bonus
    tick % BONUS_PERIOD
  end

  def router
    @router ||= Router.new(
      Wayline.new(
        Point.new(600, 3400),
        Point.new(1900, 2100),
        Point.new(2700, 2700),
        Point.new(2900, 2900),
      ),
      Wayline.new(
        Point.new(3400, 600),
        Point.new(2100, 1900),
        Point.new(2700, 2700),
        Point.new(2900, 2900),
      ),
    )
  end

  def bonus
    @world.bonuses.sort_by { |b| distance_to(b) }.first
  end

  def see_bonus?
    !bonus.nil?
  end

  def bonus_has_gone?
    distance_to(Point.new(2800, 2800)) < @me.vision_range && !see_bonus? && time_after_previous_bonus < TIME_TO_SEARCH
  end
end

class StrategyMiddle < StrategyBase
  def router
    @router ||= Router.new(
      Wayline.new(
        Point.new(800, 3200),
        Point.new(1700, 2300),
        Point.new(2000, 2000),
        Point.new(2300, 1700),
        Point.new(3400, 600),
        Point.new(3400, 601),
      ),
      Wayline.new(
        Point.new(100, 2800),
        Point.new(400, 3400),
        Point.new(800, 3200),
      ),

      #back from right bonus
      Wayline.new(
        Point.new(2800, 2800),
        Point.new(2300, 2300),
        Point.new(1500, 1500),
      ),
    )
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
    @random = Random.new(game.random_seed)
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

    klass = StrategyMiddle

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
