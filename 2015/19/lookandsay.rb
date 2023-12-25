#!/usr/bin/env ruby

# 2015 Day 10 Part 1 / Puzzle 2015/19

class Puzzle
  def initialize()
    @digits = []
  end

  def decode(line)
    @digits = line.split('').map &:to_i
  end

  def run_step
    new_a = @digits.chunk_while { |l,r| l==r }.to_a
    new_digits = new_a.map { |arr|
      [arr.length, arr[0]].join('')
    }
    decode(new_digits.join(''))
  end

  def to_s
    @digits.join('')
  end

  def digits
    @digits
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

40.times { |i|
  p.run_step
  puts "step #{i}"
}

puts p.digits.length
