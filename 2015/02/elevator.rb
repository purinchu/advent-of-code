#!/usr/bin/env ruby

# 2015 Day 1 Part 2 / Puzzle 2015/02

File.foreach(ARGV.shift || 'input') { |line|
  i = 0
  pos = 0
  line.each_char { |c|
    pos += 1
    i += (c == ')' ? -1 : 1)
    break if i < 0
  }

  puts pos
}
