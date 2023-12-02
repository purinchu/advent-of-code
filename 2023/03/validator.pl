#!/usr/bin/env perl

# AoC 2023 - Puzzle 03
# This problem requires to read in an input file one line at a time holding game records
# The line has the ID and a semicolon-separate set of results of cubes from a bag
# The puzzle is to list which game IDs are possible given a set total of cubes
# The sum of all possible game IDs is the puzzle solution.

use 5.036;
use autodie;
use experimental 'for_list';

use List::Util qw(sum);
use Mojo::JSON qw(j);

# Config
my $input_name = 'input';
my $max_cubes = [12, 13, 14]; # Red/Green/Blue
my $debug = 0;

# Globals

# Each game holds a listref to an array of results of red/green/blue cubes
my %games;
my $sum = 0;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);
    read_game($line);
}

say j(\%games) if $debug;

my @possible_ids = map { int $_ } grep {
        is_game_possible($games{$_}, $max_cubes)
    } keys %games;

if ($debug) {
    say "Possible games: ", join (", ", sort { $a <=> $b } @possible_ids);
}

say "Sum of possible games: ", sum(@possible_ids);

# Aux subs

sub read_game($line)
{
    my ($id, $games) = split(/: */, $line);
    my @subgames = split(/; */, $games);
    my @stdscore;

    my %cube_table;

    # canonicalize game ID
    $id =~ s/^Game ?//;

    # canonicalize score
    for my $subgame (@subgames) {
        # reset count for 3 colors
        @cube_table{qw/red green blue/} = (0) x 3;

        my @cube_counts = split(/, */, $subgame);
        for my $cube_count (@cube_counts) {
            # should be just something like '5 red'
            my ($count, $color) = split(' ', $cube_count);
            $cube_table{$color} = int $count;
        }

        # read slice for the 3 colors
        push @stdscore, [ @cube_table{qw/red green blue/} ];

        # remove colors we know we read and ensure nothing is still there
        delete @cube_table{qw/red green blue/};
        die "Invalid color in game $id" if %cube_table;
    }

    $games{$id} = \@stdscore;
}

sub is_game_possible($game_ref, $max_games)
{
    # game_ref is listref to game to check.
    # max_games is listref to max count for each cube color in R/G/B order
    for my $subgame (@$game_ref) {
        my $possible = 1;
        for my $i (0..2) {
            $possible &&= $subgame->[$i] <= $max_games->[$i];
        }
        return 0 unless $possible;
    }

    return 1;
}
