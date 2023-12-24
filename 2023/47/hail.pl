#!/usr/bin/env perl

# AoC 2023 - Puzzle 47
# This problem requires to read in an input file that ultimately
# lists information about falling bricks.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(first all min max reduce);
use Storable qw(dclone);
use Getopt::Long qw(:config auto_version auto_help);

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Command-line opts
my $show_input = 0;

GetOptions(
    "show-input|i"    => \$show_input,
) or die "Error reading command line options";

# Load/dump input

my @hail;
my $g_min = 200000000000000;
my $g_max = 400000000000000;

do {
    $input_name = shift @ARGV // $input_name;
    if ($input_name ne 'input') {
        ($g_min, $g_max) = (7, 27); # different range for sample data
    }

    open my $input_fh, '<', (shift @ARGV // $input_name);
    chomp(my @lines = <$input_fh>);

    if ($show_input) {
        say for @lines;
        exit 0;
    }

    say "Loading ", scalar @lines, " lines of input.";
    load_input(@lines);
};

my $count = 0;
for (my $i1 = 0; $i1 < @hail; $i1++) {
    for (my $i2 = $i1 + 1; $i2 < @hail; $i2++) {
        say "Comparing H$i1 and H$i2";
        $count++ if in_same_window(@hail[$i1, $i2]);
    }
}

say $count;

# Aux subs

# recursive
sub load_input(@lines)
{
    for (@lines) {
        my ($p, $v) = split(' @ ');
        my @pos = split(', ', $p);
        my @vel = split(', ', $v);
        push @hail, [@pos, @vel];
    }
}

sub in_same_window($h1, $h2)
{
    # wikipedia https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line
    # eq for line 1
    my ($x1, $x2) = ($h1->[0], $h1->[0] + 2000 * $h1->[3]);
    my ($y1, $y2) = ($h1->[1], $h1->[1] + 2000 * $h1->[4]);

    # eq for line 2
    my ($x3, $x4) = ($h2->[0], $h2->[0] + 2000 * $h2->[3]);
    my ($y3, $y4) = ($h2->[1], $h2->[1] + 2000 * $h2->[4]);

    my $det = ($x1 - $x2)*($y3 - $y4) - ($y1 - $y2)*($x3-$x4);

    say "Det is 0" if $det == 0;
    return 0 if $det == 0; # will never cross

    my $x_int = (($x1*$y2 - $y1*$x2)*($x3-$x4) - ($x1-$x2)*(($x3*$y4 - $y3*$x4))) / $det;
    my $y_int = (($x1*$y2 - $y1*$x2)*($y3-$y4) - ($y1-$y2)*(($x3*$y4 - $y3*$x4))) / $det;

    if (!($x_int >= $g_min && $x_int <= $g_max &&
        $y_int >= $g_min && $y_int <= $g_max))
    {
        say "Will cross outside test area at $x_int and $y_int";
        return 0;
    }

    if (($h1->[3] > 0 && $x_int < $x1) || ($h1->[3] < 0 && $x_int > $x1)) {
        # crossover in past ?
        say "$x1 -> $x2 cannot make it to X-int $x_int in the future, they already crossed.";
        return 0;
    }

    if (($h2->[3] > 0 && $x_int < $x3) || ($h2->[3] < 0 && $x_int > $x3)) {
        # crossover in past ?
        say "$x3 -> $x4 cannot make it to X-int $x_int in the future, they already crossed.";
        return 0;
    }

    if (($h1->[4] > 0 && $y_int < $y1) || ($h1->[4] < 0 && $y_int > $y1)) {
        # crossover in past ?
        say "$y1 -> $y2 cannot make it to Y-int $y_int in the future, they already crossed.";
        return 0;
    }

    if (($h2->[4] > 0 && $y_int < $y3) || ($h2->[4] < 0 && $y_int > $y3)) {
        # crossover in past ?
        say "$y3 -> $y4 cannot make it to Y-int $y_int in the future, they already crossed.";
        return 0;
    }

    say "Will cross in test area at $x_int and $y_int";

    return 1;
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./tetris.pl [-i] [FILE_NAME]

  -i | --show-input -> Echo input back and exit.

FILE_NAME specifies the brick snapshot to use, and is 'input' if not specified.

=back
