#!/usr/bin/env ruby

# 2015 Day 13 Part 2 / Puzzle 2015/26

class Puzzle
  def initialize()
    @pairs = Hash.new {|h,k| h[k] = {} }
    @me = 'me'
  end

  def decode(line)
    d = line.match(/^([\w]+) would (gain|lose) ([\d]+) happ.*next to ([\w]+).$/)
    if d
      p, g_l, amt, other = d.captures
    end

    amt = amt.to_i
    amt = -amt if g_l == "lose"
    @pairs[p][other] = amt
    @pairs[@me][other] = 0
    @pairs[other][@me] = 0
  end

  def pairs
    @pairs
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

people = p.pairs.keys
perms = people.permutation
best = perms.map { |perm|
  total = 0
  [perm, perm[0]].flatten.each_cons(2) { |n1, n2|

    amt1 = p.pairs[n1][n2]
    amt2 = p.pairs[n2][n1]
    total += amt1
    total += amt2
  }

  [perm, total]
}.max_by { |el| el[1] }

puts best[1]
