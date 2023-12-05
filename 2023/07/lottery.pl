#!/usr/bin/env perl

# AoC 2023 - Puzzle 07
# This problem requires to read in an input file one line at a time holding scratchers
# Each line has a card ID, a list of winning numbers, and a list of numbers on the card
# Cards with numbers that are winning numbers each points. 1 point for 1 match and
# points double with each additional card thereafter.
# 4 matches on 1 card would be worth 8 points.
# The puzzle is to determine the sum of the card values in the file.

use 5.036;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum);
use Mojo::JSON qw(j);

# Config
my $input_name = @ARGV ? $ARGV[0] : 'input';
my $debug = 0;
$" = ', '; # For arrays interpolated into strings

# Globals

# Each game holds a listref to an array of [@$winners, @$numbers]
my @games;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);
    read_game($line);
}

say "Game read in";
use DDP;
p @games;

# Aux subs

sub read_game($line)
{
    my ($id, $nums) = split(/: */, $line);
    my ($win_text, $pick_text) = split(/ *\| */, $nums);
    my @winners = split(' ', $win_text);
    my @picked  = split(' ', $pick_text);

    push @games, [\@winners, \@picked];
}
