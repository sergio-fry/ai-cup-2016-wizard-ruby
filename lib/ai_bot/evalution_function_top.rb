module AiBot
  class EvalutionFunctionTop < EvalutionFunction
    WAYPOINT_SCORE = 0.00001

    def calc
      super + WAYPOINT_SCORE * waypoint_score
    end

    private

    def waypoint_score
      -Point.new(200, 200).distance_to(wizard)
    end
  end
end
