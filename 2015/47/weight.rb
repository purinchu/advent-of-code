#!/usr/bin/env ruby

# 2015 Day 24 Part 1 / Puzzle 2015/47

class Puzzle
  def initialize()
    @weights = [ ]
  end

  def decode(line)
    @weights.push line.to_i
  end

  def weights
    @weights
  end
end

def popcount(i)
  m1 = 0x55555555
  m2 = 0x33333333
  m4 = 0x0f0f0f0f

  i -= (i >> 1) & m1
  i = (i & m2) + ((i >> 2) & m2)
  i = (i + (i >> 4)) & m4
  i += i >> 8

  return (i + (i >> 16)) & 0x3f
end

def id_to_mask(i)
  list = []
  (0..31).each { |n|
    list.push(n) if ((1 << n) & i) != 0
  }
  return list
end

def entries_valid?(*xs)
  val = 0
  sum = 0

  xs.each { |x|
    val |= x
    sum += popcount(x)
  }

  # this can be true only if the bits for all entries have no duplicate bits
  # set, otherwise popcount(val) will be < sum
  return (sum == popcount(val))
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../47/input') { |line|
  p.decode(line.chomp)
}

w = p.weights.sort
tot = w.sum / 3
puts "#{w.length} items"
puts "group weight should be #{tot}"

# find maximum number of weights needed in a group
max_len = (1..w.length).each.map { |n|
  [n, w[0..(n-1)].sum]
}.lazy.filter { |s| s[1] >= tot }.first[0]

# find minimum number by looking at largest numbers
min_len = (1..w.length).each.map { |n|
  [n, w.reverse[0..(n-1)].sum]
}.lazy.filter { |s| s[1] >= tot }.first[0]

puts "Need between #{min_len} - #{max_len} at worst"

# we may have a cached list of matches already. If so load those so avoid 90%
# of processing time and allow solution iteration.
matches = [ ]

max_count = (1 << w.length);
t = Process.clock_gettime(Process::CLOCK_MONOTONIC)

(0..max_count).each { |i|
  bitcount = popcount(i)
  next if (bitcount < min_len or bitcount > max_len)

  s = id_to_mask(i).map { |m| w[m] }.sum
  if s == tot
    matches.push(i)
  end
  if (i % 1000000 == 0)
    t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = t2 - t
    t = t2
    pct = i * 100.0 / max_count
    puts "Checkpoint #{i} / #{max_count} (#{pct}%). #{matches.length} matches so far. #{elapsed} since last checkpoint."
  end
}

# now we know what matches are present, we need to take them 3 at a time and
# make sure there's no overlap.  These are the possible groups that can make up
# the sleigh.  Of these 3 we record the smallest group(s).
#
# Doing this naively leads to 55 quadrillion or so potential combinations (450K
# ^ 3) But we only need to look at the matches with the smallest group (i.e.
# smallest popcount) and then we just need to find any possible other two
# groups that don't cause an overlap.

puts "Sorting #{matches.length} matches by ID mask"
matches.sort! # needed for bsearch below

puts "Sorting weight groups by number of presents"
match_groups = matches.group_by { |x| popcount(x) }

overall_smallest_grp = match_groups.keys.min

# There's almost certainly a match within the smallest group, so just sort by
# the product of the weights and then iteratively try to find the first
# possibility that is actually achievable
smallest_grp = match_groups[overall_smallest_grp].sort_by { |el|
  id_to_mask(el).map { |m| w[m] }.reduce(:*)
}

puts "Searching through #{smallest_grp.length} possible Group 1s"

smallest_grp.each { |id1|
  # need to find 2 other groups.  In principle we can do this by iterating
  # through all the groups to make the 2nd choice.  With each selection, what
  # the third group *has* to be is a specific bitstring which, if present as a
  # match, means all 3 groups work.
  puts "Options start with group #{id1}"
  puts "QE is #{id_to_mask(id1).map { |m| w[m] }.reduce :*}"

  # if we search by smallest popcounts to largest, we can stop searching midway
  # through, which cuts out about half the decision space

  stop_after = ((w.length - popcount(id1)) / 2.0).ceil

  (overall_smallest_grp..stop_after).each { |mgrp|
    match_groups[mgrp].each { |id2|

      next unless entries_valid?(id1, id2)

      puts "\tGroup 2 might be #{id2}"

      id3 = (1 << w.length) - 1 # all 1s which we'll then mask off found 1s
      id3_str = id3.to_s(2).length

      id1_w = id_to_mask(id1).map { |m| w[m] }.sum
      id2_w = id_to_mask(id2).map { |m| w[m] }.sum

      puts "\t#{id3.to_s(2)} -"
      puts "\t#{id1.to_s(2).rjust(id3_str, '0')} (#{id1_w}) -"
      puts "\t#{id2.to_s(2).rjust(id3_str, '0')} (#{id2_w}) ="
      id3 &= ~id1
      id3 &= ~id2
      id3_w = id_to_mask(id3).map { |m| w[m] }.sum
      puts "\t#{id3.to_s(2).rjust(id3_str, '0')} (#{id3_w})"

      id3_match = matches.find { |x| x == id3 }

      if !id3_match.nil? and entries_valid?(id1, id2, id3)
        # MATCH FOUND
        puts "Found match: #{id1}, #{id2}, #{id3}"
        puts "popcounts: #{popcount(id1)}, #{popcount(id2)}, #{popcount(id3)}"
        l1 = id_to_mask(id1).map { |m| w[m] }
        puts "If true, the QE is #{l1.reduce :*}"
        exit 0
      end
    }
  }
}
