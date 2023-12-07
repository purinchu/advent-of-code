#!/usr/bin/env perl

# AoC 2023 - Puzzle 12
# This problem requires to read in an input file that ultimately
# lists information on boat races and wants you to find the number
# of ways you can win each race by pre-charging your boat at race start.
# the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);
use POSIX qw(ceil);

# Config
my $input_name = @ARGV ? $ARGV[0] : '../11/input';
my $debug = 0;
$" = ', '; # For arrays interpolated into strings

# Globals
my @times;      # ms
my @distances;  # mm

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);

    next if $line =~ /^ *$/;

    if ($line =~ /^Time:/) {
        read_times($line);
    } elsif ($line =~ /Distance:/) {
        read_distances($line);
    } else {
        die "Unknown line $line";
    }
}

my $ways_to_win = num_ways_to_win_race();
say "There are $ways_to_win ways to win";

# Aux subs

sub read_times($line)
{
    my (undef, $nums) = split(/: */, $line);
    my @parts = split(' ', $nums);
    push @times, int join('', @parts);
}

sub read_distances($line)
{
    my (undef, $nums) = split(/: */, $line);
    my @parts = split(' ', $nums);
    push @distances, int join('', @parts);
}

sub num_ways_to_win_race
{
    my $race_time = $times[0];
    my $dist = $distances[0];

    # distance traveled is just time * (race_time - time)
    # This is a quadratic variable where a = -1, b = race_time, c = -race_distance

    my $a = -1;
    my $b = $race_time;
    my $c = -$dist;

    my $zero1 = (-$b + sqrt($b * $b - 4 * $a * $c)) / (2 * $a);
    my $zero2 = (-$b - sqrt($b * $b - 4 * $a * $c)) / (2 * $a);

    say "For this race, first zero at $zero1";
    say "For this race, next  zero at $zero2";

    # First try rounding down. If that doesn't win race then next value up will
    my $left = int $zero1;
    $left++ unless (($left * ($race_time - $left)) > $dist);

    my $right = ceil ($zero2);
    $right-- unless (($right * ($race_time - $right)) > $dist);

    return ($right - $left + 1);
}
