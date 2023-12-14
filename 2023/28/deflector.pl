#!/usr/bin/env perl

# AoC 2023 - Puzzle 28 (Day 14 Part 2)
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
use constant G_DEBUG_STEP  => 1;
use constant G_SPIN_CYCLES => 1_000_000_000;

my $input_name = '../27/input';
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

my @t = $grids[0]->@* or die "No grid???";

my $steps = $ARGV[0] // G_SPIN_CYCLES;
my $last_str = '';

for (1..$steps) {
    # at cycle start, left is west

    # now left is north
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks
        1 while $str =~ s/(\.+)O/O$1/;
    }

    # next face west
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks
        1 while $str =~ s/(\.+)O/O$1/;
    }

    # next face south (by transpose then reverse)
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks (DIFFERENT REGEXP)
        1 while $str =~ s/O(\.+)/${1}O/;
    }

    # next face east (by transpose then reverse)
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks (DIFFERENT REGEXP)
        1 while $str =~ s/O(\.+)/${1}O/;
    }

    my $saved_str = join('', @t);
    if ($saved_str eq $last_str) {
        say "Bailing at step $_, seems stable";
        last;
    }

    $last_str = $saved_str;

    # left is still west
    if (G_DEBUG_STEP) {
        say "After step ", sprintf("%09d", $_), ":";
        say foreach @t;
        say "";
    }
}

if (G_DEBUG_ROCKS) {
    @t = transpose_strings(@t);
    say "";
    say foreach @t;
}

# count weight
my $sum = 0;
for my $str (@t) {
    my $idx = 0;
    while(($idx = index($str, 'O', $idx)) != -1) {
        $sum += length($str) - $idx++;
    }
}

say $sum;

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
