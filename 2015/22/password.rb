#!/usr/bin/env ruby

# 2015 Day 11 Part 2 / Puzzle 2015/22

class Puzzle
  def initialize()
    @password = ''
  end

  def decode(line)
    @password = line
  end

  def ok?
    # look for chunks of 3 or more increasing triples
    inc_triple = @password.each_char
      .chunk_while{|a, b| b === a.next }
      .any? {|a| a.size >= 3}
    no_banned_letters = @password !~ /[iol]/
    diff_pairs = @password =~ /([a-z])\1.*([a-z])\2/

    inc_triple && diff_pairs && no_banned_letters
  end

  def next_password
    @password.next!
  end

  def password
    @password
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

p.next_password # input pw is valid but expired
p.next_password until p.ok?

puts p.password
