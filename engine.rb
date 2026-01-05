class Engine
  include Singleton

  attr_accessor :move

  def initialize
    @move = 0
    reset
  end

  def reset
    @boards.values.each(&:unload) if @boards.present?
    @boards = {}
  end

  def clean
    return unless @boards.size > 1_000_000
    puts 'info cleaning'
    @boards = @boards.filter_map do |key, board|
      if @move - 1 - Board::DEPTH <= board.move_number && move + 1 >= board.move_number
        board.unload
        nil
      else
        [key, board]
      end
    end.to_h
    GC.start
  end

  def find_board(board)
    if @boards.key?(board)
      @boards[board].move_number = @move
      @boards[board]
    else
      board.move_number = @move
      @boards[board] = board
    end
  end
end
