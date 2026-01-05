class Board
  module FromFen
    FEN_PIECES = {
      'P' => Pieces::PAWN,
      'N' => Pieces::KNIGHT,
      'B' => Pieces::BISHOP,
      'R' => Pieces::ROOK,
      'Q' => Pieces::QUEEN,
      'K' => Pieces::KING,
      'p' => - Pieces::PAWN,
      'n' => - Pieces::KNIGHT,
      'b' => - Pieces::BISHOP,
      'r' => - Pieces::ROOK,
      'q' => - Pieces::QUEEN,
      'k' => - Pieces::KING,
    }

    def run(fen_string)
      position_string, turn_string, castle_string, ep_string, reversible_string, _moves = fen_string.split

      board = Array.new(64) { 0 }
      position_string.split('/').each_with_index do |rank, index|
        file = 0
        rank_i  = (7 - index) * 8

        rank.each_char do |char|
          case char
          when /[0-9]/
            skip = char.to_i
            file += skip
          when /[PNBRQKpnbrqk]/
            arr_index = rank_i + file
            board[arr_index] = FEN_PIECES[char]
            file += 1
          end
        end
      end

      castles = 0
      castles |= Castles::WHITE_KINGSIDE if 'K'.in? castle_string
      castles |= Castles::WHITE_QUEENSIDE if 'Q'.in? castle_string
      castles |= Castles::BLACK_KINGSIDE if 'k'.in? castle_string
      castles |= Castles::BLACK_QUEENSIDE if 'q'.in? castle_string

      en_passant = Board.to_postion(ep_string) unless ep_string == '-'

      board = Board.new(
        board: board,
        white_turn: turn_string.downcase == 'w',
        castles:,
        en_passant:,
        reversible_moves: reversible_string.to_i,
      )
      Engine.instance.find_board(board)
    end
    module_function :run
  end
end
