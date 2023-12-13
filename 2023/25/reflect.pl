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
use List::Util qw(min max sum reduce none first);
use Mojo::JSON qw(j);
use POSIX qw(ceil);
use Term::ANSIColor qw(:constants);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_REFLECTIONS => 0;

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

my $sum = 0;
for (my $i = 0; $i < scalar @grids; $i++) {
    my $horiz_match =
        first { check_horiz_reflection_at($grids[$i], $_) }
        find_horiz_reflection($grids[$i]);

    if ($horiz_match) {
        $sum += 100 * $horiz_match;
        next;
    }

    my $vert_match =
        first { check_horiz_reflection_at($grids_t[$i], $_) }
        find_horiz_reflection($grids_t[$i]);

    if ($vert_match) {
        $sum += $vert_match;
        next;
    }

    # if we get here something is wrong
    die "No reflection found in grid $i!";
}

say $sum;

# Aux subs

sub find_horiz_reflection($grid_ref)
{
    my @lines = $grid_ref->@*;
    my @idx_candidates;
    my $line_idx = 1;
    my $last_line = shift @lines;

    while(my $line = shift @lines) {
        if ($line eq $last_line) {
            push @idx_candidates, $line_idx;
        }

        $last_line = $line;
        $line_idx++;
    }

    return @idx_candidates;
}

# reflects the grid about the horizontal axis just after line $idx, and
# returns true if the grid was a true reflection at that point
sub check_horiz_reflection_at($grid_ref, $idx)
{
    my $num_lines = @$grid_ref;
    my $top = 0;
    my $bottom = $num_lines - 1;

    if (($num_lines - $idx) == $idx) {
        # perfect split, don't change lines
    } elsif (($num_lines - $idx) < $idx) {
        # near bottom of grid, remove lines at top
        $top = $num_lines - 2 * ($num_lines - $idx);
    } else {
        # near top of grid, remove lines at bottom
        $bottom = 2 * $idx - 1;
    }

    my $above_str = join('', @{$grid_ref}[$top..($idx - 1)]);
    my $below_str = join('', reverse @{$grid_ref}[$idx..$bottom]);

    die "misshappen reflection"
        unless length($above_str) == length ($below_str);

    if (G_DEBUG_REFLECTIONS) {
        say "Grid reflected about $idx into:";
        say "\t[$above_str] and";
        say "\t[$below_str]";
        say "Which are ", ($above_str eq $below_str) ? 'equal' : 'not equal';
    }

    return $above_str eq $below_str;
}
