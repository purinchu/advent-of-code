#!/usr/bin/env ruby

# 2015 Day 8 Part 1 / Puzzle 2015/15

class Puzzle
  def initialize()
    @sum = 0
  end

  def sum
    @sum
  end

  def read_str(cur, rest)
    # initially in 'start' state
    cur = ''
    e = rest.each_char
    if e.next != '"'
      raise "#{rest} is not a valid string!"
    end

    return read_in_str(cur, e)

    return cur
  end

  def read_in_str(cur, e)
    # reads until an escape char reached
    ch = e.next
    case ch
    when '\\'
      return read_in_escape(cur, e)
    when '"'
      return cur
    else
      read_in_str(cur + ch, e)
    end
  end

  # 0-9a-f only!
  def hex_to_dec(h)
    val = h.ord
    if val >= 'a'.ord
      return (val - 'a'.ord)
    end
    return (val - '0'.ord)
  end

  def read_in_escape(cur, e)
    # already read one backslash, what comes next?
    ch = e.next

    case ch
    when '\\'
      return read_in_str(cur + '\\', e)
    when '"'
      return read_in_str(cur + '"', e)
    when 'x'
      hex1, hex2 = [e.next, e.next] # e.take doesn't work?
      hex1, hex2 = [hex1, hex2].map { |ch| hex_to_dec(ch) }
      return read_in_str(cur + (hex1 * 16 + hex2).chr, e)
    else
      throw "Invalid escape seq in string at #{ch}"
    end
  end

  def decode(line)
    out = read_str('', line)

    @sum += (line.length - out.length)
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  p.decode(line.chomp)
}

puts p.sum
