#!/usr/bin/env ruby

# 2024 Day 11 Part 1 / Puzzle 2015/21

# quick 'n' dirty solution to get first star, will rewrite with Rust later but
# for now Ruby makes this easy. Won't be fast enough for part 2.

def split(stone, bleft)
  return stone unless bleft>0
  res = []
  stone.each { |s|
    if s == 0
      res.push(split([1],bleft-1))
    elsif s.to_s.length % 2 == 0
      s1 = s.to_s
      new_vals = [ s1[0...(s1.length/2)].to_i, s1[(s1.length/2)..].to_i ]
      res.push(split(new_vals, bleft-1))
    else
      res.push(split([s*2024],bleft-1))
    end
  }
  return res.flatten
end

File.foreach(ARGV.shift || 'input') { |line|
  res = split(line.split(' ').map { |x| x.to_i }, 25)
  puts "#{res.length}"
}
