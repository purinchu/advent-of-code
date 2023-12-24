#!/usr/bin/env perl

# AoC 2023 - Puzzle 48
# This problem requires to read in an input file that ultimately
# lists information about falling bricks.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(first all min max reduce uniqint);
use Storable qw(dclone);
use Getopt::Long qw(:config auto_version auto_help);
use DDP;

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Command-line opts
my $show_input = 0;
my $preprocess = 0;

GetOptions(
    "show-input|i"    => \$show_input,
    "preprocess|p"    => \$preprocess,
) or die "Error reading command line options";

# Load/dump input

my @hail;
my $g_min = 200000000000000;
my $g_max = 400000000000000;

my @min = ($g_max) x 3;
my @max = (-$g_max) x 3;

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

if ($preprocess) {
    for (my $i1 = 0; $i1 < @hail; $i1++) {
        for (my $i2 = $i1 + 1; $i2 < @hail; $i2++) {
            preprocess_velocity(@hail[$i1, $i2]);
        }
    }

    exit 0;
}

# look for intersections in xy-plane first
my @options;
say "Brute forcing";

my $stationary = [(0) x 6]; # no motion, at origin
for (my $x = -500; $x < 500; $x++) {
    say "x = $x" if ($x % 25 == 0);
    Y: for (my $y = -500; $y < 500; $y++) {
        # use a rock-centric reference frame to ignore initial position for now
        my $vel = [0, 0, 0, $x, $y, 0];
        my @last_hit;

        for (my $i1 = 0; $i1 < @hail; $i1++) {
            for (my $i2 = $i1 + 1; $i2 < @hail; $i2++) {
                my ($h1, $h2) = @hail[$i1, $i2];
                my $mod1 = [map { $h1->[$_] - $vel->[$_] } 0..5];
                my $mod2 = [map { $h2->[$_] - $vel->[$_] } 0..5];

                my @hit = in_same_window($mod1, $mod2, ('nil'));
                next Y unless @hit;
                @last_hit = @hit unless $hit[0] eq 'nil'; # determinants can do this
            }
        }

        say "Last hit for @$vel was @last_hit";
        push @$vel, @last_hit;
        push @options, $vel;
    }
}

say "Velocity vector options so far are:";
p @options;

# now look for Z coords
for my $opt (@options) {

    say "Checking @$opt";

    # we don't know the adjusted z yet
    my ($x, $y) = @$opt[3, 4];
    my ($hit_x, $hit_y) = @$opt[6, 7];

    say "\tthis hit x at $hit_x and y at $hit_y";

    for my $z (0..300) {
        my @all_z = uniqint map { calc_z ($opt, $z, $_) } @hail;
        if (1 == @all_z) {
            say "Z = $all_z[0]!!";
            say "Try $hit_x, $hit_y, $all_z[0]";
            say "This sum is ", ($hit_x + $hit_y + $all_z[0]);
            exit 0;
        }
    }
}

say "Couldn't find working Z component!";

# Aux subs

sub calc_z($opt, $z, $h)
{
    my ($x, $y) = @$opt[3, 4];
    my ($hit_x, $hit_y) = @$opt[6, 7];

    my $adj_vel_x = $h->[3] - $x;
    my $adj_vel_y = $h->[4] - $y;
    my $adj_vel_z = $h->[5] - $z;
    my @adj_vel = ($adj_vel_x, $adj_vel_y, $adj_vel_z);

    die "not moving" unless $adj_vel_x != 0 or $adj_vel_y != 0;

    my $t;

    $t = ($hit_x - $h->[0]) / ($adj_vel_x) if $adj_vel_y == 0;
    $t = ($hit_y - $h->[1]) / ($adj_vel_y) if not defined $t;

    my $hit_z = $h->[2] + $t * $adj_vel_z;
    return $hit_z;
}

sub preprocess_velocity($h1, $h2)
{
    # https://www.reddit.com/r/adventofcode/comments/18pptor/2023_day_24_part_2java_is_there_a_trick_for_this/kepxbew/
    # there's always a trick with these puzzles... nothing ever just is as it is
    if ($h1->[0] > $h2->[0] && $h1->[3] > $h2->[3]) {
        say "$h1->[3] to $h2->[3] range is impossible";
    }
}

# recursive
sub load_input(@lines)
{
    for (@lines) {
        my ($p, $v) = split(' @ ');
        my @pos = split(', ', $p);
        my @vel = split(', ', $v);
        push @hail, [@pos, @vel];

        $min[$_] = min($min[$_], $vel[$_]) for 0..2;
        $max[$_] = max($max[$_], $vel[$_]) for 0..2;
    }

    p @min;
    p @max;
}

sub in_same_window($h1, $h2, $ignore_det=0, $dbg=0)
{
    # wikipedia https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line
    # eq for line 1
    my ($x1, $x2) = ($h1->[0], $h1->[0] + 2000 * $h1->[3]);
    my ($y1, $y2) = ($h1->[1], $h1->[1] + 2000 * $h1->[4]);

    # eq for line 2
    my ($x3, $x4) = ($h2->[0], $h2->[0] + 2000 * $h2->[3]);
    my ($y3, $y4) = ($h2->[1], $h2->[1] + 2000 * $h2->[4]);

    my $det = ($x1 - $x2)*($y3 - $y4) - ($y1 - $y2)*($x3-$x4);

    say "DET" if $det == 0 and $dbg;
    return $ignore_det if $det == 0; # may or will never cross

    my $x_int = (($x1*$y2 - $y1*$x2)*($x3-$x4) - ($x1-$x2)*(($x3*$y4 - $y3*$x4))) / $det;
    my $y_int = (($x1*$y2 - $y1*$x2)*($y3-$y4) - ($y1-$y2)*(($x3*$y4 - $y3*$x4))) / $det;

    if (!($x_int >= $g_min && $x_int <= $g_max &&
        $y_int >= $g_min && $y_int <= $g_max))
    {
        say "No cross in window" if $dbg;
        return;
    }

    if (($h1->[3] > 0 && $x_int < $x1) || ($h1->[3] < 0 && $x_int > $x1)) {
        # crossover in past ?
        say "x1 crossover in past" if $dbg;
        return;
    }

    if (($h2->[3] > 0 && $x_int < $x3) || ($h2->[3] < 0 && $x_int > $x3)) {
        # crossover in past ?
        say "x2 crossover in past" if $dbg;
        return;
    }

    if (($h1->[4] > 0 && $y_int < $y1) || ($h1->[4] < 0 && $y_int > $y1)) {
        # crossover in past ?
        say "y1 crossover in past" if $dbg;
        return;
    }

    if (($h2->[4] > 0 && $y_int < $y3) || ($h2->[4] < 0 && $y_int > $y3)) {
        # crossover in past ?
        say "y2 crossover in past" if $dbg;
        return;
    }

    return ($x_int, $y_int);
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./hail.pl [-i] [FILE_NAME]

  -i | --show-input -> Echo input back and exit.
  -p | --preprocess -> Preprocess velocities and output results.

FILE_NAME specifies the brick snapshot to use, and is 'input' if not specified.

=back
