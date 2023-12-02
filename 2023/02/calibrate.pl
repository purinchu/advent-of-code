#!/usr/bin/env perl

# AoC 2023 - Puzzle 02
# This problem requires to read in an input file one line at a time
# Each line contains one or more digits and other extraneous info
#   For puzzle 02, the digit can be expressed as [0-9] or as a written word (zero - nine)
# Each line produces a 2-digit calibration value, the first and last digit in that order
# The sum of all these lines is the puzzle solution.
# The input is unchanged from Puzzle 01

use 5.036;
use autodie;

# Config
my $input_name = '../01/input';
my $debug = 0;

# Globals
my $sum = 0;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);
    $line = convert_words_to_digits($orig_line);

    my ($first) = $line =~ /^[^0-9]*([0-9])/;
    my ($second) = (scalar reverse $line) =~ /^[^0-9]*([0-9])/;

    my $res = $first . $second;
    $sum += int $res;

    say "$orig_line -> $line -> $res" if $debug;
}

say "Sum is $sum";

# Aux subs

sub convert_words_to_digits($line)
{
    my %substs = (
        zero  => 0,
        one   => 1,
        two   => 2,
        three => 3,
        four  => 4,
        five  => 5,
        six   => 6,
        seven => 7,
        eight => 8,
        nine  => 9,
    );

    my $words = join('|', keys %substs); # make a regexp alteration

    # We want to address only a first and a last match.  Going only
    # left-to-right risks removing letters that would cause a valid word to
    # match had we started from the right.
    # Test case from input: 8hkrb3oneightj (one/eight overlap, eight should win)
    my $first_res = $line =~ s/($words)/$substs{$1}/re;

    $words = reverse $words;
    my $rline = reverse $first_res;
    my $second_res = $rline =~ s/($words)/$substs{reverse $1}/re;

    return reverse $second_res;
}
