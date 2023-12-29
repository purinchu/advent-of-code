#!/usr/bin/env ruby

# 2015 Day 15 Part 1 / Puzzle 2015/29

class Puzzle
  def initialize()
    @ratings = { }
  end

  def decode(line)
    name, stats = line.split(': ')
    stat_groups = stats.split(', ')
    # [0..-2] to ignore the final category for now
    stat_vals = stat_groups.map { |s| s.split(' ')[1].to_i }[0..-2]
    @ratings[name] = stat_vals
  end

  def ratings
    @ratings
  end

  # multi-level looping. arrs is an array of ints treated as a counter, intended to enumerate
  # all possibilities of 0..arrs[i] foreach i in arrs
  def loop_over(arrs, vals, &block)
    f, *arr = arrs
    if arr.empty?
      f.times { |i| block.call([vals, i].flatten) }
    else
      f.times { |i| loop_over(arr, [vals, i].flatten, &block) }
    end
  end

  def max_unlimited
    max_score = 0
    max_counts = []

    ingredients = @ratings.keys
    num_categories = @ratings.values.map { |v| v.length }.max
    num_combos = ingredients.count
    max_mg = 100
    counter = Array.new(num_combos, max_mg - (num_combos - 1) + 1)
    puts "Iterating over all combinations of #{num_combos} ingredients (#{num_categories})"

    loop_over(counter, []) { |counts|
      raise "oops" if counts.length != ingredients.length

      next if counts.sum != max_mg

      categories = Array.new(num_categories, 0)
      ingredients.each_index { |idx|
        quality = @ratings[ingredients[idx]]
        f = counts[idx]
        categories.each_index { |j|
          categories[j] += f * quality[j]
        }
      }

      if categories.min < 0
        next
      end

      score = categories.reduce { |a,b| a*b }

      if score > max_score
        max_score = score
        max_counts = counts
      end
    }

    puts "This mix had best option with score of #{max_score}:"
    max_counts.each_index { |idx|
      puts "\t#{max_counts[idx]} of #{ingredients[idx]} (#{@ratings[ingredients[idx]]})"
    }
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

p.max_unlimited
