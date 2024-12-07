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

  def is_ok?(total, nums)
    return ['+', '*'].repeated_permutation(nums.length - 1).any? { |perm|
      l = nums[0]
      perm.each_with_index { |op, i|
        r = nums[i+1]
        l = l + r if op == '+'
        l = l * r if op == '*'
      }

      l == total
    }
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../13/input') { |line|
  p.decode(line.chomp)
}

matches = p.calibrations.filter_map { |entry|
  total, nums = entry
  total if p.is_ok?(total, nums)
}

puts "#{matches.sum}"
