#!/usr/bin/env ruby

# 2015 Day 24 Part 1 / Puzzle 2015/47

class Puzzle
  def initialize()
    @weights = [ ]
    @solutions = [ ]
    @lowest_partial = 99
  end

  def decode(line)
    @weights.push line.to_i
  end

  def weights
    @weights
  end

  def solutions
    @solutions
  end

  # Recursively look for all ways to add to tot (without exceeding the best
  # known minimum group length). Solutions will be in @solutions, not the
  # return value. Nil return value forces early exit
  def sum_for(remaining, tot, partials)
    # group too long
    return if partials.length > @lowest_partial

    s = partials.sum

    if s == tot
      puts "Found #{partials}"

      if partials.length < @lowest_partial
        @solutions = [ ] # reset
        @lowest_partial = partials.length
      end

      @solutions.push partials
      return
    end

    # bail early as we can't fit remaining numbers in
    return if s > tot

    # burn down through remaining array with existing partials
    remaining.each_index { |idx|
      n = remaining[idx]
      rest = remaining[(idx+1)..]
      res = sum_for(rest, tot, [partials, n].flatten)
    }
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../47/input') { |line|
  p.decode(line.chomp)
}

w = p.weights.sort.reverse
tot = w.sum / 3
puts "#{w.length} items"
puts "group weight should be #{tot}"

p.sum_for(w, tot, [])

puts "#{p.solutions.length} possible entries"

qe = p.solutions.map { |sol| sol.reduce :* }.min
puts "Minimum QE is now #{qe}"
