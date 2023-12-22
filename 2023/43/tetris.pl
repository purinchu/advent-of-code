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
my $show_grid = 0;
my $show_grid_dump = 0;

GetOptions(
    "show-input|i"    => \$show_input,
    "show-grid|g"     => \$show_grid,
    "debug-grid"      => \$show_grid_dump,
) or die "Error reading command line options";

# Bricks are stored as 2 different 2-D grids to help me visualize better.
# Access as $zx_grid[$z]->[$x]
my @zx_grid = map { [('.') x G_GRID_SIZE] } 1..G_GRID_SIZE;
my @zy_grid = map { [('.') x G_GRID_SIZE] } 1..G_GRID_SIZE;

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

if ($show_grid) {
    show_grid();
}

settle_bricks();

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
        id => chr(ord('A') + $brick_id),
        idx => $brick_id,
        x => [$x1, $x2],
        y => [$y, $y],
        z => [$z, $z],
        ori => 'x',
    };

    for my $x ($x1..$x2) {
        $zx_grid[$z]->[$x] = $brick_id;
        $zy_grid[$z]->[$y] = $brick_id;
    }

    $brick_id++;
}

sub build_brick_y($x, $z, $y1, $y2)
{
    ($y1, $y2) = ($y2, $y1) if $y1 > $y2;

    push @bricks, {
        id => chr(ord('A') + $brick_id),
        idx => $brick_id,
        x => [$x, $x],
        y => [$y1, $y2],
        z => [$z, $z],
        ori => 'y',
    };

    for my $y ($y1..$y2) {
        $zx_grid[$z]->[$x] = $brick_id;
        $zy_grid[$z]->[$y] = $brick_id;
    }

    $brick_id++;
}

sub build_brick_z($x, $y, $z1, $z2)
{
    ($z1, $z2) = ($z2, $z1) if $z1 > $z2;

    push @bricks, {
        id => chr(ord('A') + $brick_id),
        idx => $brick_id,
        x => [$x, $x],
        y => [$y, $y],
        z => [$z1, $z2],
        ori => 'z',
    };

    for my $z ($z1..$z2) {
        $zx_grid[$z]->[$x] = $brick_id;
        $zy_grid[$z]->[$y] = $brick_id;
    }

    $brick_id++;
}

sub settle_bricks()
{
    my @falling_bricks = sort { $a->{z}->[0] <=> $b->{z}->[0] } @bricks;
    for my $b (@falling_bricks) {
        while (!is_supported($b->{idx})) {
            my ($x1, $y1, $z1) = map { $_->[0] } $b->@{qw/x y z/};
            my ($x2, $y2, $z2) = map { $_->[1] } $b->@{qw/x y z/};
            my ($dx, $dy, $dz) = map { $_ eq $b->{ori} } qw/x y z/;

            say "Dropping brick $b->{id}";

            # move block down by 1
            for my $z ($z1..$z2) {
                for my $x ($x1..$x2) {
                    $zx_grid[$z - 1]->[$x] = $zx_grid[$z]->[$x];
                    $zx_grid[$z]->[$x] = '.';
                }

                for my $y ($y1..$y2) {
                    $zy_grid[$z - 1]->[$y] = $zy_grid[$z]->[$y];
                    $zy_grid[$z]->[$y] = '.';
                }
            }

            $b->{z}->[0]--;
            $b->{z}->[1]--;

            show_grid();
        }

        $b->{falling} = 0;
    }
}

sub is_supported($idx)
{
    # a brick is supported if even one brick has a brick or ground below it.
    my $brick = $bricks[$idx];
    my $ori = $brick->{ori};
    my ($x1, $y1, $z1) = map { $_->[0] } $brick->@{qw/x y z/};
    my ($x2, $y2, $z2) = map { $_->[1] } $brick->@{qw/x y z/};

    return 1 if $z1 == 1; # on ground?

    # must have something below in both zx and zy planes, and that
    # something must have stopped falling itself.
    my @bricks_below =
                map { $bricks[$_] }
                grep { $_ ne '.' } $zx_grid[$z1-1]->@[$x1..$x2];
    my $zx_ok = any { !($_->{falling} // 1) } @bricks_below;

    @bricks_below =
                map { $bricks[$_] }
                grep { $_ ne '.' } $zy_grid[$z1-1]->@[$y1..$y2];
    my $zy_ok = any { !($_->{falling} // 1) } @bricks_below;

    return ($zx_ok and $zy_ok);
}

sub show_grid
{
    # grid width, 3 for col labels, 2 for 'z' label
    my $xz_width = ($max_grid[0] - $min_grid[0] + 1) + 3 + 2;
    my $yz_width = ($max_grid[1] - $min_grid[1] + 1) + 3 + 2;

    # Two more rows on top but those will be implicit
    my $z_height = ($max_grid[2] - $min_grid[2] + 1);
    my $x_pos = int(($xz_width - 4) / 2);
    print "\e[${x_pos}G", "x";

    my $y_pos = int($xz_width + 1 + ($yz_width - 4) / 2);
    print "\e[${y_pos}G", "y";
    print "\n";

    for my $ch (0..($max_grid[0])) {
        print "". ($ch % 10);
    }

    $y_pos = $xz_width + 2;
    print "\e[${y_pos}G";
    for my $ch (0..($max_grid[1])) {
        print "". ($ch % 10);
    }

    print "\n";

    for (my $row = $max_grid[2]; $row > 0; $row--) {
        for (my $x = 0; $x <= $max_grid[0]; $x++) {
            my $b = $zx_grid[$row]->[$x];
            print $b if $b eq '.';
            print chr (ord('A') + $b) unless $b eq '.';
        }

        print " ", ($row % 10);

        print " z" if $row == int(($max_grid[2] + 1) / 2);

        print "\e[${y_pos}G";
        for (my $y = 0; $y <= $max_grid[1]; $y++) {
            my $b = $zy_grid[$row]->[$y];
            print $b if $b eq '.';
            print chr (ord('A') + $b) unless $b eq '.';
        }

        print " ", ($row % 10);

        print " z" if $row == int(($max_grid[2] + 1) / 2);

        print "\n";
    }

    print (('-') x ($max_grid[0] - $min_grid[0] + 1));
    print ' 0';

    print "\e[${y_pos}G";
    print (('-') x ($max_grid[1] - $min_grid[1] + 1));
    print ' 0';

    print "\n";
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./tetris.pl [-i] [FILE_NAME]

  -i | --show-input -> Echo input back and exit.
  -g | --show-grid  -> Show puzzle grid after setup, and keep running.
       --debug-grid -> Dump grid data struct.

FILE_NAME specifies the brick snapshot to use, and is 'input' if not specified.

=back
