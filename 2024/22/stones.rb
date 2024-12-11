#!/usr/bin/env ruby

# 2024 Day 11 Part 2 / Puzzle 2015/22

# quick 'n' dirty solution to get second star, will rewrite with Rust later but
# for now Ruby makes this easy. With memoizing, it was fast enough for part 2.

class Puzzle
  def initialize()
    @stored_counts = { }
  end

  def split(stone, bleft)
    return stone.length unless bleft>0

    count = 0
    stone.each { |s|
      new_vals = []
      key = "#{bleft}-#{s}"

      if @stored_counts.has_key?(key)
        count += @stored_counts[key]
        next
      end

      if s == 0
        new_vals.push(1)
      elsif s.to_s.length % 2 == 0
        s1 = s.to_s
        new_vals = [ s1[0...(s1.length/2)].to_i, s1[(s1.length/2)..].to_i ]
      else
        new_vals.push(s * 2024);
      end

      @stored_counts[key] = self.split(new_vals, bleft - 1)
      count += @stored_counts[key]
    }

    return count
  end
end

File.foreach(ARGV.shift || '../21/input') { |line|
  p = Puzzle.new()
  res = p.split(line.split(' ').map { |x| x.to_i }, 75)
  puts "#{res}"
}
