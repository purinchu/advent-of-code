#!/usr/bin/env ruby

# 2015 Day 22 Part 2 / Puzzle 2015/44

class Puzzle
  def initialize()
    @boss = { }
    @min_mana_spent = 99999999999
    @min_mana_seq = []

    # mana required to cast each spell
    @mana_req = {
      'missile'  => 53,
      'drain'    => 73,
      'shield'   => 113,
      'poison'   => 173,
      'recharge' => 229,
    }

    # queue of spell casts used for a BFS
    @event_queue = [ ]
  end

  def decode(line)
    name, val = line.split(/: /)
    @boss[name] = val.to_i
  end

  def boss
    @boss
  end

  def check_lowest_mana(new_total_mana, spells)
    if new_total_mana < @min_mana_spent
      @min_mana_spent = new_total_mana
      @min_mana_seq = spells
    end
  end

  # effects is a 3-array, each value is either 0 (inactive) or the number of
  # turns remaining.  The 3 elements in order represent shield, poison, recharge
  def process_effects(effects, boss_hp, player_mana)
    player_armor = 0
    new_boss_hp = boss_hp
    new_player_mana = player_mana

    if effects[0] > 0
      # shield
      player_armor = 7
    end

    if effects[1] > 0
      # poison
      new_boss_hp = boss_hp - 3
    end

    if effects[2] > 0
      # recharge
      new_player_mana = player_mana + 101
    end

    # update timers
    new_effects = effects.map { |x| [0, x-1].max }

    return [player_armor, new_boss_hp, new_player_mana, new_effects]
  end

  # spell is the spell to cast
  # effects is an array of effects in operation
  # boss is the boss info (HP, DMG)
  # player is likewise (HP, ARMR, MANA)
  #
  # In each round the player goes, then the boss (if needed).
  def fight_round(spell, effects, boss_hp, boss_atk, player_hp, player_mana, total_mana_spent, spells)
    # player phase

    if total_mana_spent > @min_mana_spent
      # early exit if it's not possible to beat the current record
    end

    # HARD MODE
    player_hp = player_hp - 1
    if player_hp <= 0
      return
    end

    # process existing effects first before allowing player to use their turn
    armor, new_boss_hp, new_player_mana, new_effects =
      self.process_effects(effects, boss_hp, player_mana)

    if new_boss_hp <= 0
      # winrar
      self.check_lowest_mana(total_mana_spent, spells)
      return
    end

    # first ensure we have mana. If not the player will lose.
    new_player_mana = new_player_mana - @mana_req[spell]
    if new_player_mana < 0
      return
    end

    # next ensure the spell is legal to case
    if spell == 'shield' and new_effects[0] > 0
      return
    elsif spell == 'poison' and new_effects[1] > 0
      return
    elsif spell == 'recharge' and new_effects[2] > 0
      return
    end

    # spell is cast, now figure out effects and damage
    new_total_mana_spent = total_mana_spent + @mana_req[spell]
    new_player_hp = player_hp

    # these are instants, run before effects
    if spell == 'missile'
      new_boss_hp = new_boss_hp - 4
    elsif spell == 'drain'
      new_boss_hp = new_boss_hp - 2
      new_player_hp = new_player_hp + 2
    end

    if new_boss_hp <= 0
      self.check_lowest_mana(new_total_mana_spent, spells)
      return
    end

    # turn on effects if any applied
    if spell == 'shield'
      new_effects[0] = 6
    elsif spell == 'poison'
      new_effects[1] = 6
    elsif spell == 'recharge'
      new_effects[2] = 5
    end

    # boss still alive, run its turn

    # process effects again
    armor, new_boss_hp, new_player_mana, new_effects =
      self.process_effects(new_effects, new_boss_hp, new_player_mana)

    if new_boss_hp <= 0
      # winrar
      self.check_lowest_mana(new_total_mana_spent, spells)
      return
    end

    # boss attack
    new_player_hp = new_player_hp - [1, boss_atk - armor].max
    if new_player_hp <= 0
      return
    end

    'missile drain shield poison recharge'.split(' ').each { |new_spell|
      # we don't want to be 'clever' here about removing 'impossible' spells
      # early because things like recharge may mean we have enough mana, we can
      # afford 1 free tick on effects and still re-cast the spell next turn,
      # etc.
      new_spells = spells.dup
      new_spells.push("#{new_player_hp}/#{new_player_mana}", new_spell)
      new_event = [ new_spell, new_effects, new_boss_hp, boss_atk, new_player_hp, new_player_mana, new_total_mana_spent, new_spells ]

      @event_queue.push(new_event)
    }
  end

  def run_scenarios
    # for this scenario, we just breadth-first search on all permutations of
    # casting one of the 5 spells in order.  Each that beat the boss record its
    # total mana cost and if the current sequence has a higher mana cost we can
    # stop.

    # start the scenario by pushing one of each spell onto the queue, and then
    # pulling from the queue until it empties (BFS).

    'missile drain shield poison recharge'.split(' ').each { |new_spell|
      @event_queue.push([ new_spell, [0, 0, 0], @boss['Hit Points'], @boss['Damage'], 50, 500, 0, [ new_spell ] ])
    }

    while !@event_queue.empty?
      ev = @event_queue.shift
      self.fight_round(*ev)
    end

    puts "Lowest mana expense: #{@min_mana_spent}"
    puts "Sequence was: #{@min_mana_seq}"
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../43/input') { |line|
  p.decode(line.chomp)
}

puts "Boss info: #{p.boss}"
p.run_scenarios
