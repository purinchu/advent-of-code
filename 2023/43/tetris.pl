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
my @zx_grid = map { [(0) x G_GRID_SIZE] } 1..G_GRID_SIZE;
my @zy_grid = map { [(0) x G_GRID_SIZE] } 1..G_GRID_SIZE;

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
    return;
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./tetris.pl [-i] [FILE_NAME]

  -i | --show-input -> Echo input back and exit.
       --debug-grid -> Dump grid data struct.

FILE_NAME specifies the brick snapshot to use, and is 'input' if not specified.

=back
