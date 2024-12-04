#!/usr/bin/env ruby

# 2015 Day 17 Part 2 / Puzzle 2015/34

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

    list_of_largest = []
    size_of_list = list.size

    (1..list.size).each { |n|
      list.combination(n) { |opt|
        next if opt.size > size_of_list
        next unless opt.sum == total
        if opt.size < size_of_list
          list_of_largest = [opt]
          size_of_list = opt.size
        else
          list_of_largest.push(opt)
        end
      }
    }

    return list_of_largest
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../33/input') { |line|
  p.decode(line.chomp)
}

total = (ARGV.shift || '150').to_i
combos = p.check_combos(total)
puts ("#{combos.size}")
