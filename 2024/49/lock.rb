#!/usr/bin/env ruby

# 2024 Day 25 Part 1 / Puzzle 2024/49

# quick 'n' dirty solution to get first star, will rewrite with Rust later but
# for now Ruby makes this easy.

class Puzzle
  def initialize(keylocks)
    @keys = [ ]
    @locks = [ ]

    keylocks.each { |x|
      if x.split("\n")[0] == "#####"
        @locks.push x
      else
        @keys.push x
      end
    }
  end

  def keys
    @keys
  end

  def locks
    @locks
  end

  def lock_height(lock)
    heights = [0, 0, 0, 0, 0]

    lock.split("\n").drop(1).each { |line|
      (0..4).each { |i|
        heights[i] += line[i] == "#" ? 1 : 0
      }
    }

    return heights
  end

  def key_height(key)
    heights = [0, 0, 0, 0, 0]

    key.split("\n").reverse.drop(1).each { |line|
      (0..4).each { |i|
        heights[i] += line[i] == "#" ? 1 : 0
      }
    }

    return heights
  end
end

keylocks = File.read(ARGV.shift || '../49/input').split("\n\n")

p = Puzzle.new(keylocks)

puts "#{p.keys.length} keys"
puts "#{p.locks.length} locks"

count = 0

p.locks.each { |lock|
  lh = p.lock_height(lock)

  p.keys.each { |key|
    kh = p.key_height(key)

    if lh.zip(kh).map { |x| x.sum }.none? { |x| x > 5 }
      count += 1
    end
  }
}

puts "#{count}"
