#!/usr/bin/env ruby

# 2015 Day 21 / Puzzle 2015/41

class Puzzle
  def initialize()
    @boss = { }

    # these are all structured:
    # name, cost, dmg, armor, type
    @weapons = [
      [ 'Dagger',      8, 4, 0, 'weapon' ],
      [ 'Shortsword', 10, 5, 0, 'weapon' ],
      [ 'Warhammer',  25, 6, 0, 'weapon' ],
      [ 'Longsword',  40, 7, 0, 'weapon' ],
      [ 'Greataxe',   74, 8, 0, 'weapon' ],
    ]

    @armors = [
      [ 'Leather',     13, 0, 1, 'armor' ],
      [ 'Chainmail',   31, 0, 2, 'armor' ],
      [ 'Splintmail',  53, 0, 3, 'armor' ],
      [ 'Bandedmail',  75, 0, 4, 'armor' ],
      [ 'Platemail',  102, 0, 5, 'armor' ],
    ]

    @rings = [
      [ 'Damage +1',   25, 1, 0, 'ring' ],
      [ 'Damage +2',   50, 2, 0, 'ring' ],
      [ 'Damage +3',  100, 3, 0, 'ring' ],
      [ 'Defense +1',  20, 0, 1, 'ring' ],
      [ 'Defense +2',  40, 0, 2, 'ring' ],
      [ 'Defense +3',  80, 0, 3, 'ring' ],
    ]
  end

  def decode(line)
    name, val = line.split(/: /)
    @boss[name] = val.to_i
  end

  def boss
    @boss
  end

  def fight_loadout(loadout)
    # loop between player and boss until HP = 0
    hp = 100
    boss_hp = @boss['Hit Points']

    atk = loadout[2]
    boss_atk = @boss['Damage']

    armor = loadout[3]
    boss_armor = @boss['Armor']

    player_dmg = [1, atk - boss_armor].max
    boss_dmg =   [1, boss_atk - armor].max

    # dmg and HP are constant so can probably just divide HP by dmg and give
    # ties to the player, but we'll game it out...
    while true
      # player turn
      boss_hp -= player_dmg
      if boss_hp <= 0
        return true
      end

      # boss turn
      hp -= boss_dmg
      if hp <= 0
        return false
      end
    end
  end

  def permute_loadouts
    # we can have exactly 1 weapon, up to 1 armor, and up to 2 rings.  cost is
    # no object, but we are trying to minimize it
    highest_cost = 0
    highest_loadout = ''
    @weapons.each { |weap|
      [@armors.permutation(0), @armors.permutation(1)].each { |it|
        it.each { |arm|
          [@rings.permutation(0), @rings.permutation(1), @rings.permutation(2)].each { |it2|
            it2.each { |rn|

              loadout = [weap, *arm, *rn].filter{|arr| !arr.empty?}

              summary = loadout.reduce(['?', 0, 0, 0, 'total']) { |total, i|
                ['?', total[1] + i[1], total[2] + i[2], total[3] + i[3], 'total']
              }

              if not fight_loadout(summary)
                if summary[1] > highest_cost
                  highest_cost = summary[1]
                  highest_loadout = loadout
                end
              end

            }
          }
        }
      }
    }

    puts "Highest cost to lose was #{highest_cost} with #{highest_loadout}"
  end
end

p = Puzzle.new()

File.foreach(ARGV.shift || '../41/input') { |line|
  p.decode(line.chomp)
}

puts "Boss info: #{p.boss}"
p.permute_loadouts
