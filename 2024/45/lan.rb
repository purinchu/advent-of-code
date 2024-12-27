#!/usr/bin/env ruby

# 2024 Day 23 Part 1 / Puzzle 2024/45

# Something about finding sets of connected computers

class Puzzle
  def initialize()
    @codes = [ ]
    @conns = { }
    @edges = { }
  end

  def decode(line)
    l, r = line.split('-')

    if !@conns.has_key? (l)
      @conns[l] = [ ]
    end

    if !@conns.has_key? (r)
      @conns[r] = [ ]
    end

    @conns[l].push(r)
    @conns[r].push(l)
    @edges[[l,r].sort.join] = 1
  end

  def connections
    @conns
  end

  def all_connected?(n1, n2, n3)
    key1 = [n1, n2].sort.join
    key2 = [n1, n3].sort.join
    key3 = [n2, n3].sort.join

    return [key1, key2, key3].all? { |x| @edges.has_key?(x) }
  end

end

p = Puzzle.new()

File.foreach(ARGV.shift || '../45/input') { |line|
  p.decode(line.chomp)
}

visited = { }
count = 0

p.connections.each_pair { |n, conn|
  conn.combination(2) { |comb|
    n1, n2 = comb
    key = [n, n1, n2].sort.join
    if [n, n1, n2].all? { |x| x[0] != 't' }
      next
    end

    if !visited.has_key?(key)
      visited[key] = 1

      if p.all_connected?(n, n1, n2)
        count += 1
      end
    end
  }
}

puts "#{count}"
