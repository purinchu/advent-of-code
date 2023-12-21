#!/usr/bin/env ruby

# 2015 Day 7 Part 2 / Puzzle 2015/14

class Puzzle
  include Enumerable

  def initialize()
    @symtab = {}
    @values = {}
    @isreset = false
  end

  def assignOutput(result, expression)
    @symtab[result] = expression
  end

  def lookup(name)
    return @symtab[name]
  end

  def setVar(name, result)
    @values[name] = result
  end

  def var?(name)
    return @values.key?(name)
  end

  def reset?
    @isreset
  end

  def reset!
    @values = {}
    @isreset = true
  end

  def each(&block)
    @symtab.each(&block)
  end
end

class Op
  def initialize(p)
    @p = p
    @value = nil
    @was_reset = false
  end

  def evaluate
    if @p.reset? and not @was_reset
      @value = nil
      @was_reset = true
    end

    if @value.nil?
      @value = evaluate_impl
    end
    return @value
  end
end

class BinOp < Op
  def initialize(p, op, l, r)
    super(p)
    @l = l
    @r = r

    case op
    when "LSHIFT"
      @op = ->(l, r) { (l << r) & 0xFFFF }
    when "RSHIFT"
      @op = ->(l, r) { (l >> r) & 0xFFFF }
    when "AND"
      @op = ->(l, r) { (l & r) & 0xFFFF }
    when "OR"
      @op = ->(l, r) { (l | r) & 0xFFFF }
    else
      raise "Unhandled operation #{op}"
    end
  end

  def to_s
    return "#{@l} OP #{@r}"
  end

  def evaluate_impl
    val_l = @l.evaluate().to_i
    val_r = @r.evaluate().to_i
    return @op.(val_l, val_r)
  end
end

class UnaryOp < Op
  def initialize(p, op, operand)
    super(p)
    @operand = operand

    case op
    when "NOT"
      @op = ->(val) { (~val) & 0xFFFF }
    else
      raise "Unhandled operation #{op}"
    end
  end

  def to_s
    return "-(#{@op})"
  end

  def evaluate_impl
    return @op.(@operand.evaluate())
  end
end

class Var < Op
  def initialize(p, op)
    super(p)
    @op = op
  end

  def to_s
    return "#{@op}"
  end

  def evaluate_impl
    res = (@p.lookup(@op).evaluate()) & 0xFFFF
    @p.setVar(@op, res)
    return res
  end
end

class Literal < Op
  def initialize(p, op)
    super(p)

    @op = Integer(op)
  end

  def to_s
    return "#{@op}"
  end

  def evaluate_impl
    return @op
  end
end

def decode(line, p)
  # update state of puzzle p
  input, output = line.split(' -> ')

  result = nil

  read_lit = ->(term) {
    a = begin Literal.new(p, term) rescue Var.new(p, term) end
    return a
  }

  # input can be a literal number, binary operator, or unary op try them bin,
  # unary, literal. Make the output depend on the input being ready to manage
  # the flow graph.
  case input
  when /^(\w+) (AND|OR|LSHIFT|RSHIFT) (\w+)$/
    # binary op
    l = read_lit.($1)
    r = read_lit.($3)
    result = BinOp.new(p, $2, l, r)
  when /^NOT (\w+)$/
    # unary op
    operand = read_lit.($1)
    result = UnaryOp.new(p, 'NOT', operand)
  when /^(\w+)$/
    # literal. yes the input has vars too not just constants
    result = read_lit.($1)
  else
    raise "Can't understand #{line}"
  end

  p.assignOutput(output, result)
end

p = Puzzle.new()

File.foreach(ARGV.shift || 'input') { |line|
  decode(line.chomp, p)
}

val = p.lookup('a').evaluate
puts "Resetting with b = #{val}"

p.reset!
p.assignOutput('b', Literal.new(p, val))

puts p.lookup('a').evaluate
