#!/usr/bin/env ruby

# 2015 Day 14 Part 1 / Puzzle 2015/27

class Puzzle
  def initialize()
    @reindeer = { }
  end

  def decode(line)
    d = line.match(/^([\w]+) can fly ([\d]+) km.s for ([\d]+) sec.*rest for ([\d]+) se/)
    raise "Illegible #{line}" unless d

    name, speed, time, rest = d.captures

    @reindeer[name] = [speed, time, rest].map &:to_i
  end

  def state_at(name, t)
    r = @reindeer[name]
    raise "?? #{name}" unless r
    speed, fly_t, rest_t = @reindeer[name]
    cyc = fly_t + rest_t

    num_complete = t / cyc
    dist = num_complete * speed * fly_t
    if t % cyc
      # partial cycle
      added_fly_t = [fly_t, t % cyc].min
      dist += speed * added_fly_t
    end

    dist
  end

  def reindeer
    @reindeer
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

time = (ARGV.shift || '1000').to_i

p.reindeer.each_key { |r|
  puts ("#{r} @#{time}: #{p.state_at(r, time)}")
}
