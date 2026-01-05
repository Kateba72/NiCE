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
    Engine.instance.stop_calculating = false

    params = {
      wtime: nil,
      btime: nil,
      winc: 0,
      binc: 0,
      movestogo: nil,
    }

    i = 1
    while i < tokens.length
      case tokens[i]
      when "wtime"
        params[:wtime] = tokens[i + 1].to_i
        i += 2
      when "btime"
        params[:btime] = tokens[i + 1].to_i
        i += 2
      when "winc"
        params[:winc] = tokens[i + 1].to_i
        i += 2
      when "binc"
        params[:binc] = tokens[i + 1].to_i
        i += 2
      when "movestogo"
        params[:movestogo] = tokens[i + 1].to_i
        i += 2
      when "depth"
        i += 2
      when "nodes"
        i += 2
      when "mate"
        i += 2
      when "movetime"
        i += 2
      when "ponder"
        i += 1
      when "infinite"
        i += 1
      else
        # Unknown or malformed token — skip
        i += 1
      end
    end

    best_move = calculate_best_move(params)

    puts "bestmove #{Board.from_position(best_move[0])}#{Board.from_position(best_move[1])}#{best_move[2]}"
  end

  def handle_stop
    Engine.instance.stop_calculating = true
  end

  def reset_engine
    Engine.instance.stop_calculating = false

    Engine.instance.reset
  end

  def calculate_best_move(params)
    params[:movestogo] ||= 40
    expected_time = if @board_position.white_turn
      params[:wtime] / params[:movestogo] + (params[:winc] || 0)
    else
      params[:btime] / params[:movestogo] + (params[:binc] || 0)
    end * 0.001 * 0.95
    puts "info expected time #{expected_time}"

    start = Time.now
    Engine.instance.stop_time = Time.now + expected_time
    best_move = @board_position.best_move

    until Engine.instance.stop_calculating?
      expected_time *= 0.75
      Engine.instance.stop_time = Time.now + expected_time
      best_move = @board_position.increase_depth
    end

    best_move
  end
end
