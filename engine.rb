class Engine
  include Singleton

  attr_accessor :move, :stop_time
  attr_writer :stop_calculating

  def initialize
    @move = 0
    reset
  end

  def reset
    @boards.values.each(&:unload) if @boards.present?
    @boards = {}
  end

  def stop_calculating?
    !!@stop_calculating || Time.now > stop_time
  end

  def clean
    return unless @boards.size > 1_000_000
    puts 'info cleaning'
    @boards = @boards.filter_map do |key, board|
      if @move - 1 <= board.move_number
        board.unload
        nil
      else
        [key, board]
      end
    end.to_h
    GC.start
  end

  def find_board(board, move_number: nil)
    move_number ||= @move
    if @boards.key?(board)
      @boards[board].move_number = move_number
      @boards[board]
    else
      board.move_number = move_number
      @boards[board] = board
    end
  end
end
