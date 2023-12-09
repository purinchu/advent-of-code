#!/usr/bin/env perl

# AoC 2023 - Puzzle 17
# This problem requires to read in an input file that ultimately
# lists information about an oasis to extrapolate.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);
use POSIX qw(ceil);

# Config
use constant G_DEBUG_EXTRAPOLATION => 0;
use constant G_DEBUG_INPUT => 1;
my $input_name = @ARGV ? $ARGV[0] : 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

my @readings = map { chomp; read_oasis_reading($_) } <$input_fh>;

say j \@readings if G_DEBUG_INPUT;

say sum map { extrapolate_next(@$_) } @readings;

# Aux subs

sub adjacent_difference(@xs)
{
    return map { $xs[$_] - $xs[$_ - 1] } 1..$#xs;
}

sub read_oasis_reading($line)
{
    [map { int } split(' ', $line)];
}

sub extrapolate_next(@xs)
{
    my @intermediate_stack;
    my @cur = @xs;
    my $sum;

    push @intermediate_stack, \@xs;

    do {
        my @diffs = adjacent_difference(@cur);
        $sum = sum (@diffs);
        push @intermediate_stack, \@diffs;
        @cur = @diffs;
    } while ($sum);

    say j \@intermediate_stack if G_DEBUG_EXTRAPOLATION;

    # now extrapolate

    my $next = 0;
    for my $diffs (reverse @intermediate_stack) {
        my $last = $diffs->[-1];
        $next += $last;
        push @$diffs, $next;
    }

    say j \@intermediate_stack if G_DEBUG_EXTRAPOLATION;

    return $next;
}
