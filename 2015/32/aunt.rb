#!/usr/bin/env ruby

# 2015 Day 16 Part 2 / Puzzle 2015/32

class Puzzle
  def initialize()
    @aunts = [ ]
    @facts = {
      "children"    => 3,
      "cats"        => 7,
      "samoyeds"    => 2,
      "pomeranians" => 3,
      "akitas"      => 0,
      "vizslas"     => 0,
      "goldfish"    => 5,
      "trees"       => 3,
      "cars"        => 2,
      "perfumes"    => 1,
    }

    @detectors = {
      "children"    => "equal",
      "cats"        => "gt",
      "samoyeds"    => "equal",
      "pomeranians" => "lt",
      "akitas"      => "equal",
      "vizslas"     => "equal",
      "goldfish"    => "lt",
      "trees"       => "gt",
      "cars"        => "equal",
      "perfumes"    => "equal",
    }
  end

  def decode(line)
    id, stats = line.split(/Sue ([0-9]+): */, 2)[1..]

    id = id.to_i
    cur_aunt = { }

    stats.split(/, */).each { |compound|
      name, amount = compound.split(/: */)
      cur_aunt[name] = amount.to_i
    }

    @aunts[id] = cur_aunt
  end

  def aunts
    @aunts
  end

  def could_be_match?(id)
    aunt = @aunts[id]
    aunt.each { |key, value|
      cmp = @detectors[key]

      ok = false
      if cmp === "gt"
        ok = value > @facts[key]
      elsif cmp === "lt"
        ok = value < @facts[key]
      else
        ok = value === @facts[key]
      end

      return false unless ok
    }

    return true
  end

end

p = Puzzle.new()

File.foreach(ARGV.shift || '../31/input') { |line|
  p.decode(line.chomp)
}

opts = []

for i in 1..500
  if p.could_be_match?(i)
    opts.push(i)
  end
end

puts "#{opts}"

