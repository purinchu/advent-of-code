#!/usr/bin/env ruby

# 2015 Day 20 Part 2 / Puzzle 2015/40

# Need to find the lowest number where adding up all prefix sums of 1..num is
# greater than the number provided on the command line, with a limit on how
# many sums are provided for each number.

min_num = ARGV.shift.to_i

if min_num == 0
  puts "You need to enter a number to use as minimum number for prefix sums to exceed on the command line"
  puts "Usage: #{$0} <num>"

  exit 1
end

nums = Array.new(min_num * 2, 0)

(1..nums.length).each { |n|
  (n..(n * 50)).step(n) { |i|
    if i > 0 and i < nums.length
      nums[i - 1] += n * 11
    end
  }

  # see if we can exit early based on being in the gap between (n-1) to n
  # (which won't be touched again)
  if nums[n - 1] >= min_num
    puts "Think we found it, n = #{n} and house number is #{nums[n-1]} compared to #{min_num}"
    exit 0
  end
}

results = [ ]
nums.each_with_index { |n, idx|
  if n >= min_num
    results.push(idx)
  end
}

first_house = results.min

puts "#{first_house + 1} which is #{nums[first_house]}"
