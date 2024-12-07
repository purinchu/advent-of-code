#!/usr/bin/env ruby

# 2024 Day 7 Part 1 / Puzzle 2024/13

class Puzzle
  def initialize()
    # each entry is an array of [total, [ inputs ]]
    @calibrations = [ ]
  end

  def decode(line)
    total, numstr = line.split(/: /, 2)
    nums = numstr.split(' ').map(&:to_i)
    @calibrations.push([total.to_i, nums])
  end

  def calibrations
    @calibrations
  end
end

def check_total(val, tot, remainders)
  if val > tot
    return false
  end
  if remainders.empty?
    return val == tot
  end

  entry, rest = remainders[0], remainders[1..]
  res = (check_total(entry + val, tot, rest) or
         check_total(entry * val, tot, rest) or
         check_total((val.to_s + entry.to_s).to_i, tot, rest)
        )
  return res
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../13/input') { |line|
  p.decode(line.chomp)
}

sum = p.calibrations.filter_map { |entry|
  total, nums = entry

  total if check_total(0, total, nums)
}.sum

puts "#{sum}"
