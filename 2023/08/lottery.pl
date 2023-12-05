#!/usr/bin/env perl

# AoC 2023 - Puzzle 08
# This problem requires to read in an input file one line at a time holding scratchers
# Each line has a card ID, a list of winning numbers, and a list of numbers on the card
# Cards with numbers that are winning numbers earn copies of the succeeding
# cards to process.
# Originals and copies of cards are all processed until no more additional
# cards are earned.
# The total number of cards processed is the puzzle's answer.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum);
use Mojo::JSON qw(j);

# Config
my $input_name = @ARGV ? $ARGV[0] : '../07/input';
my $debug = 0;
$" = ', '; # For arrays interpolated into strings

# Globals

# Each game holds a listref to an array of [@$winners, @$numbers]
my @games;

# Cards to process. Each entry is a card ID (starts at 1)
my @queue;

# Number of matching numbers for the card ID (starts at 1)
my %card_value;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);
    read_game($line);
}

# Load table of card scores
%card_value = map { ( $_ + 1, num_winners($games[$_]) ) } 0..$#games;

say "card values: ", j \%card_value if $debug;

my @cards = (1) x @games;

unshift @cards, 0; # placeholder value to make id num == array idx

for (my $i = 1; $i <= @games; $i++) {
    say "card $i" if $debug;
    my $add_amount = $card_value{$i};
    say "  adding $add_amount cards below $i" if $debug;
    for (my $j = $i + 1; $j < $i + 1 + $add_amount && $j <= @games; $j++) {
        $cards[$j] += $cards[$i];
        say "  added $cards[$i] to card $j" if $debug;
    }
}

say "card counts: ", j \@cards if $debug;
say "card total: ", sum @cards;

# Aux subs

sub read_game($line)
{
    my ($id, $nums) = split(/: */, $line);
    my ($win_text, $pick_text) = split(/ *\| */, $nums);
    my @winners = split(' ', $win_text);
    my @picked  = split(' ', $pick_text);

    push @games, [\@winners, \@picked];
}

sub num_winners($game)
{
    my %scores;
    my @winners = $game->[0]->@*;
    my @picked  = $game->[1]->@*;

    @scores{@winners} = (1) x @winners;
    my $count = grep { exists $scores{$_} } @picked;
    return $count;
}
