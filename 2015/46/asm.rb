#!/usr/bin/env ruby

# 2015 Day 23 Part 2 / Puzzle 2015/46

class Puzzle
  def initialize()
    @code = [ ]
    @regs = [ 1, 0 ]
    @ip = 0
    @cycles = 0
  end

  def decode(line)
    op, regoff = line.split(' ', 2)

    reg, off = ['', '']
    if !regoff.index(',').nil?
      reg, off = regoff.split(', ')
    elsif regoff =~ /[-+]/
      reg, off = ['', regoff]
    else
      reg, off = [regoff, 0]
    end

    @code.push([op, reg, off.to_i])
  end

  def rom
    @code
  end

  def regs
    @regs
  end

  def cycles_run
    @cycles
  end

  def run_once
    # check whether still in memory
    return false if @ip >= @code.length

    @cycles += 1

    raise "Stuck?" if @cycles > 5_000_000

    op, reg, off = @code[@ip]
    reg_id = (reg == 'a') ? 0 : 1

    puts "OP: #{op} #{reg}(#{reg_id}), #{off}. A: #{regs[0]} B: #{regs[1]} IP: #{@ip}" if @cycles % 1000 == 0

    case op
    when 'hlf'
      @regs[reg_id] /= 2
      @ip += 1
    when 'tpl'
      @regs[reg_id] *= 3
      @ip += 1
    when 'inc'
      @regs[reg_id] += 1
      @ip += 1
    when 'jmp'
      @ip += off
    when 'jie'
      @ip += ((@regs[reg_id] % 2 == 0) ? off : 1)
    when 'jio'
      @ip += ((@regs[reg_id] == 1) ? off : 1)
    else
      raise "Unknown instruction"
    end

#   puts "+OP: #{op} #{reg}(#{reg_id}), #{off}. A: #{regs[0]} B: #{regs[1]} IP: #{@ip}"

    return true
  end

  def run
    1 while self.run_once
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../45/input') { |line|
  p.decode(line.chomp)
}

p.run

puts "#{p.cycles_run} cycles. A: #{p.regs[0]} B: #{p.regs[1]}"
