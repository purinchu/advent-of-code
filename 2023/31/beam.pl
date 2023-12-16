#!/usr/bin/env perl

# AoC 2023 - Puzzle 31 (Day 16 Part 1)
# This problem requires to read in an input file that ultimately
# lists information about info grids to find where these grids have
# beams cross over them
# See the Advent of Code website.

use 5.038;
use autodie;

use List::Util qw(sum first zip);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_OUTPUT => 1;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Globals

my @grids;
my @tiles;

# Code (Aux subs below)

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    local $/ = ""; # go into 'paragraph mode'
    chomp(my @paragraphs = <$input_fh>);
    load_input(@paragraphs);
};

if (G_DEBUG_INPUT) {
    say join('', $_->@*) foreach @grids;
    say "";
    say join('', $_->@*) foreach @tiles;
    say "";
}

# Handle beams
my @beams;

push @beams, ['E', 0, 0, 4096]; # dir, x, y, ttl

my $h = @grids;
my $w = $grids[0]->@*;

my %newdir = (
    '/E' => 'N',
    '/W' => 'S',
    '/N' => 'E',
    '/S' => 'W',
    '\E' => 'S',
    '\W' => 'N',
    '\N' => 'W',
    '\S' => 'E',
);

my %visited_tiles;
my $visit = sub ($x, $y, $dir) {
    $tiles[$y]->[$x] = '#';
    $visited_tiles{"$x/$y/$dir"} = 1;
    say "visited $x, $y heading $dir";
};

my $move = sub ($x, $y, $dir) {
    return ($x + 1, $y  ) if $dir eq 'E';
    return ($x - 1, $y  ) if $dir eq 'W';
    return ($x  , $y + 1) if $dir eq 'S';
    return ($x  , $y - 1) if $dir eq 'N';
    die "unhandled dir $dir";
};

system ('tput', 'smcup');
$SIG{INT} = sub { system('tput', 'rmcup'); exit 1; };

while (@beams && @beams < 2048) {
    my ($dir, $x, $y, $ttl) = (shift @beams)->@*;

    my $horiz = ($dir eq 'E' or $dir eq 'W');
    my $vert = !$horiz;

    # clear screen and reset cursor
    print "\e[H\e[2J";

    $visit->($x, $y, $dir);
    ($x, $y) = $move->($x, $y, $dir);
    say "-moved to $x, $y heading $dir";

#   draw_screen_overlayed();
#   sleep 1;

    my $tile = $grids[$y]->[$x];

    if ($x >= 0 && $y >= 0 && $x < $w && $y < $h && $ttl) {
        --$ttl;

        # stop if we've run through this loop before
        if (exists $visited_tiles{"$x/$y/$dir"}) {
            say "stopping early to skip visited tile $x, $y heading $dir";
            next;
        }

        my @new_beams;
        if ($tile eq '.' || $tile eq '-' && $horiz || $tile eq '|' && $vert) {
            push @new_beams, [$dir, $x, $y, $ttl];
        }
        elsif ($tile eq '|' && $horiz) {
            push @new_beams, ['N', $x, $y, $ttl];
            push @new_beams, ['S', $x, $y, $ttl];
        }
        elsif ($tile eq '-' && $vert) {
            push @new_beams, ['E', $x, $y, $ttl];
            push @new_beams, ['W', $x, $y, $ttl];
        }
        else {
            push @new_beams, [$newdir{"$tile$dir"}, $x, $y, $ttl];
        }

        push @beams, @new_beams;
    }

    if (!$ttl && !exists $visited_tiles{"$x/$y/$dir"}) {
        warn "Killed beam about to visit new tile at $x, $y heading $dir!";
    }
}

system ('tput', 'rmcup');

if (G_DEBUG_OUTPUT) {
    say join('', $_->@*) foreach @grids;
    say "";
    say join('', $_->@*) foreach @tiles;
    say "";
}

say scalar grep { $_ eq '#' } map { ($_->@*)} @tiles;

say "Likely died due to lotsa beams" if @beams >= 2048;

# Aux subs

sub load_input(@paras)
{
    # should be only one para for this exercise
    for (@paras) {
        s/\n*$//;
        # break into lines then chars
        @grids = map { [split('')] } split("\n");
    }

    @tiles = map { [('.') x (@$_)] } @grids;
}

sub draw_screen_overlayed
{
    print "\e[31m";
    say join('', $_->@*) foreach @grids;
    say "";

    # save cursor position then back up over lines we just draw, and reset
    # color
    my $up = $h + 1;
    print ("\e[7\e[${up}F\e[0m");

    for my $y (0..$h) {
        for my $x (0..$w) {
            my $c = $tiles[$y]->[$x] // '';
            if ($c eq '#') {
                print $tiles[$y]->[$x];
            } else {
                print "\e[1C"; # skip column
            }
            select()->flush();
        }
        print "\e[1E"; # down 1, back to start
    }

    # restore cursor position
    print ("\e[8");
}
