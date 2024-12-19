#!/usr/bin/env ruby

# 2024 Day 19 Part 1 / Puzzle 2024/37

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

  def designs
    @designs
  end

  def towels
    @towels
  end
end

hdr, designs = File.read(ARGV.shift || '../37/input').split("\n\n")

p = Puzzle.new(hdr, designs)

num_possible = p.designs.filter { |d| p.num_matches(d) > 0 }.count
puts "#{num_possible} are possible"
