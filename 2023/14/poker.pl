#!/usr/bin/env perl

# AoC 2023 - Puzzle 14
# This problem requires to read in an input file that ultimately
# lists information on camel cards.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);
use POSIX qw(ceil);

# Config
my $input_name = @ARGV ? $ARGV[0] : '../13/input';
my $debug = 0;
$" = ', '; # For arrays interpolated into strings

# Globals
my %hands;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);
    read_hand($line);
}

my @ordered_hands = sort { score_hands($a, $b) } keys %hands;

$debug = 1; grade_hand_tier($_) foreach @ordered_hands;

my $sum = 0;
for (my $i = 0; $i < @ordered_hands; $i++) {
    my $rank = $i + 1;
    my $bid  = $hands{$ordered_hands[$i]};
    $sum += $rank * $bid;
}

say $sum;

# Aux subs

sub read_hand($line)
{
    my ($hand, $bid) = $line =~ /^(.{5}) (\d+)/;
    $hands{$hand} = $bid;
}

sub grade_hand_tier($hand)
{
    state @grades = map { int } qw(
        -1 -1
        1 1
        2 3
        4 5
        6 6
        7 7
    );

    state @labels = (
        'impossible', 'impossible',
        'high card', 'high card',
        'one pair', 'two pair',
        'three of a kind', 'full house',
        'four of a kind', 'four of a kind',
        'five of a kind', 'five of a kind',
    );

    my %counts;
    $counts{$_}++ foreach split('', $hand);
    my @result = reverse sort values %counts;

    my $lookup = $result[0] * 2 + (($result[1] // 0) == 2);
    say "$hand: $labels[$lookup], tier $grades[$lookup]" if $debug;

    return $grades[$lookup];
}

sub score_card($ca, $cb)
{
    state %scores = (
        J  => 0,
        2  => 1,
        3  => 2,
        4  => 3,
        5  => 4,
        6  => 5,
        7  => 6,
        8  => 7,
        9  => 8,
        T  => 9,
        Q  => 11,
        K  => 12,
        A  => 13,
    );

    return $scores{$ca} <=> $scores{$cb};
}

sub score_hands($ha, $hb)
{
    my $score = grade_hand_tier($ha) <=> grade_hand_tier($hb);
    return $score if $score != 0;

    # tiebreakers
    my @letters_a = split('', $ha);
    my @letters_b = split('', $hb);

    for (my $i = 0; $i < 5; $i++) {
        $score = score_card($letters_a[$i], $letters_b[$i]);
        return $score if $score != 0;
    }

    die "Cannot compare $ha and $hb!";
}
