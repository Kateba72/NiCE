class UciEngine
  def initialize
    @stop_requested = false
    @board_position = nil
  end

  def run
    STDOUT.sync = true

    while (line = STDIN.gets)
      line.strip!
      next if line.empty?

      handle_command(line)
    end
  end

  private

  def handle_command(line)
    tokens = line.split
    command = tokens.first

    case command
    when "uci"
      handle_uci
    when "isready"
      handle_isready
    # when "setoption"
    #   handle_setoption(tokens)
    when "ucinewgame"
      handle_ucinewgame
    when "position"
      handle_position(tokens)
    when "go"
      handle_go(tokens)
    when "stop"
      handle_stop
    # when 'debugger'
    #   binding.break
    when "quit"
      exit(0)
    else
      # Unknown command – ignore per UCI spec
    end
  rescue StandardError => e
    puts "info #{e}"
    puts "info #{e.backtrace.join("\ninfo ")}"
  end

  def handle_uci
    puts "id name NiCE"
    puts "id author Niklas Hasselmeyer"

    puts "uciok"
  end

  def handle_isready
    puts "readyok"
  end

  # def handle_setoption(tokens)
  #   # Format:
  #   # setoption name <id> [value <x>]
  #   name_index = tokens.index("name")
  #   value_index = tokens.index("value")

  #   return unless name_index

  #   name =
  #     if value_index
  #       tokens[(name_index + 1)...value_index].join(" ")
  #     else
  #       tokens[(name_index + 1)..].join(" ")
  #     end

  #   value =
  #     value_index ? tokens[(value_index + 1)..].join(" ") : true

  #   @options[name] = value
  # end

  def handle_ucinewgame
    reset_engine
  end

  def handle_position(tokens)
    index = 1

    position = if tokens[index] == "startpos"
      index += 1
      Board.start_position
    elsif tokens[index] == "fen"
      index += 1
      fen_parts = []
      6.times do
        fen_parts << tokens[index]
        index += 1
      end
      Board.from_fen(fen_parts.join ' ')
    else
      puts 'info board position must start with "startpos" or "fen"'
    end

    if tokens[index] == "moves"
      tokens[(index + 1)..].each do |move|
        move = position.moves[Board.parse_move(move)]
        position = move.target
      end
    end

    Engine.instance.move = tokens.size - index
    Engine.instance.clean

    @board_position = position
  end

  def handle_go(tokens)
    @stop_requested = false

    best_move = calculate_best_move

    puts "bestmove #{Board.from_position(best_move[0])}#{Board.from_position(best_move[1])}#{best_move[2]}"
  end

  def handle_stop
    @stop_requested = true
  end

  def reset_engine
    @stop_requested = false

    Engine.instance.reset
  end

  def calculate_best_move
    @board_position.best_move
  end
end
