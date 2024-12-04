#!/usr/bin/env ruby

# 2015 Day 18 Part 2 / Puzzle 2015/36

class Puzzle
  def initialize()
    # height is the same as the width
    @cur_row = 0 # incremented as each row is read in

    @grid = [ ]
  end

  def num_neighbors(x, y)
    sum = 0

    (-1..1).each { |dy|
      (-1..1).each { |dx|
        next unless dx != 0 or dy != 0
        nx = x + dx
        ny = y + dy
        next if nx < 0 or ny < 0
        next if nx >= @width or ny >= @width

        sum += 1 if @grid[ny][nx] == '#'
      }
    }

    return sum
  end

  def decode(line)
    if @cur_row == 0
      @width = line.length
      @grid = Array.new(@width) {
        Array.new(@width)
      }
    end

    line.each_char.each_with_index { |ch, idx|
      @grid[@cur_row][idx] = ch
    }

    @cur_row += 1
  end

  def show_grid
    @grid.each { |row|
      puts "#{row.join}"
    }
  end

  def run_animate
    new_grid = Array.new(@width) {
      Array.new(@width)
    }

    # simulate stuck-on corner lights
    @grid[@width - 1][0] = @grid[0][0] = @grid[0][@width - 1] = @grid[@width - 1][@width - 1] = '#'

    new_grid.each_index { |y|
      new_grid[y].each_index { |x|
        n_count = num_neighbors(x, y)
        is_on = @grid[y][x] === '#'
        if n_count == 3 or (is_on and n_count == 2)
          new_grid[y][x] = '#'
        else
          new_grid[y][x] = '.'
        end
      }
    }

    @grid = new_grid

    @grid[@width - 1][0] = @grid[0][0] = @grid[0][@width - 1] = @grid[@width - 1][@width - 1] = '#'
  end

  def count_lights
    @grid.flatten.count('#')
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../35/input') { |line|
  p.decode(line.chomp)
}

#p.show_grid

(1..100).each { |idx|
  p.run_animate

  puts ""
  puts "After step #{idx}"
#  p.show_grid
}

puts ""
p.show_grid

puts "\n#{p.count_lights} lights"
