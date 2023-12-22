#!/usr/bin/env ruby

# 2015 Day 9 Part 2 / Puzzle 2015/18

class Puzzle
  include Enumerable

  def initialize()
    @distance = {}
    @cities = []
  end

  def decode(line)
    if not line.match(/^([\w]+) to ([\w]+) = ([\d]+)/)
      throw line
    end

    citypair = [$1, $2].sort.join('/')
    dist = Integer($3)

    @cities << $1
    @cities << $2
    @distance[citypair] = dist
  end

  def solve
    overall_max = @cities.uniq.permutation.map { |p|
      sum = 0

      p.each_cons(2) { |pair|
        a, b = pair
        sum += @distance[ [a, b].sort.join('/') ]
      }

      [p, sum]
    }.max_by { |p| p[1] }

    overall_max
  end

  def each(&block)
    @cities.each(&block)
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

max_pair = p.solve
puts "#{max_pair}"
