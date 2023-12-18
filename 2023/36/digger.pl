#!/usr/bin/env perl

# AoC 2023 - Puzzle 36
# This problem requires to read in an input file that ultimately
# lists information about a maze of trenches to dig.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use Math::BigInt;
use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);

# Config
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', (shift @ARGV // '../35/input');
chomp (my @insts = <$input_fh>);

say shoelace(@insts);

# Aux subs

sub shoelace(@insts)
{
    my $x = 0, my $y = 0;
    # dir 0 1 2 3 => R D L U
    my @xoff = (1, 0, -1, 0);
    my @yoff = (0, 1, 0, -1);

    my $sum = 0; # should be 64-bit on modern Perl
    my $perimeter = 0;

    for (@insts) {
        my ($dist, $dir) = /\(#([0-9a-f]{5})([0-9a-f])\)$/;
        $dist = hex $dist;
        $dir  = int $dir;
        print "$dir for $dist m ";

        my $x2 = $x + $dist * $xoff[$dir];
        my $y2 = $y + $dist * $yoff[$dir];
        say "($x, $y) -> ($x2, $y2)";

        $perimeter += $dist;
        $sum += (($x * $y2) - ($x2 * $y));
        ($x, $y) = ($x2, $y2);
    }

    return ($sum + $perimeter) / 2 + 1;
}
