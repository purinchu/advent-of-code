#!/usr/bin/env ruby

# 2015 Day 3 Part 2 / Puzzle 2015/06

class Sleigh
  def initialize()
    @x = 0
    @y = 0
    @map = { }
    self.note_visit()
  end

  def visits_made?()
    @map
  end

  def note_visit()
    @map[@y * 65536 + @x] = 1
  end

  def visit(char)
    case char
    when "<" then @x += 1
    when ">" then @x -= 1
    when "^" then @y -= 1
    when "v" then @y += 1
    end
    self.note_visit()
  end
end

File.foreach(ARGV.shift || 'input') { |line|
  santa = Sleigh.new()
  robo  = Sleigh.new()

  line.each_char.each_slice(2) { |s, r|
    santa.visit(s)
    robo.visit(r)
  }

  overlay_map = santa.visits_made?.merge(robo.visits_made?)

  puts overlay_map.length
}

