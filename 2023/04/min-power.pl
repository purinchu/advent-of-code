#!/usr/bin/env perl

# AoC 2023 - Puzzle 04
# This problem requires to read in an input file one line at a time holding game records
# The line has the ID and a semicolon-separate set of results of cubes from a bag
# The puzzle is to determine the minimum number of cubes to make each game possible
# The sum of all product of minimum cubes for every game IDs is the puzzle solution.

use 5.036;
use autodie;
use experimental 'for_list';

use List::Util qw(min sum);
use Mojo::JSON qw(j);

# Config
my $input_name = '../03/input';
my $debug = 0;

# Globals

# Each game holds a listref to an array of results of red/green/blue cubes
my %games;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);
    read_game($line);
}

say j(\%games) if $debug;

my @min_games = map { min_cubes_for_game($games{$_}) } values %games;
my @powers    = map { $_->[0] * $_->[1] * $_->[2]    } @min_games;

say "Sum of power of min cube sets: ", sum(@powers);

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

sub min_cubes_for_game($game_ref)
{
    my @min_cubes = (999, 999, 999);

    for my $subgame (@$game_ref) {
        for my $i (0..2) {
            $min_cubes[$i] = min($min_cubes[$i], $subgame->[$i]);
        }
    }

    return \@min_cubes;
}
