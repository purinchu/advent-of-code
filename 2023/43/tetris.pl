#!/usr/bin/env perl

# AoC 2023 - Puzzle 43
# This problem requires to read in an input file that ultimately
# lists information about falling bricks.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(first all any min max reduce);
use Data::Printer;
use JSON;
use Getopt::Long qw(:config auto_version auto_help);

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

use constant G_GRID_SIZE => 20;

# Command-line opts
my $show_input = 0;
my $show_grid_dump = 0;

GetOptions(
    "show-input|i"    => \$show_input,
    "debug-grid"      => \$show_grid_dump,
) or die "Error reading command line options";

# Bricks are stored as 2 different 2-D grids to help me visualize better.
# Access as $zx_grid[$z]->[$x]
my @zx_grid = map { [(0) x G_GRID_SIZE] } 1..G_GRID_SIZE;
my @zy_grid = map { [(0) x G_GRID_SIZE] } 1..G_GRID_SIZE;

my @min_grid = (100, 100, 100);
my @max_grid = (0, 0, 0);

my @bricks;
my $brick_id = 0; # disambiguate bricks

# Load/dump input

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    chomp(my @lines = <$input_fh>);

    if ($show_input) {
        say for @lines;
        exit 0;
    }

    load_input(@lines);
};

if ($show_grid_dump) {
    p @zx_grid;
    p @zy_grid;

    exit 0;
}

# Code (Aux subs below)

# Aux subs

sub load_input(@lines)
{
    for (@lines) {
        my ($l, $r) = split('~');
        my ($x1, $y1, $z1) = split(',', $l);
        my ($x2, $y2, $z2) = split(',', $r);

        build_brick_x($y1, $z1, $x1, $x2) if $x1 != $x2;
        build_brick_y($x1, $z1, $y1, $y2) if $y1 != $y2;
        build_brick_z($x1, $y1, $z1, $z2) if $z1 != $z2;

        $min_grid[0] = min($min_grid[0], $x1, $x2);
        $min_grid[1] = min($min_grid[1], $y1, $y2);
        $min_grid[2] = min($min_grid[2], $z1, $z2);
        $max_grid[0] = max($max_grid[0], $x1, $x2);
        $max_grid[1] = max($max_grid[1], $y1, $y2);
        $max_grid[2] = max($max_grid[2], $z1, $z2);
    }
}

sub build_brick_x($y, $z, $x1, $x2)
{
    ($x1, $x2) = ($x2, $x1) if $x1 > $x2;
    push @bricks, {
        x => [$x1, $x2],
        y => [$y, $y],
        z => [$z, $z],
        ori => 'x',
    };

    for my $x ($x1..$x2) {
        $zx_grid[$z]->[$x] = $brick_id;
        $zy_grid[$z]->[$y] = $brick_id;
        $brick_id++;
    }
}

sub build_brick_y($x, $z, $y1, $y2)
{
    ($y1, $y2) = ($y2, $y1) if $y1 > $y2;
    push @bricks, {
        x => [$x, $x],
        y => [$y1, $y2],
        z => [$z, $z],
        ori => 'y',
    };

    for my $y ($y1..$y2) {
        $zx_grid[$z]->[$x] = $brick_id;
        $zy_grid[$z]->[$y] = $brick_id;
        $brick_id++;
    }
}

sub build_brick_z($x, $y, $z1, $z2)
{
    ($z1, $z2) = ($z2, $z1) if $z1 > $z2;
    push @bricks, {
        x => [$x, $x],
        y => [$y, $y],
        z => [$z1, $z2],
        ori => 'z',
    };

    for my $z ($z1..$z2) {
        $zx_grid[$z]->[$x] = $brick_id;
        $zy_grid[$z]->[$y] = $brick_id;
        $brick_id++;
    }
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./tetris.pl [-i] [FILE_NAME]

  -i | --show-input -> Echo input back and exit.
       --debug-grid -> Dump grid data struct.

FILE_NAME specifies the brick snapshot to use, and is 'input' if not specified.

=back
