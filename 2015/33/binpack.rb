#!/usr/bin/env ruby

# 2015 Day 17 Part 1 / Puzzle 2015/33

class Puzzle
  def initialize()
    @bins = [ ]
  end

  def decode(line)
    @bins.push(line.to_i)
  end

  def bins
    @bins
  end

  def check_combos(total)
    list = @bins.sort.reverse

    sum = 0

    (1..list.size).each { |n|
      list.combination(n) { |opt|
        if opt.sum == total
          sum = sum + 1
        end
      }
    }

    return sum
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../33/input') { |line|
  p.decode(line.chomp)
}

total = (ARGV.shift || '150').to_i
puts p.check_combos(total)
