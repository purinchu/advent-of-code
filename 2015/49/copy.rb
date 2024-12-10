#!/usr/bin/env ruby

# 2015 Day 25 Part 1 / Puzzle 2015/49

class Puzzle
  def initialize()
    @row = 0
    @col = 0
  end

  def decode(line)
    row, col = /at row ([0-9]+), column ([0-9]+)/.match(line)[1,2];
    @row = row.to_i
    @col = col.to_i
  end

  def grid_entry
    [@row, @col]
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../49/input') { |line|
  p.decode(line.chomp)
}

r, c = p.grid_entry

puts "Row: #{r}, Col: #{c} (sum #{c + r})"

c2 = c + (r - 1)

puts "Row: 1, Col: #{c2} (sum #{c2 + 1})"

t = c2 * (c2 + 1) / 2

puts "Tri num: #{t}"

t2 = t - (r - 1)

puts "I think we want tri num: #{t2} (moving back down and to the left on the diagonal)?"

n = 20151125
mult = 252533
modu = 33554393

(1...t2).each {
  n = (n * mult) % modu;
}

puts "Entry #{t2} = #{n}"
