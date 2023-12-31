#!/usr/bin/env perl

# AoC 2023 - Puzzle 32 (Day 16 Part 2)
# This problem requires to read in an input file that ultimately
# lists information about info grids to find where these grids have
# beams cross over them
# See the Advent of Code website.

use 5.038;
use autodie;

use List::Util qw(sum first zip min max);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_ANIMATE => 0;
use constant G_DEBUG_OUTPUT => 0;

my $input_name = '../31/input';
$" = ', '; # For arrays interpolated into strings

# Globals

my @grids; # Mirror grid
my @tiles; # Portions of grid energized
my @beams; # Beams of light in motion
my @visited_tiles; # Detects cycles of beams
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

my @initial_dirs;

# Directions N S E W => 0 1 2 3
push @initial_dirs, map { ([0, $_, 2], [$w - 1, $_, 3]) } 0..($h-1);
push @initial_dirs, map { ([$_, 0, 1], [$_, $h - 1, 0]) } 0..($w-1);

say scalar @initial_dirs, " unique directions to try";

my $max_energized = 0;
my $i = 0;
my $last_update = 0;

for my $init (@initial_dirs) {
    $max_energized = max ($max_energized, num_energized($init->@*));
    $i++;

    my $cur_update = time;
    if ($cur_update != $last_update) {
        print "\e[2K\r"; # clear line
        print sprintf("%05d", $i), " / ", sprintf("%05d", scalar @initial_dirs), " cases handled, cur max $max_energized.";
        select()->flush();
        $last_update = $cur_update;
    }
}

say "";
say "Max energized? $max_energized";

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

sub visit ($x, $y, $dir_code)
{
    $tiles[$y]->[$x] = '#';

    # need separate cache because multiple beams can appear going different
    # directions. We can only skip if direction was also seen
    $visited_tiles[$y * $w + $x] |= (1 << $dir_code);
}

sub add_next_moves ($x, $y, $dir_code)
{
    state %dirs = (N => 0, S => 1, E => 2, W => 3);
    state %newdir = (
        '/2' => 0, '/3' => 1, '/0' => 2, '/1' => 3,
        '\2' => 1, '\3' => 0, '\0' => 3, '\1' => 2,
    );

    my $tile = $grids[$y]->[$x];
    my $horiz = $dir_code >= 2;

    if ($horiz && ($tile eq '.' || $tile eq '-')) {
        my $row = $grids[$y];

        if ($dir_code == 2) { # E
            my $end = ((first { $row->[$_] ne '-' and $row->[$_] ne '.' } $x..($w-1)) // $w) - 1;
            visit($_, $y, $dir_code) foreach $x..$end;
            add_beam($end, $y, $dir_code) if $end < ($w - 1); # only add beam if we hit a mirror
        } else {
            my $end = ((first { $row->[$_] ne '-' and $row->[$_] ne '.' } reverse 0..$x) // 0) + 1;
            visit($_, $y, $dir_code) foreach $end..$x;
            add_beam($end, $y, $dir_code) if $end > 0; # only add beam if we hit a mirror
        }
    }
    elsif (!$horiz && ($tile eq '.' || $tile eq '|')) {
        if ($dir_code == 1) { # S
            my $end = ((first { $grids[$_]->[$x] ne '|' and $grids[$_]->[$x] ne '.' } $y..($h-1)) // $h) - 1;
            visit($x, $_, $dir_code) foreach $y..$end;
            add_beam($x, $end, $dir_code) if $end < ($h - 1); # only add beam if we hit a mirror
        } else {
            my $end = ((first { $grids[$_]->[$x] ne '|' and $grids[$_]->[$x] ne '.' } reverse 0..$y) // 0) + 1;
            visit($x, $_, $dir_code) foreach $end..$y;
            add_beam($x, $end, $dir_code) if $end > 0; # only add beam if we hit a mirror
        }
    }
    elsif ($tile eq '|' && $horiz) {
        add_beam($x, $y, 0);
        add_beam($x, $y, 1);
    }
    elsif ($tile eq '-' && !$horiz) {
        add_beam($x, $y, 2);
        add_beam($x, $y, 3);
    }
    else {
        add_beam($x, $y, $newdir{"$tile$dir_code"});
    }
}

# starting from sx,sy, moves in dir and, if valid and not seen, adds a
# beam for later processing
sub add_beam ($sx, $sy, $dir)
{
    state @xoff = (0, 0, 1, -1); # N S E W
    state @yoff = (-1, 1, 0, 0);

    my $x = $sx + $xoff[$dir];
    my $y = $sy + $yoff[$dir];

    return unless ($x >= 0 && $x < $w && $y >= 0 && $y < $h);
    return if (($visited_tiles[$y * $w + $x] // 0) & (1 << $dir));

    push @beams, [$dir, $x, $y];
}

sub num_energized ($x, $y, $initialdir)
{
    # clear state
    @beams = [$initialdir, $x, $y];
    @tiles = map { [('.') x (@$_)] } @grids;
    @visited_tiles = ();

    if (G_DEBUG_ANIMATE) {
        # use alternate terminal screen if we want to show in situ progress
        system ('tput', 'smcup');
        $SIG{INT} = sub { system('tput', 'rmcup'); exit 1; };
    }

    while (@beams) {
        die "too many concurrent beams" if @beams >= 2048;

        my ($dir, $x, $y) = (shift @beams)->@*;

        visit($x, $y, $dir);

        if (G_DEBUG_ANIMATE){
            draw_screen_overlayed();
            sleep 1;
        }

        add_next_moves($x, $y, $dir);
    }

    system ('tput', 'rmcup') if G_DEBUG_ANIMATE;
    delete $SIG{INT};

    dump_screen_with_color() if G_DEBUG_OUTPUT;

    return scalar grep { $_ eq '#' } map { ($_->@*) } @tiles;
}
