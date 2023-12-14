#!/usr/bin/env ruby

# 2015 Day 3 Part 1 / Puzzle 2015/05

File.foreach(ARGV.shift || 'input') { |line|
  x = 0
  y = 0
  map = { }
  map[0] = 1 # initial visit

  line.each_char { |char|
    case char
    when "<" then x += 1
    when ">" then x -= 1
    when "^" then y -= 1
    when "v" then y += 1
    end

    map[y * 65536 + x] = 1
  }

  puts map.length
}
