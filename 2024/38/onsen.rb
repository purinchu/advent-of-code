#!/usr/bin/env ruby

# 2024 Day 19 Part 2 / Puzzle 2024/38

# quick 'n' dirty solution to get first star, will rewrite with Rust later but
# for now Ruby makes this easy.

class Puzzle
  def initialize(hdr, designs)
    @towels = hdr.split(', ').sort
    @designs = designs.split("\n")
    @stored_counts = { }
  end

  def num_matches(design)
    count = 0
    if @stored_counts.has_key?(design)
      return @stored_counts[design]
    end

    @towels.each { |t|
      if design === t
        # base case
        count += 1
        break
      end

      if design.start_with? t
        rest = design[(t.length)..]
        rem_count = num_matches(rest)
        if rem_count > 0
          count += rem_count
        end
      end
    }

    @stored_counts[design] = count
    return count
  end

  def designs
    @designs
  end
end

hdr, designs = File.read(ARGV.shift || '../37/input').split("\n\n")

p = Puzzle.new(hdr, designs)

num_possible = p.designs.map { |d| p.num_matches(d) }.sum
puts "#{num_possible} total designs are possible"
