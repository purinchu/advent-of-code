#!/usr/bin/env ruby

# 2015 Day 4 Part 2 / Puzzle 2015/08

require 'digest'

File.foreach(ARGV.shift || 'input') { |line|
  line.chomp!
  puts "Mining for coins starting with #{line}"
  (1..).each { |i|
    str = Digest::MD5.hexdigest line + i.to_s
    if str[0..5] == "000000"
      puts "#{i} is final result, #{line}#{i} -> #{str}"
      break
    end
  }
}
