#!/usr/bin/env ruby

# 2015 Day 19 Part 2 / Puzzle 2015/38

class Puzzle
  def initialize()
    @subs = Hash.new {
      |hash, key| hash[key] = Array.new
    }
    @awaiting_input = false
    @base_molecule
  end

  def decode(line)
    if line.empty?
      @awaiting_input = true
    elsif @awaiting_input
      @base_molecule = line
    else
      base, replacement = line.split(/ => /)
      @subs[base].push(replacement)
    end
  end

  def substitutions
    @subs
  end

  def input
    @base_molecule
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../37/input') { |line|
  p.decode(line.chomp)
}

# look for productions which are unique and undo them all first.  (note: for
# both the input and the sample data, all productions were 'unique' in that you
# could only get a specific production result from 1 possible rule)
rev_bases = Hash.new {
  |hash, key| hash[key] = Array.new
}

p.substitutions.each_pair { |base, repl_list|
  repl_list.each { |repl|
    rev_bases[repl].push(base)
  }
}

# idiot check the assumption above, to look for cases that break my assumption
# and are actually not unique productions
max_sources = rev_bases.values.map{|x| x.length}.max
if max_sources > 1
  puts "Too complicated!"
  exit 1
end

# start reversing productions starting from the longest productions to the
# shortest since this will cause the resulting string to potentially have new
# longer productions that will be possible, just keep doing this over and over.
#
# I don't actually agree that this is logically sound, but worked fine on the
# data input I was provided.
rev_keys = rev_bases.keys.sort_by { |x| x.length }.reverse

steps = 0
start_str = p.input

(1..100).each {
  for key in rev_keys
    replacement = rev_bases[key][0]
    changed = false

    while start_str.include?(key)
      start_str = start_str.sub(key, replacement)
      steps += 1
      changed = true
    end

    if changed
      puts "#{key} -> #{replacement}"
      puts "input now #{start_str} (#{steps} steps)"
    end

    if start_str === "e"
      break
    end
  end

  if start_str === "e"
    break
  end
}

# if we make it here there's probably a problem. The script above worked
# fine on the input I was given.

if start_str != "e"
  puts "Good luck finding the rest of the steps from here, assuming this is event on the right track!"
  exit 1
end
