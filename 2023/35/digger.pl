#!/usr/bin/env perl

# AoC 2023 - Puzzle 35
# This problem requires to read in an input file that ultimately
# lists information about a maze of trenches to dig.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use Math::BigInt;
use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);
use POSIX qw(ceil);
use Term::ANSIColor qw(:constants);

# Config
use constant G_DEBUG_INTERMEDIATE => 0;
use constant G_DEBUG_FILL => 0;
use constant G_DEBUG_FINAL => 0;
use constant G_DEBUG_INPUT => 0;
my $input_name = @ARGV ? $ARGV[0] : 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', $input_name;
chomp (my @insts = <$input_fh>);

if (G_DEBUG_INPUT) {
    say foreach @insts;
}

my %extents = find_extent(@insts);

my $map = generate_map(\%extents, @insts);

if (G_DEBUG_INTERMEDIATE) {
    for (my $j = 0; $j < $extents{h}; $j++) {
        say substr($map, $j * $extents{w}, $extents{w});
    }
}

$map = flood_fill($map, $extents{w}, $extents{h},
    1 - $extents{minx}, 1 - $extents{miny}, '#');

if (G_DEBUG_FILL) {
    for (my $j = 0; $j < $extents{h}; $j++) {
        say substr($map, $j * $extents{w}, $extents{w});
    }
}

my $count = grep { $_ eq '#' } split('', $map);
say $count;

# Aux subs

sub find_extent (@insts)
{
    my $x = 0, my $y = 0;
    my $maxx = -10000, my $maxy = -10000;
    my $minx =  10000, my $miny =  10000;
    my %actions = (
        R => sub ($i) { $x += $i; },
        D => sub ($i) { $y += $i; },
        L => sub ($i) { $x -= $i; },
        U => sub ($i) { $y -= $i; },
    );

    for (@insts) {
        my ($act, $amount) = /^(.) (\d+)/;
        $actions{$act}->($amount);

        $maxx = max ($maxx, $x);
        $minx = min ($minx, $x);
        $maxy = max ($maxy, $y);
        $miny = min ($miny, $y);
    }

    return (
        maxx => $maxx,
        maxy => $maxy,
        minx => $minx,
        miny => $miny,
        w    => $maxx - $minx + 1,
        h    => $maxy - $miny + 1,
    );
}

sub generate_map($extents, @insts)
{
    my $w = +$extents->{w};
    my $h = +$extents->{h};
    my $pos = (-$extents->{miny}) * $w - $extents->{minx};

    my $base = '.' x ($w * $h);

    my %actions = (
        R => sub ($i) {
            substr ($base, $pos + 1, $i) = ('#' x $i);
            $pos += $i;
        },
        D => sub ($i) {
            while ($i--) {
                $pos += $w;
                substr ($base, $pos, 1) = '#';
            }
        },
        L => sub ($i) {
            $pos -= $i;
            substr ($base, $pos, $i) = ('#' x $i);
        },
        U => sub ($i) {
            while ($i--) {
                $pos -= $w;
                substr ($base, $pos, 1) = '#';
            }
        },
    );

    substr ($base, $pos, 1) = '#'; # make first block
    for (@insts) {
        my ($act, $amount) = /^(.) (\d+)/;
        $actions{$act}->($amount); # update x,y
    }

    return $base;
}

# Flood fills the region starting from x,y with val, but blocked by piping
sub flood_fill($maze, $stride, $rows, $x, $y, $val)
{
    # can't got through these
    my $block_cells = "#";

    my @queue;

    push @queue, [$x, $y];
    while (@queue) {
        my ($x, $y) = @{shift @queue};
        if($val ne substr($maze, $y * $stride + $x, 1, $val)) {
            for my ($dx, $dy) (qw/-1 0   1 0   0 -1   0 1/) {
                my $newx = $x + $dx;
                my $newy = $y + $dy;

                next if ($newx < 0 || $newy < 0);
                next if $newx >= $stride;
                next if $newy >= $rows;

                my $existing = substr($maze, $newy * $stride + $newx, 1);
                next if index($block_cells, $existing) != -1;
                push @queue, [$newx, $newy];
            }
        }
    }

    return $maze;
}
