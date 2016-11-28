module AiBot
  class World
    attr_accessor :move

    def initialize(me, world, game)
      @world = world
      @game = game
      @me = me

      @wizards = @world.wizards.map { |w| AiBot::Wizard.new(w) }
    end

    def tick!(move)
      me.speed_x = move.speed

      @wizards = @wizards.map(&:clone).map { |w| w.x += w.speed_x; w.y += w.speed_y; w }
    end

    def me
      @wizards.find { |w| w.id == @me.id }
    end
  end
end
