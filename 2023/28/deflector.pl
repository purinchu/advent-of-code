#!/usr/bin/env perl

# AoC 2023 - Puzzle 28 (Day 14 Part 2)
# This problem requires to read in an input file that ultimately
# lists information about info grids to find where to readjust
# mirrors
# See the Advent of Code website.

use 5.038;
use autodie;

use List::Util qw(sum first zip);
use Hash::Util qw(hash_value);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_ROCKS => 0;
use constant G_DEBUG_STEP  => 0;
use constant G_MAX_CACHE   => 2047;
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

my %prev_cycles; # Try to detect if we've met an intermediate state
my @t = $grids[0]->@* or die "No grid???";

my $steps = $ARGV[0] // G_SPIN_CYCLES;
my $stop_at; # if we find a cycle we can flag what step to stop on

for (1..$steps) {
    # at cycle start, left is west

    # now left is north
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks
        1 while $str =~ s/(\.+)O/O$1/g;
    }

    # next face west
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks
        1 while $str =~ s/(\.+)O/O$1/g;
    }

    # next face south (by transpose then reverse)
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks (DIFFERENT REGEXP)
        1 while $str =~ s/O(\.+)/${1}O/g;
    }

    # next face east (by transpose then reverse)
    @t = transpose_strings(@t);

    for my $str (@t) {
        # move rocks (DIFFERENT REGEXP)
        1 while $str =~ s/O(\.+)/${1}O/g;
    }

    # left is still west
    if (G_DEBUG_STEP) {
        say "After step ", sprintf("%09d", $_), ":";
        say foreach @t;
        say "";
    }

    last if ($stop_at // 0) == $_; # if we know where to stop, keep going

    # See if we've encountered this intermediate state before
    my $state_str = join('', @t);
    if (my $seen_cycle = $prev_cycles{$state_str} // 0) {
        my $cycle_length = $_ - $seen_cycle;
        my $steps_left   = $steps - $_;
        $stop_at = $_ + ($steps_left % $cycle_length);
    } else {
        $prev_cycles{$state_str} = $_;
        die "intermediate cache too small" if %prev_cycles >= G_MAX_CACHE;
    }
}

if (G_DEBUG_ROCKS) {
    say foreach @t;
    say "";
    say "Stopped at $stop_at" if $stop_at;
}

# count weight on north platform. Since array assumes left is west-facing,
# must transpose to get an accurate weight.
my $sum = 0;
for my $str (transpose_strings(@t)) {
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
