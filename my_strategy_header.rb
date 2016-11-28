require './model/wizard'
require './model/game'
require './model/move'
require './model/world'

class MyStrategy
  def initialize(algo='current')
    @strategy = AiBot::Strategy.new
  end

  def move(me, world, game, move)
    @strategy.me = me
    @strategy.world = world
    @strategy.game = game
    @strategy.move = move

    @strategy.move!
  end
end
