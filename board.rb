class Board
  attr_reader :board, :white_turn, :castles, :en_passant, :reversible_moves
  attr_accessor :move_number # for showing when to clean

  MIN_DEPTH = 3

  def initialize(board:, white_turn:, castles:, en_passant:, reversible_moves:)
    @board = board
    @white_turn = white_turn
    @castles = castles
    @en_passant = en_passant
    @reversible_moves = reversible_moves
    @attributes = [board, white_turn, castles, en_passant, reversible_moves]
    @remembered_score = nil
    @best_move = nil
    @depth = -1
  end

  def unload
    @attributes = nil
    @moves = nil
  end

  def ==(other)
    other.is_a?(Board) && board == other.board && white_turn == other.white_turn && castles == other.castles && en_passant == other.en_passant && reversible_moves == other.reversible_moves
  end
  alias :eql? :==

  def hash
    @attributes.hash
  end

  def best_move
    score(MIN_DEPTH)
    @best_move
  end

  def increase_depth
    puts "info depth #{@depth + 1}"
    score(@depth + 1)
    @best_move
  end

  def moves
    return @moves if @moves
    @moves = {}
    board.each_with_index do |piece, index|
      next if piece == 0
      next unless (piece > 0) == white_turn

      case piece
      when Pieces::PAWN # white
        rank = index / 8
        file = index % 8

        convert = rank == 6
        add_pawn_move(@moves, index, index + 7, convert:) if file > 0 && board[index + 7] < 0
        add_pawn_move(@moves, index, index + 9, convert:) if file < 7 && board[index + 9] < 0
        if board[index + 8] == 0
          add_pawn_move(@moves, index, index + 8, convert:)
          if rank == 1 && board[index + 16] == 0
            add_pawn_move(@moves, index, index + 16, allow_en_passant: index + 8)
          end
        end
        if en_passant && rank == 5 && [index + 7, index + 9].include?(en_passant)
          add_move(@moves, index, en_passant, reversible: false) do |next_board|
            next_board[en_passant - 8] = 0
          end
        end
      when -Pieces::PAWN # black
        rank = index / 8
        file = index % 8

        convert = rank == 1
        add_pawn_move(@moves, index, index - 7, convert:) if file < 7 && board[index - 7] > 0
        add_pawn_move(@moves, index, index - 9, convert:) if file > 0 && board[index - 9] > 0
        if board[index - 8] == 0
          add_pawn_move(@moves, index, index - 8, convert:)
          if rank == 6 && board[index - 16] == 0
            add_pawn_move(@moves, index, index - 16, allow_en_passant: index - 8)
          end
        end
        if en_passant && rank == 4 && [index - 7, index - 9].include?(en_passant)
          add_move(@moves, index, en_passant, reversible: false) do |next_board|
            next_board[en_passant + 8] = 0
          end
        end
      when Pieces::KNIGHT, -Pieces::KNIGHT
        PieceMoves.instance.knight[index].each do |move|
          add_piece_move(@moves, index, move)
        end
      when Pieces::BISHOP, -Pieces::BISHOP
        PieceMoves.instance.bishop[index].each do |direction|
          direction.each do |move|
            break unless add_piece_move(@moves, index, move)
          end
        end
      when Pieces::ROOK, -Pieces::ROOK
        PieceMoves.instance.rook[index].each do |direction|
          direction.each do |move|
            break unless add_piece_move(@moves, index, move)
          end
        end
      when Pieces::QUEEN, -Pieces::QUEEN
        PieceMoves.instance.bishop[index].each do |direction|
          direction.each do |move|
            break unless add_piece_move(@moves, index, move)
          end
        end
        PieceMoves.instance.rook[index].each do |direction|
          direction.each do |move|
            break unless add_piece_move(@moves, index, move)
          end
        end
      when Pieces::KING, -Pieces::KING
        PieceMoves.instance.king[index].each do |move|
          add_piece_move(@moves, index, move)
        end
      end
    end

    home_rank = white_turn ? 0 : 56
    if board[home_rank + 4].abs == Pieces::KING
      if (castles & (white_turn ? Castles::WHITE_QUEENSIDE : Castles::BLACK_QUEENSIDE)) > 0 && board[home_rank].abs == Pieces::ROOK && board[home_rank + 1] == 0 && board[home_rank + 2] == 0 && board[home_rank + 3] == 0
        board[home_rank] = 0
        board[home_rank + 4] = 0
        test_board = Board.new(board:, white_turn: !white_turn, castles: 0, en_passant: nil, reversible_moves: 0)
        test_board.move_number = 0
        under_attack = test_board.moves.keys.map { _1[1] }.to_set
        board[home_rank] = white_turn ? Pieces::ROOK : -Pieces::ROOK
        board[home_rank + 4] = white_turn ? Pieces::KING : -Pieces::KING
        if under_attack.intersection(home_rank..(home_rank + 4)).blank?
          add_move(@moves, home_rank + 4, home_rank + 2) do |next_board|
            next_board[home_rank + 3] = next_board[home_rank]
            next_board[home_rank] = 0
          end
        end
      end
      if (castles & (white_turn ? Castles::WHITE_KINGSIDE : Castles::BLACK_KINGSIDE)) > 0 && board[home_rank + 7].abs == Pieces::ROOK && board[home_rank + 6] == 0 && board[home_rank + 5] == 0
        board[home_rank + 7] = 0
        board[home_rank + 4] = 0
        test_board = Board.new(board:, white_turn: !white_turn, castles: 0, en_passant: nil, reversible_moves: 0)
        test_board.move_number = 0
        under_attack = test_board.moves.keys.map { _1[1] }.to_set
        board[home_rank + 7] = white_turn ? Pieces::ROOK : -Pieces::ROOK
        board[home_rank + 4] = white_turn ? Pieces::KING : -Pieces::KING
        if under_attack.intersection((home_rank + 4)..(home_rank + 7)).blank?
          add_move(@moves, home_rank + 4, home_rank + 6) do |next_board|
            next_board[home_rank + 5] = next_board[home_rank + 7]
            next_board[home_rank + 7] = 0
          end
        end
      end
    end

    @moves
  end

  def to_s
    board_string = board.each_slice(8).map do |rank|
      rank.map { AS_STRING[_1] }.join
    end.reverse.join("\n")
    "#{board_string}\n #{white_turn ? 'W' : 'B'} #{castles} #{en_passant || '-'}"
  end

  def self.start_position
    self.from_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
  end

  def self.from_fen(fen)
    FromFen.run(fen)
  end

  def self.to_position(pos_string)
    file = pos_string[0].downcase
    rank = pos_string[1].to_i

    (file.ord - 97) + 8 * (rank - 1)
  end

  def self.from_position(pos_index)
    file = 'abcdefghi'[pos_index % 8]
    rank = pos_index / 8 + 1
    "#{file}#{rank}"
  end

  def self.parse_move(move)
    [
      to_position(move[0..1]),
      to_position(move[2..3]),
      move[4]&.upcase,
    ]
  end

  module Pieces
    PAWN = 1
    KNIGHT = 2
    BISHOP = 3
    ROOK = 4
    QUEEN = 5
    KING = 6

    CONVERTABLE = [KNIGHT, BISHOP, ROOK, QUEEN].freeze
  end

  module Castles
    WHITE_KINGSIDE = 1
    WHITE_QUEENSIDE = 2
    BLACK_KINGSIDE = 4
    BLACK_QUEENSIDE = 8

    MASK = {
      0 => WHITE_QUEENSIDE,
      4 => WHITE_QUEENSIDE | WHITE_KINGSIDE,
      7 => WHITE_KINGSIDE,
      66 => WHITE_QUEENSIDE,
      60 => BLACK_QUEENSIDE | BLACK_KINGSIDE,
      63 => BLACK_KINGSIDE,
    }.freeze
  end

  AS_STRING = {
    1 => 'P', 2 => 'N', 3 => 'B', 4 => 'R', 5 => 'Q', 6 => 'K',
    -1 => 'p', -2 => 'n', -3 => 'b', -4 => 'r', -5 => 'q', -6 => 'k',
    0 => ' ',
  }.freeze

  include DoesScore

  private

  def add_pawn_move(moves, start, target, convert: false, allow_en_passant: nil)
    if convert
      Pieces::CONVERTABLE.each do |piece|
        add_move(moves, start, target, reversible: false, convert: AS_STRING[piece]) do |next_board|
          next_board[target] = white_turn ? piece : -piece
        end
      end
    else
      add_move(moves, start, target, allow_en_passant:, reversible: false)
    end
  end

  def add_piece_move(moves, start, target)
    if board[target] == 0
      add_move(moves, start, target, reversible: true)
      true
    elsif board[target] > 0 == white_turn # same color
      false
    else # different color
      add_move(moves, start, target, reversible: false)
      false
    end
  end

  def add_move(moves, start, target, allow_en_passant: nil, reversible: false, convert: nil)
    moves[[start, target, convert]] = if board[target] == Pieces::KING
      Move.new(target_board: EndState::BLACK_WIN)
    elsif board[target] == -Pieces::KING
      Move.new(target_board: EndState::WHITE_WIN)
    elsif block_given?
      next_board = board.dup
      next_board[start] = 0
      next_board[target] = board[start]
      yield next_board

      Move.new(
        target_board: next_board,
        white_turn: !white_turn,
        castles: next_castles(start),
        en_passant: allow_en_passant,
        reversible_moves: reversible ? reversible_moves + 1 : 0,
        move_number: move_number + 1
      )
    else
      Move.new(
        from_board: board,
        move_start: start,
        move_target: target,
        white_turn: !white_turn,
        castles: next_castles(start),
        en_passant: allow_en_passant,
        reversible_moves: reversible ? reversible_moves + 1 : 0,
        move_number: move_number + 1
      )
    end
  end

  def next_castles(start)
    castles ^ (castles & Castles::MASK.fetch(start, 0))
  end
end
