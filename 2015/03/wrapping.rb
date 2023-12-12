#!/usr/bin/env ruby

# 2015 Day 2 Part 1 / Puzzle 2015/03

sum = 0

File.foreach(ARGV.shift || 'input') { |line|
  # each line in format WxHxL
  w, h, l = line.split('x').map(&:to_i)
  area = [2 * w * h, 2 * w * l, 2 * l * h]
  area << (area.min / 2) # slack wrapping
  sum = sum + area.sum
}

puts sum
