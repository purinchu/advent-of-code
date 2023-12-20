#!/usr/bin/env ruby

# 2015 Day 6 Part 2 / Puzzle 2015/12

def decode(line)
  match = line.match /^([a-z ]+) ([0-9]+),([0-9]+) through ([0-9]+),([0-9]+)/

  m = Array.new(match.captures[0..4])
  m[1..4] = m[1..4].map(&:to_i)
  m
end

grid = Array.new(1000) { Array.new(1000, 0) }

File.foreach(ARGV.shift || 'input') { |line|
  line.chomp!
  act, x1, y1, x2, y2 = decode(line)

  if x1 > x2
    x2, x1 = x1, x2
  end

  if y1 > y2
    y2, y1 = y1, y2
  end

  y1.upto(y2) { |y|
    x1.upto(x2) { |x|
      case act
      when "turn on"
        grid[y][x] += 1
      when "turn off"
        grid[y][x] = [grid[y][x] - 1, 0].max
      when "toggle"
        grid[y][x] += 2
      else
        raise "unimplemented"
      end
    }
  }
}

puts grid.flatten.sum
