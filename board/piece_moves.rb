class Board
  class PieceMoves
    attr_reader :knight, :bishop, :rook, :king

    include Singleton

    def calculate!
      return if defined?(@knight)
      calculate_knight
      calculate_bishop
      calculate_rook
      calculate_king
      nil
    end

    private

    def calculate_knight
      @knight = {}
      (0..7).each do |rank|
        (0..7).each do |file|
          @knight[pos(rank, file)] = [[2,1], [1,2], [-1,2], [-2,1], [-2,-1], [-1,-2], [1,-2], [2,-1]].filter_map do |move|
            next_rank = rank + move[0]
            next_file = file + move[1]

            next unless allowed_square?(next_rank, next_file)

            pos(next_rank, next_file)
          end
        end
      end
    end

    def calculate_bishop
      @bishop = {}
      (0..7).each do |rank|
        (0..7).each do |file|
          @bishop[pos(rank, file)] = [[1,1],[1,-1],[-1,-1],[-1,1]].map do |direction|
            moves = []

            next_rank = rank + direction[0]
            next_file = file + direction[1]
            while allowed_square?(next_rank, next_file)
              moves << pos(next_rank, next_file)
              next_rank = next_rank + direction[0]
              next_file = next_file + direction[1]
            end
            moves
          end
        end
      end
    end

    def calculate_rook
      @rook = {}
      (0..7).each do |rank|
        (0..7).each do |file|
          @rook[pos(rank, file)] = [[1,0],[0,-1],[-1,0],[0,1]].map do |direction|
            moves = []

            next_rank = rank + direction[0]
            next_file = file + direction[1]
            while allowed_square?(next_rank, next_file)
              moves << pos(next_rank, next_file)
              next_rank = next_rank + direction[0]
              next_file = next_file + direction[1]
            end
            moves
          end
        end
      end
    end

    def calculate_king
      @king = {}
      (0..7).each do |rank|
        (0..7).each do |file|
          @king[pos(rank, file)] = [[1,1], [0,1], [-1,1], [-1,0], [-1,-1], [0,-1], [1,-1], [1, 0]].filter_map do |move|
            next_rank = rank + move[0]
            next_file = file + move[1]

            next unless allowed_square?(next_rank, next_file)

            pos(next_rank, next_file)
          end
        end
      end
    end

    def allowed_square?(rank, file)
      (rank >= 0) && (file >= 0) && (rank <= 7) && (file <= 7)
    end

    def pos(rank, file)
      rank * 8 + file
    end
  end
end
