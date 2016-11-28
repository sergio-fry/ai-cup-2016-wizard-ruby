module AiBot
  class Wizard
    attr_accessor :id, :x, :y, :speed_x, :speed_y

    def initialize(wizard)
      @id = wizard.id
      @x = wizard.x
      @y = wizard.y
      @speed_x = wizard.speed_x
      @speed_y = wizard.speed_y
    end
  end
end
