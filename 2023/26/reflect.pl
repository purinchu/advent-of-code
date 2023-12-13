#!/usr/bin/env perl

# AoC 2023 - Puzzle 26 (Day 12 Part 2)
# This problem requires to read in an input file that ultimately
# lists information about info grids to find where these grids have
# an axis of reflection
# See the Advent of Code website.

use 5.038;
use autodie;

use List::Util qw(sum first zip);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_REFLECTIONS => 0;
use constant G_DEBUG_SMUDGE => 0;

my $input_name = '../25/input';
$" = ', '; # For arrays interpolated into strings

# Globals

my @grids;   # read in data
my @grids_t; # transposition of read in data

# Code (Aux subs below)

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    chomp(my @lines = <$input_fh>);
    load_input(@lines);
};

my $sum = 0;

$sum += 100 * sum map { horiz_reflection($_) } @grids;
$sum +=   1 * sum map { horiz_reflection($_) } @grids_t;

say $sum;

# Aux subs

sub load_input(@lines)
{
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

    if (G_DEBUG_INPUT) {
        say "Read in ", scalar @grids, " arrays";

        my $num_grids = @grids;
        my $num_transposed = @grids_t;
        die "Different grid sizes ($num_grids vs $num_transposed)"
            unless $num_grids == $num_transposed;

        my $count = grep { $_ > 0 } map { horiz_reflection($_) } (@grids, @grids_t);
        # Ensure we found a reflection for every puzzle
        die "Missed some input!" unless $count == @grids;
    }

}

# Returns line number to reflect around if it exists. Assumes there is only 1 match!
sub horiz_reflection($grid_ref)
{
    my $last_row = @$grid_ref - 1;
    my $line_ref = first { check_horiz_reflection_at($grid_ref, $_) } 1..$last_row;
    return $line_ref // 0;
}

# reflects the grid about the horizontal axis just after line $idx, and
# returns true if the grid was a true reflection at that point (including
# "must have exactly one smudge" criteria to this puzzle...)
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

    # extract into component characters
    my @above_chars = split('', join('', @{$grid_ref}[$top..($idx - 1)]));
    my @below_chars = split('', join('', reverse @{$grid_ref}[$idx..$bottom]));

    die "misshappen reflection" unless @above_chars == @below_chars;

    if (G_DEBUG_REFLECTIONS) {
        local $" = '';
        say "Grid reflected about $idx into:";
        say "\t[@above_chars] and";
        say "\t[@below_chars]";
    }

    # for this puzzle, we want to find *exactly one* "smudge" where replacing a
    # # by a . (or vice versa) would make the reflections exactly identical.
    my $smudge_mark = abs(ord('#') - ord('.')); # the sum we should see for a smudge
    my @sums = map { abs(ord($_->[0]) - ord($_->[1])) } zip (\@above_chars, \@below_chars);
    my @smudge_indices = grep { $sums[$_] == $smudge_mark } 0..$#sums;

    if (@smudge_indices == 1) {
        say "\tFound exactly one smudge for the grid reflecting about $idx"
            if G_DEBUG_SMUDGE;
        return 1;
    }

    return 0;
}
