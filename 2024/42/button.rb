#!/usr/bin/env ruby

# 2024 Day 21 Part 2 / Puzzle 2024/42

# Something about the shortest button string to force a robot (indirect through
# 2 robots and yourself) to enter a given code successfully.

# 7 8 9
# 4 5 6
# 1 2 3
#   0 A
#
# and
#
#   ^ A
# < v >
#
# are the button layouts. The robot always starts on 'A'.
#
# Written mostly in a cabin in a West Virginia state park w/ no internet
# access.
class Puzzle
  def initialize()
    @codes = [ ]
    @row_pos = { }
    @col_pos = { }
    @move_cache = { }
    @code_cache = { }

    %w[7 8 9].each { |i| @row_pos[i] = 0 }
    %w[4 5 6].each { |i| @row_pos[i] = 1 }
    %w[1 2 3].each { |i| @row_pos[i] = 2 }
    %w[  0 A].each { |i| @row_pos[i] = 3 }

    %w[7 4 1  ].each { |i| @col_pos[i] = 0 }
    %w[8 5 2 0].each { |i| @col_pos[i] = 1 }
    %w[9 6 3 A].each { |i| @col_pos[i] = 2 }

    # We can use same coord space for the num pad and dir pad
    # if we orient around 'A' always being in the same spot
    %w[< v >].each { |i| @row_pos[i] = 4 }
    @row_pos['^'] = 3 # next to A
    @col_pos['<'] = 0
    @col_pos['^'] = 1
    @col_pos['v'] = 1
    @col_pos['>'] = 2
  end

  def decode(line)
    @codes.push line.chomp
  end

  def clear_cache
    @move_cache = { }
    @code_cache = { }
  end

  def codes
    @codes
  end

  # Find keystroke sequences to move us (dx, dy) starting from (row, col)
  def resolve_to_zero(dx, dy, row, col)
    res = []
    if dx == 0 && dy == 0
      return ''
    end

    # ever pointing at row 3, col 0 (the blank space left of '^' and below '1')
    # will cause the robot to instantly panic.

    # we can get shortest strings by going the same direction repeatedly, so
    # only try the two cardinal directions we can go (accounting for the poison
    # cell above)
    x_str = (dx < 0) ? '<' : '>'
    x_str = x_str * dx.abs

    y_str = (dy < 0) ? '^' : 'v'
    y_str = y_str * dy.abs

    # needed for the .between? call, which requires first param be <= second
    minc = [col, col + dx].min
    maxc = [col, col + dx].max

    if dx != 0
      if dy == 0 || col == 0 || (!0.between?(minc, maxc) || row != 3)
        # dy == 0: if we're only moving in the current row we won't be asked to touch
        # the wrong gap.
        # col == 0: If col == 0 we're moving away, and we should do so first.
        # 0.between?: Is it possible to hit panic area with wrong x/y seq? If
        # so, ensure we're not already in the wrong row (if we are, the check
        # below will move us then).
        res.push (x_str + y_str)
      end
    end

    minr = [row, row + dy].min
    maxr = [row, row + dy].max

    if dy != 0
      # Similar to the logic of the col-first sequence above
      if dx == 0 || row == 3 || (!3.between?(minr, maxr) || col != 0)
        res.push (y_str + x_str)
      end
    end

    if (dx != 0 || dy != 0) && res.empty?
      throw "Empty result when a result is required! row=#{row}, col=#{col}, dx=#{dx}, dy=#{dy}"
    end

    return res
  end

  def row_of(ch)
    throw "row: #{ch}" unless @row_pos.has_key?(ch)
    return @row_pos[ch]
  end

  def col_of(ch)
    thcol "col: #{ch}" unless @col_pos.has_key?(ch)
    return @col_pos[ch]
  end

  def shortest_move_commands(start, stop)
    # Rather than Djikstra or whatever, just take advantage of the fact we know
    # we have to move over the specific number of rows and columns

    if start == stop
      # Hey look we're already there
      return ["A"]
    end

    key = "#{start}#{stop}"
    if @move_cache.has_key?(key)
      return @move_cache[key]
    end

    start_row = row_of(start)
    stop_row  = row_of(stop)
    start_col = col_of(start)
    stop_col  = col_of(stop)

    dx = stop_col - start_col
    dy = stop_row - start_row

    opts = resolve_to_zero(dx, dy, start_row, start_col)
    opts.each { |opt| opt.concat('A') }

    groups = opts.group_by { |x| x.length }
    min_group = groups.keys.min

    opts = groups[min_group]
    @move_cache[key] = opts
    return opts
  end

  def do_code_step(cur_ch, level, next_ch, rest)
    # if level = 0, we no longer recursively sub-expand our strings to find
    # their lengths but instead return length directly

    res = shortest_move_commands(cur_ch, next_ch)

    if level == 0
      min_len = res.map { |x| x.length }.min

      if rest.empty?
        # base case
        return min_len
      else
        # sum across
        remainder = do_code_step(next_ch, level, rest[0], rest[1..])
        return min_len + remainder
      end
    end

    key = [level, '/', cur_ch, next_ch, rest].join
    if @code_cache.has_key?(key)
      return @code_cache[key]
    end

    # level != 0
    # we need to drill down on the sub-components broken up by each 'A' press
    # and find the min-length of each possible segment, to find the best
    # segment we can report as an overall possibility.  The segments that sum
    # to the smallest value is the overall minimum length of the overall
    # possibility
    possible_lens = res.map { |overall_seg|
        do_code_step('A', level - 1, overall_seg[0], overall_seg[1..])
    }

    remainder = 0
    if !rest.empty?
      remainder = do_code_step(next_ch, level, rest[0], rest[1..])
    end

    @code_cache[key] = possible_lens.min + remainder
    return @code_cache[key]
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../41/input') { |line|
  p.decode(line.chomp)
}

puts "Puzzle codes: #{p.codes}"

sum = 0

p.codes.each { |code|
  min_len = p.do_code_step('A', 25, code[0], code[1..])
  puts "#{code} min len? #{min_len}"
  sum += code[0..3].to_i * min_len
}

puts "Final sum: #{sum}"
