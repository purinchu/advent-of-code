#!/usr/bin/env ruby

# 2015 Day 2 Part 2 / Puzzle 2015/04

sum = 0

File.foreach(ARGV.shift || 'input') { |line|
  # each line in format WxHxL
  dimensions = line.split('x').map(&:to_i)
  ribbon = dimensions.sort.take(2)
  rlength = dimensions.reduce { |a, b| a * b } + 2 * ribbon.sum
  sum += rlength
}

puts sum
