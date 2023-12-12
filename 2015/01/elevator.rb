#!/usr/bin/env ruby

File.foreach('input') { |line|
  puts line.count('(') - line.count(')')
}
