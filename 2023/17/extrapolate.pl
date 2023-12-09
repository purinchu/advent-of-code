#!/usr/bin/env perl

# AoC 2023 - Puzzle 17
# This problem requires to read in an input file that ultimately
# lists information about an oasis to extrapolate.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use Math::BigInt;
use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);
use POSIX qw(ceil);

# Config
use constant G_DEBUG_EXTRAPOLATION => 0;
use constant G_DEBUG_INPUT => 0;
my $input_name = @ARGV ? $ARGV[0] : 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

my @readings = map { chomp; read_oasis_reading($_) } <$input_fh>;

say j \@readings if G_DEBUG_INPUT;

#my $sum = Math::BigInt->new('0');
#$sum += extrapolate_next(@$_) foreach @readings;
#say "$sum";

say sum map { extrapolate_next(@$_) } @readings;
say sum map { extrapolate_next2(@$_) } @readings;

# Aux subs

sub adjacent_difference(@xs)
{
    return map {
        my $x = $xs[$_];
        my $y = $xs[$_ - 1];
        my $sum = abs($x) + abs($y);
        die "overflow $x $y to " if $sum < (abs($x) | abs($y));
        $x - $y
    } 1..$#xs;
}

sub read_oasis_reading($line)
{
    [map { int } split(' ', $line)];
}

sub extrapolate_next(@xs)
{
    my @vars = (@xs, 0);
    while (@vars > 1) {
        @vars = adjacent_difference(@vars);
    }
    return -$vars[0];
}

sub extrapolate_next2(@xs)
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

        print "    Adding $last to $next to get " if G_DEBUG_EXTRAPOLATION;
        $next += $last;
        say $next if G_DEBUG_EXTRAPOLATION;

        push @$diffs, $next;
        say "    ", j ([reverse @$diffs]) if G_DEBUG_EXTRAPOLATION;
    }

#   say j \@intermediate_stack if G_DEBUG_EXTRAPOLATION;

    return $next;
}
