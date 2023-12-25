#!/usr/bin/env ruby

# 2015 Day 14 Part 2 / Puzzle 2015/28

class Puzzle
  def initialize()
    @reindeer = { }
    @score = { }
  end

  def decode(line)
    d = line.match(/^([\w]+) can fly ([\d]+) km.s for ([\d]+) sec.*rest for ([\d]+) se/)
    raise "Illegible #{line}" unless d

    name, speed, time, rest = d.captures

    @reindeer[name] = [speed, time, rest].map &:to_i
    @score[name] = 0
  end

  def dist_at(name, t)
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

  def winning_at(t)
    scores = @reindeer.each_key.map { |r|
      [r, dist_at(r, t)]
    }
    m = scores.max_by { |arr| arr[1] }
    winners = scores.find_all { |arr| arr[1] == m[1] }
    winners.each { |arr| @score[arr[0]] = @score[arr[0]] + 1 }
  end

  def scores
    @score
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

1.upto(time) { |t|
  p.winning_at(t)
}

p.reindeer.each_key { |r|
  puts ("#{r} @#{time}: score #{p.scores.fetch(r, 'none')}")
}
