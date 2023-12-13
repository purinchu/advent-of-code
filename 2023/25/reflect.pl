#!/usr/bin/env perl

# AoC 2023 - Puzzle 25 (Day 12 Part 1)
# This problem requires to read in an input file that ultimately
# lists information about info grids to find where these grids have
# an axis of reflection
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use Math::BigInt;
use List::Util qw(min max sum reduce none);
use Mojo::JSON qw(j);
use POSIX qw(ceil);
use Term::ANSIColor qw(:constants);

# Config
use constant G_DEBUG_INPUT => 1;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', (shift @ARGV // $input_name);

chomp(my @lines = <$input_fh>);

my @grids;   # read in data
my @grids_t; # transposition of read in data

my $cur_grid   = [ ];
my @cur_grid_t; # array of lines, transposed from input
my $grid_line  = 0;

my $finalize_grid = sub {
    if (G_DEBUG_INPUT) {
        say "Read grid:";
        say foreach @$cur_grid;

        say "\nGrid transposed:";
        say "\t$_" foreach @cur_grid_t;
        say "";
    }

    push @grids  , $cur_grid;
    push @grids_t, [@cur_grid_t];
    $cur_grid   = [ ];
    @cur_grid_t = ( );
    $grid_line  = 0;
};

say scalar @lines, " lines";
for (@lines) {
    if ($_) {
        push @$cur_grid, $_;
        @cur_grid_t = ('') x length $_ unless $grid_line;

        my @chars = split('');
        while (my ($idx, $c) = each @chars) {
            $cur_grid_t[$idx] .= $c;
        }

        $grid_line++;
    }
    else {
        # grid done, onto new one
        $finalize_grid->();
    }
}

# finalize if hit eof without a terminating blank line first
$finalize_grid->() if $cur_grid->@*;

my $num_grids = @grids;
my $num_transposed = @grids_t;
die "Different grid sizes ($num_grids vs $num_transposed)"
    unless $num_grids == $num_transposed;

if (G_DEBUG_INPUT) {
    say "Read in ", scalar @grids, " arrays";
}

# Aux subs

