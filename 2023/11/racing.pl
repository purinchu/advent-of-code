#!/usr/bin/env perl

# AoC 2023 - Puzzle 11
# This problem requires to read in an input file that ultimately
# lists information on boat races and wants you to find the number
# of ways you can win each race by pre-charging your boat at race start.
# the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);

# Config
my $input_name = @ARGV ? $ARGV[0] : 'input';
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

my $product_ways_to_win = List::Util::product (
    map { num_ways_to_win_race($_) } 0..$#times
    );
say "There are $product_ways_to_win ways to win";

# Aux subs

sub read_times($line)
{
    my (undef, $nums) = split(/: */, $line);
    @times = split(' ', $nums);
}

sub read_distances($line)
{
    my (undef, $nums) = split(/: */, $line);
    @distances = split(' ', $nums);
}

# return distance in mm if boat for race $id is charged for $time ms
sub distance_if_pressed($id, $time)
{
    my $total_time = $times[$id];
    my $time_traveling = $total_time - $time;
    my $speed = $time;

    return $speed * $time_traveling;
}

sub num_ways_to_win_race($id)
{
    my $dist_to_beat = $distances[$id];
    my @time_options = 1..($times[$id] - 1);
    my @distances_seen = map { distance_if_pressed($id, $_) } @time_options;
    my @winners = grep { $_ > $dist_to_beat } @distances_seen;

    return scalar @winners;
}
