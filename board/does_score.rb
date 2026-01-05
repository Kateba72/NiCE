class Board
  module DoesScore
    BASE_VALUES = {
      Pieces::PAWN => 100,
      Pieces::BISHOP => 330,
      Pieces::KNIGHT => 320,
      Pieces::ROOK => 500,
      Pieces::QUEEN => 900,
      Pieces::KING => 0,
      - Pieces::PAWN => 100,
      - Pieces::BISHOP => 330,
      - Pieces::KNIGHT => 320,
      - Pieces::ROOK => 500,
      - Pieces::QUEEN => 900,
      - Pieces::KING => 0,
      0 => 0,
    }

    PAWN_SCORES = [
       0,  0,  0,  0,  0,  0,  0,  0,
       5, 10, 10,-20,-20, 10, 10,  5,
       5, -5,-10,  0,  0,-10, -5,  5,
       0,  0,  0, 25, 25,  0,  0,  0,
       5,  5, 10, 25, 25, 10,  5,  5,
      10, 10, 20, 30, 30, 20, 10, 10,
      50, 50, 50, 50, 50, 50, 50, 50,
       0,  0,  0,  0,  0,  0,  0,  0
    ].freeze

    KNIGHT_SCORES = [
      -25,-20,-15,-15,-15,-15,-20,-25,
      -20,-10,  0,  5,  5,  0,-10,-20,
      -15,  5, 10, 15, 15, 10,  5,-15,
      -15,  0, 15, 20, 20, 15,  0,-15,
      -15,  5, 15, 20, 20, 15,  5,-15,
      -15,  0, 10, 15, 15, 10,  0,-15,
      -20,-10,  0,  0,  0,  0,-10,-20,
      -25,-20,-15,-15,-15,-15,-20,-25,
    ].freeze

    BISHOP_SCORES = [
      -20,-10,-10,-10,-10,-10,-10,-20,
      -10,  5,  0,  0,  0,  0,  5,-10,
      -10, 10, 10, 10, 10, 10, 10,-10,
      -10,  0, 10, 10, 10, 10,  0,-10,
      -10,  5,  5, 10, 10,  5,  5,-10,
      -10,  0,  5, 10, 10,  5,  0,-10,
      -10,  0,  0,  0,  0,  0,  0,-10,
      -20,-10,-10,-10,-10,-10,-10,-20,
    ].freeze

    ROOK_SCORES = [
      0,  0,  0,  5,  5,  0,  0,  0,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
      5, 10, 10, 10, 10, 10, 10,  5,
      0,  0,  0,  0,  0,  0,  0,  0,
    ].freeze

    QUEEN_SCORES = [
      -20,-10,-10, -5, -5,-10,-10,-20,
      -10,  0,  5,  0,  0,  0,  0,-10,
      -10,  5,  5,  5,  5,  5,  0,-10,
       -5,  0,  5,  5,  5,  5,  0, -5,
       -5,  0,  5,  5,  5,  5,  0, -5,
      -10,  0,  5,  5,  5,  5,  0,-10,
      -10,  0,  0,  0,  0,  0,  0,-10,
      -20,-10,-10, -5, -5,-10,-10,-20,
    ].freeze

    KING_MIDDLE_GAME = [
       20, 30, 10,  0,  0, 10, 30, 20,
       20, 20,  0,  0,  0,  0, 20, 20,
      -10,-20,-20,-20,-20,-20,-20,-10,
      -20,-30,-30,-40,-40,-30,-30,-20,
      -30,-40,-40,-50,-50,-40,-40,-30,
      -30,-40,-40,-50,-50,-40,-40,-30,
      -30,-40,-40,-50,-50,-40,-40,-30,
      -30,-40,-40,-50,-50,-40,-40,-30,
    ].freeze

    KING_END_GAME = [
      -50,-30,-30,-30,-30,-30,-30,-50,
      -30,-30,  0,  0,  0,  0,-30,-30,
      -30,-10, 20, 30, 30, 20,-10,-30,
      -30,-10, 30, 40, 40, 30,-10,-30,
      -30,-10, 30, 40, 40, 30,-10,-30,
      -30,-10, 20, 30, 30, 20,-10,-30,
      -30,-20,-10,  0,  0,-10,-20,-30,
      -50,-40,-30,-20,-20,-30,-40,-50,
    ].freeze

    SCORES_MIDGAME = {
      Pieces::PAWN => PAWN_SCORES,
      Pieces::KNIGHT => KNIGHT_SCORES,
      Pieces::BISHOP => BISHOP_SCORES,
      Pieces::ROOK => ROOK_SCORES,
      Pieces::QUEEN => QUEEN_SCORES,
      Pieces::KING => KING_MIDDLE_GAME,
    }.freeze

    SCORES_ENDGAME = {
      Pieces::PAWN => PAWN_SCORES,
      Pieces::KNIGHT => KNIGHT_SCORES,
      Pieces::BISHOP => BISHOP_SCORES,
      Pieces::ROOK => ROOK_SCORES,
      Pieces::QUEEN => QUEEN_SCORES,
      Pieces::KING => KING_END_GAME,
    }.freeze

    def score(depth, alpha: -Float::INFINITY, beta: Float::INFINITY)
      @remembered_score = if depth <= 0
        score_estimate
      elsif white_turn
        value = -Float::INFINITY
        moves.sort_by { |key, move| -move.target.remembered_score }.each do |key, move|
          result = move.target.score(depth - 1, alpha:, beta:)
          result += 1 if result < -9_999_999
          if result > value
            @best_move = key
            value = result
            return (@remembered_score = value) if value >= beta
            alpha = value if value > alpha
          end
        end
        value
      else
        value = Float::INFINITY
        moves.sort_by { |key, move| move.target.remembered_score }.each do |key, move|
          result = move.target.score(depth - 1, alpha:, beta:)
          result += 1 if result < -9_999_999
          if result < value
            @best_move = key
            value = result
            return (@remembered_score = value) if value <= alpha
            beta = value if value > beta
          end
        end
        value
      end

      if depth == 1
        @remembered_score += score_estimate + (white_turn ? moves.size : -moves.size)
      elsif depth == 2
        @remembered_score += (white_turn ? moves.size : -moves.size)
      end
      @remembered_score
    end

    def remembered_score
      @remembered_score ||= score_estimate
    end

    def score_estimate
      @score_estimate ||= begin
        board_sum = board.sum { BASE_VALUES[it] }
        scores = board_sum >= 2000 ? SCORES_MIDGAME : SCORES_ENDGAME
        board.each_with_index.sum do |piece, field|
          if piece == 0
            0
          elsif piece > 0
            value = BASE_VALUES[piece] + scores[piece][field]
            if piece == Pieces::PAWN
              file = field % 8
              value -= 18 if board[field - 8] == Pieces::PAWN
              value += 10 if file < 7 && board[field - 7] == Pieces::PAWN
              value += 10 if file > 0 && board[field - 9] == Pieces::PAWN
            end
            value
          else
            value = BASE_VALUES[-piece] + scores[-piece][-field]
            if piece == -Pieces::PAWN
              file = field % 8
              value -= 18 if board[field + 8] == Pieces::PAWN
              value += 10 if file < 7 && board[field + 9] == Pieces::PAWN
              value += 10 if file > 0 && board[field + 7] == Pieces::PAWN
            end
            - value
          end
        end
      end
    end
  end
end
