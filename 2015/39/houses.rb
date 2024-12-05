#!/usr/bin/env ruby

# 2015 Day 20 Part 1 / Puzzle 2015/39

# Need to find the lowest number where adding up all prefix sums of 1..num is
# greater than the number provided on the command line.

min_num = ARGV.shift.to_i

if min_num == 0
  puts "You need to enter a number to use as minimum number for prefix sums to exceed on the command line"
  puts "Usage: #{$0} <num>"

  exit 1
end

nums = Array.new(min_num + 2, 1)

# 1 is accounted for in the default value being 1
(2..nums.length).each { |n|
  (n..nums.length).step(n) { |i|
    if i > 0
      nums[i - 1] += n
    end
  }
}

results = [ ]
nums.each_with_index { |n, idx|
  if n >= min_num
    results.push(idx)
  end
}

puts "#{results.min + 1}"
