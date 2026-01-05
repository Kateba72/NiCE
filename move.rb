class Move
  def initialize(from_board: nil, move_start: nil, move_target: nil, target_board: nil, white_turn: true, castles: 0, en_passant: nil, reversible_moves: 0, move_number: nil)
    @from_board = from_board
    @move_start = move_start
    @move_target = move_target
    @target_board = target_board
    @white_turn = white_turn
    @castles = castles
    @en_passant = en_passant
    @reversible_moves = reversible_moves
    @move_number = move_number
  end

  def inspect
    str = +'<Move:'
    if @move_start
      str << " #{Board.from_position(@move_start)}->#{Board.from_position(@move_target)}"
    else
      str << " (precalculated)"
    end

    str << " by #{@white_turn ? 'black' : 'white'}"
    str << " e.p. #{Board.from_position(@en_passant)}" if @en_passant
    str << " C#{@castles}" if @castles > 0

    str << '>'
    str
  end

  def target
    @target ||= begin
      if @target_board.is_a? Board::EndState
        @target_board
      elsif @reversible_moves >= 100
        Board::EndState::REMIS
      else
        Engine.instance.find_board(
          Board.new(
            board: target_board,
            white_turn: @white_turn,
            castles: @castles,
            en_passant: @en_passant,
            reversible_moves: @reversible_moves,
          ),
          move_number: @move_number,
        )
      end
    end
  end

  def target_board
    return @target_board if @target_board

    @target_board = @from_board.dup
    @target_board[@move_start] = 0
    @target_board[@move_target] = @from_board[@move_start]
    @target_board
  end
end
