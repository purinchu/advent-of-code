#!/usr/bin/env perl

# AoC 2023 - Puzzle 27 (Day 14 Part 1)
# This problem requires to read in an input file that ultimately
# lists information about info grids to find where to readjust
# mirrors
# See the Advent of Code website.

use 5.038;
use autodie;

use List::Util qw(sum first zip);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_ROCKS => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Globals

my @grids;   # read in data

# Code (Aux subs below)

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    local $/ = ""; # go into 'paragraph mode'
    chomp(my @paragraphs = <$input_fh>);
    @grids = load_input(@paragraphs);
};

# To roll rocks 'north', transpose and roll them 'west'
for my $g (@grids) {
    my @t = transpose_strings(@$g);

    if (G_DEBUG_ROCKS) {
        say foreach @t;
    }

    my $sum = 0;

    for my $str (@t) {
        # move rocks
        1 while $str =~ s/(\.+)O/O$1/;

        # count weight
        my $idx = 0;
        while(($idx = index($str, 'O', $idx)) != -1) {
            $sum += length($str) - $idx++;
        }
    }

    if (G_DEBUG_ROCKS) {
        @t = transpose_strings(@t);
        say "";
        say foreach @t;
    }

    say $sum;
}

# Aux subs

sub transpose_strings(@lines)
{
    return unless @lines;
    my @result;
    my $l = length($lines[0]);
    for (my $i = 0; $i < $l; $i++) {
        $result[$i] = join('', map { substr ($_, $i, 1) } @lines);
    }
    return @result;
}

sub load_input(@paras)
{
    map { [ split("\n", s/\n*$//r ) ] } @paras;
}
