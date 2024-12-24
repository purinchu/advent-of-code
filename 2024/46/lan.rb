#!/usr/bin/env ruby

# 2024 Day 23 Part 2 / Puzzle 2024/46

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

  def all_connected?(*ns)
    ns.combination(2).map { |comb|
      comb.sort.join
    }.all? { |key| @edges.has_key?(key) }
  end

end

p = Puzzle.new()

File.foreach(ARGV.shift || '../45/input') { |line|
  p.decode(line.chomp)
}

visited = { }

largest_match = ''
warns = 0

found = false
num_combos = 14

while !found
  puts "Running through combinations of #{num_combos}"

  p.connections.each_pair { |n, conn|
    if num_combos > conn.length
      break
    end

    conn.combination(num_combos) { |comb|
      all_n = [n, *comb]

      key = all_n.sort.join (',')

      if !visited.has_key?(key)
        visited[key] = 1

        if p.all_connected?(*all_n)
          puts "#{key} success"

          if key.length > largest_match.length
            largest_match = key
            found = true
          elsif key.length == largest_match.length
            puts "WARN #{key} is a duplicate match!"
            warns += 1
          end
        end
      end
    }
  }

  if !found
    num_combos -= 1
    if num_combos <= 10
      break;
    end
  end
end

puts "Largest match: #{largest_match} (#{warns} warnings)"
