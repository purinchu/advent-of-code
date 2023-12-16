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
use constant G_DEBUG_ANIMATE => 0;
use constant G_DEBUG_OUTPUT => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Globals

my @grids; # Mirror grid
my @tiles; # Portions of grid energized
my @beams; # Beams of light in motion
my %visited_tiles; # Detects cycles of beams
my ($h, $w); # Grid dimension

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
push @beams, ['E', 0, 0]; # dir, x, y, ttl

my $move = sub ($x, $y, $dir) {
    return ($x + 1, $y  ) if $dir eq 'E';
    return ($x - 1, $y  ) if $dir eq 'W';
    return ($x  , $y + 1) if $dir eq 'S';
    return ($x  , $y - 1) if $dir eq 'N';
    die "unhandled dir $dir";
};

my $add_beam = sub ($sx, $sy, $dir) {
    my ($x, $y) = $move->($sx, $sy, $dir);
    return unless ($x >= 0 && $x < $w && $y >= 0 && $y < $h);
    return if exists $visited_tiles{"$x/$y/$dir"};
    push @beams, [$dir, $x, $y];
};

if (G_DEBUG_ANIMATE) {
    # use alternate terminal screen if we want to show in situ progress
    system ('tput', 'smcup');
    $SIG{INT} = sub { system('tput', 'rmcup'); exit 1; };
}

while (@beams && @beams < 2048) {
    my ($dir, $x, $y) = (shift @beams)->@*;

    visit($x, $y, $dir);

    if (G_DEBUG_ANIMATE){
        draw_screen_overlayed();
        sleep 1;
    }

    add_next_moves($x, $y, $dir);
}

system ('tput', 'rmcup') if G_DEBUG_ANIMATE;
dump_screen_with_color() if G_DEBUG_OUTPUT;

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
    $h = @grids;
    $w = $grids[0]->@*;
}

sub dump_screen_with_color
{
    for my $y (0..($h-1)) {
        for my $x (0..($w-1)) {
            my $c = $tiles[$y]->[$x] // '';
            if ($c eq '#') {
                # energized
                print "\e[1;31;46m"; # cyan bg, bright red fg
            } else {
                print "\e[37;49m"; # default bg, white fg
            }
            print $grids[$y]->[$x];
        }
        print "\e[37;49m"; # default bg, white fg
        say "";
    }
}

sub draw_screen_overlayed
{
    # clear screen and reset cursor
    print "\e[H\e[2J";

    print "\e[31m"; # color
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

sub visit ($x, $y, $dir)
{
    $tiles[$y]->[$x] = '#';
    $visited_tiles{"$x/$y/$dir"} = 1;
}

sub add_next_moves ($x, $y, $indir)
{
    state %newdir = (
        '/E' => 'N', '/W' => 'S', '/N' => 'E', '/S' => 'W',
        '\E' => 'S', '\W' => 'N', '\N' => 'W', '\S' => 'E',
    );

    my $tile = $grids[$y]->[$x];
    my $horiz = ($indir eq 'E' or $indir eq 'W');
    my $vert = !$horiz;

    if ($tile eq '.' || $tile eq '-' && $horiz || $tile eq '|' && $vert) {
        $add_beam->($x, $y, $indir);
    }
    elsif ($tile eq '|' && $horiz) {
        $add_beam->($x, $y, 'N');
        $add_beam->($x, $y, 'S');
    }
    elsif ($tile eq '-' && $vert) {
        $add_beam->($x, $y, 'E');
        $add_beam->($x, $y, 'W');
    }
    else {
        $add_beam->($x, $y, $newdir{"$tile$indir"});
    }
}
