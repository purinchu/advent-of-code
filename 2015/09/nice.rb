#!/usr/bin/env ruby

# 2015 Day 5 Part 2 / Puzzle 2015/10

vowels = ->(line) { line =~ /[aeiou].*[aeiou].*[aeiou]/ }
pair = ->(line) { line =~ /(.)\1/ }
naughty = ->(line) { line =~ /(ab|cd|pq|xy)/ }
santa = ->(line) { vowels.(line) && pair.(line) && !naughty.(line) }

File.foreach(ARGV.shift || 'input') { |line|
  line.chomp!
  if santa.(line)
    puts line
  end
}
