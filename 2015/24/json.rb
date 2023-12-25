#!/usr/bin/env ruby

# 2015 Day 12 Part 2 / Puzzle 2015/24

require 'json'

class Puzzle
  def initialize()
  end

  def decode(line)
    @data = JSON.parse(line)
  end

  def sum_hash(h)
    total = 0

    if h.values.any?{|v| v==="red"}
      return 0
    end

    h.each_pair {|_,v|
      case v
      when Integer
        total += v
      when Array
        total += sum_array(v)
      when Hash
        total += sum_hash(v)
      end
    }

    total
  end

  def sum_array(a)
    total = 0
    a.each { |v|
      case v
      when Integer
        total += v
      when Array
        total += sum_array(v)
      when Hash
        total += sum_hash(v)
      end
    }
    total
  end

  def sum
    sum_hash(@data)
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

puts p.sum
