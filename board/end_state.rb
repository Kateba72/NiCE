class Board
  class EndState
    def initialize(score)
      @score = score
    end

    def score(*)
      999_999_999 * @score
    end
    alias_method :remembered_score, :score
  end

  class EndState
    WHITE_WIN = EndState.new(1)
    REMIS = EndState.new(0)
    BLACK_WIN = EndState.new(-1)
  end
end
