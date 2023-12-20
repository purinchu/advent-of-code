#!/usr/bin/env ruby

# 2015 Day 5 Part 2 / Puzzle 2015/10

pair = ->(line) { line =~ /([a-z][a-z]).*\1/ }
dual = ->(line) { line =~ /(.)(.)\1/ }
santa = ->(line) { pair.(line) && dual.(line) }

File.foreach(ARGV.shift || 'input') { |line|
  line.chomp!
  if santa.(line)
    puts line
  end
}
