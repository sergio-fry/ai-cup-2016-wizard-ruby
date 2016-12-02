module AiBot
  module Utils
    def normalize_angle(angle)
      return 0 if angle == 0

      sign = angle / angle.abs

      while angle.abs > Math::PI
        angle += -sign * 2 * Math::PI
      end

      angle
    end

    module_function :normalize_angle

    def safe_distance_from(wizard:, unit:, game:)
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

      attack_distance + wizard.radius + unit.radius
    end

    module_function :safe_distance_from
  end
end
