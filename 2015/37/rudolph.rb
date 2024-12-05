#!/usr/bin/env ruby

# 2015 Day 19 Part 1 / Puzzle 2015/37

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

puts p.substitutions
puts p.input

matches = Hash.new { |hash, key| hash[key] = 0 }

p.substitutions.each_pair { |base, repl_list|
  repl_list.each { |repl|
#   puts "Testing #{base} -> #{repl} against #{p.input}"

    idx = p.input.index(base)
    while not idx.nil?
      b = p.input.dup
      b[idx, base.length] = repl
#     puts "\t #{p.input} -> #{b}@#{idx}"
      matches[b] = matches[b] + 1
      idx = p.input.index(base, idx+1)
    end
  }
}

puts matches.keys.length
