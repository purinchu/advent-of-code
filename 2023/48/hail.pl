#!/usr/bin/env perl

# AoC 2023 - Puzzle 48
# This problem requires to read in an input file that ultimately
# lists information about hail.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(first all min max reduce uniqint);
use Storable qw(dclone);
use Getopt::Long qw(:config auto_version auto_help);
use JSON;

# This is a crazy slow library so we don't want to use it for the full brute-force if we
# can avoid it. Turns out, at least for my input, we could avoid it.
use Math::BigRat try => 'GMP';

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Command-line opts
my $show_input = 0;
my $preprocess = 0;
my $use_xy = 0;
my $use_arb_prec = 0;

GetOptions(
    "show-input|i"    => \$show_input,
    "preprocess|p"    => \$preprocess,
    "arb-prec|a"      => \$use_arb_prec,
    "use-xy|x"        => \$use_xy,
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

    open my $input_fh, '<', $input_name;
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

if ($use_arb_prec) {
    # just make everything a big frac
    say "Converting input numbers to arbitrary-precision";
    for my $h (@hail) {
        $h = [map { Math::BigRat->new($_) } $h->@*];
    }
}

# look for intersections in xy-plane first
my @options;

# Uses the method described by FantasticFeline-47 at
# https://www.reddit.com/r/adventofcode/comments/18pptor/2023_day_24_part_2java_is_there_a_trick_for_this/kepufsi/
# and at https://www.reddit.com/r/adventofcode/comments/18pptor/2023_day_24_part_2java_is_there_a_trick_for_this/kepwo12/
# to look for intersections within the rock's own reference frame.  If the
# intersections all happen at the same point, we've chosen the right velocity
# (the velocity to make the hail hit *us* assuming we're the center of the
# universe), and the intersection point will then be the point at which we
# should throw the rock from in the original reference frame.
#
# We can reuse the xy-intersection code from Part 1 if we don't bother with Z immediately.
if ($use_xy) {
    die "Enter both x and y" unless @ARGV >= 2;
    my ($x, $y) = @ARGV[-2..-1];
    # use a rock-centric reference frame to ignore initial position for now
    my $vel = [0, 0, 0, $x, $y, 0];
    my @last_hit;

    Y: for (my $i1 = 0; $i1 < @hail; $i1++) {
        for (my $i2 = $i1 + 1; $i2 < @hail; $i2++) {
            my ($h1, $h2) = @hail[$i1, $i2];
            my $mod1 = [map { Math::BigRat->new($h1->[$_]) - Math::BigRat->new($vel->[$_]) } 0..5];
            my $mod2 = [map { Math::BigRat->new($h2->[$_]) - Math::BigRat->new($vel->[$_]) } 0..5];

            # we permit 0 determinants where because introducing 'z' may
            # resolve the parallel lines into a point
            my @hit = in_same_window($mod1, $mod2, ('nil'));
            next Y unless @hit;
            @last_hit = @hit unless $hit[0] eq 'nil'; # determinants can do this
        }
    }

    say "Last hit for @$vel was @last_hit";
    push @$vel, @last_hit;
    push @options, $vel;
} else {
    # This will relatively quickly find possible x, y values and estimated
    # intercept points for x and y.  For the sample input this is enough to
    # recover z directly below. For the full input the intercept points will
    # have degraded accuracy using hardware integers but the x and y will still
    # be OK. Feed back with --use-xy.
    say "Brute forcing" unless $use_arb_prec;
    say "Brute forcing (with SLOW ARBITRARY PRECISION)" if $use_arb_prec;

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

                    # we permit 0 determinants where because introducing 'z' may
                    # resolve the parallel lines into a point
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
}

say "Velocity vector options so far are:";
for my $opt (@options) {
    say "x, y: $opt->@[3,4]";
    say "x_int, y_int: $opt->@[6,7]";
}

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
            say "Z = $all_z[0]!! (from z velocity $z)";
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

    # note I explored this but never used it because carving out disjoint
    # subsets of a larger set of min-max ranges would be required and that's
    # even more trouble than just brute-forcing every x/y/z
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

    say "min x,y,z: @min";
    say "max x,y,z: @max";
}

sub in_same_window($h1, $h2, $ignore_det=0)
{
    # wikipedia https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line
    # eq for line 1
    my ($x1, $x2) = ($h1->[0], $h1->[0] + 2000 * $h1->[3]);
    my ($y1, $y2) = ($h1->[1], $h1->[1] + 2000 * $h1->[4]);

    # eq for line 2
    my ($x3, $x4) = ($h2->[0], $h2->[0] + 2000 * $h2->[3]);
    my ($y3, $y4) = ($h2->[1], $h2->[1] + 2000 * $h2->[4]);

    # NOTE: In theory the 2000 * modifier above doesn't matter. You'll have two
    # points on a line and the rest plays out as normal.
    # In practice, at least with hardware integer math, spacing out the points
    # by using the larger modifier helps to recover at least x and y.
    my $det = ($x1 - $x2)*($y3 - $y4) - ($y1 - $y2)*($x3-$x4);

    return $ignore_det if $det == 0; # may or will never cross

    my $x_int = (($x1*$y2 - $y1*$x2)*($x3-$x4) - ($x1-$x2)*(($x3*$y4 - $y3*$x4))) / $det;
    my $y_int = (($x1*$y2 - $y1*$x2)*($y3-$y4) - ($y1-$y2)*(($x3*$y4 - $y3*$x4))) / $det;

    if (!($x_int >= $g_min && $x_int <= $g_max &&
        $y_int >= $g_min && $y_int <= $g_max))
    {
        return;
    }

    if (($h1->[3] > 0 && $x_int < $x1) || ($h1->[3] < 0 && $x_int > $x1)) {
        # crossover in past ?
        return;
    }

    if (($h2->[3] > 0 && $x_int < $x3) || ($h2->[3] < 0 && $x_int > $x3)) {
        # crossover in past ?
        return;
    }

    if (($h1->[4] > 0 && $y_int < $y1) || ($h1->[4] < 0 && $y_int > $y1)) {
        # crossover in past ?
        return;
    }

    if (($h2->[4] > 0 && $y_int < $y3) || ($h2->[4] < 0 && $y_int > $y3)) {
        # crossover in past ?
        return;
    }

    return ($x_int, $y_int);
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./hail.pl [-i] [FILE_NAME] -- [x] [y]

  -i | --show-input -> Echo input back and exit.
  -p | --preprocess -> Preprocess velocities and output results.
  -x | --use-xy     -> Directly use x, y velocity to get z (slower func)
                       (use -- before x and y to avoid confusing Getopt)
  -a | --arb-prec   -> Use slow-but-accurate search the whole time.

FILE_NAME specifies the hail info to use, and is 'input' if not specified.

NOTE on --use-xy: Use without --use-xy first to get the x and v velocity, you'll
see a message like
    "x, y: -3, 1"

In this case "-3" and "1" are the values to use for x and y velocity
respectively. Do *NOT* use the "x_int" or "y_int" output.

If you feed this back into the program with --use-xy, it will calculate the matching
z positions using a **much slower** arbitrary-precision math library. If successful
it will output the final sum of x, y, z starting *positions* (not velocity).

=back
