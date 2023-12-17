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

my @grids;   # Mirror grid
my ($h, $w); # Grid dimension
my %cache;   # Memoization cache
my %cycles;  # Loops to be fixed up

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
}

# For fun, run the initial_dir[0] and then the initial_dir[5], and compare to
# what you get if you run initial_dir[5] by itself. Since the current code
# gives up on a segment once a cycle is detected, the cache is susceptible to
# the order that you try to interrogate a potential cycle, potentially leaving
# an eventually-cached entry for an (x,y,dir) short of all the cells it could
# cover (because the other cells in the cycle were made part of a different
# cache entry).
#
# Probably a way to fix this by thinking smarter about but not there right now.

my @initial_dirs;
push @initial_dirs, map { ([0, $_, 'E'], [$w - 1, $_, 'W']) } 0..($h-1);
push @initial_dirs, map { ([$_, 0, 'S'], [$_, $h - 1, 'N']) } 0..($w-1);

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

    # Doing this to try to 'patch up' cached cycles seems to fix up some of the
    # correctness issues... but not all.  And it's so SLOOW.  But it does at
    # least find the appropriate max to solve the puzzle, so there's that.
    while (my ($key, $cycles) = each %cycles) {
        my $found = 0;
        my @c = grep { $found ||= $key eq $_ ; $found } $cycles->@*;

        # Need to make sure every one of these segments is included in the cache
        # for each of these entries...
        my @reachable = map { $_->@* } @cache{@c};

        # de-dup cruft from potential multiple results. Same method as in
        # energized_cells.
        my %h = map { (join('_', $_->@*), $_) } @reachable;
        my @reachable_set = values %h;
        my $num_reachable = num_covered(@reachable_set);
        @cache{@c} = (\@reachable_set) x @c;
    }

    %cycles = ();
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

    $h = @grids;
    $w = $grids[0]->@*;
}

# returns a list of all line segments (x, y, dir, length) reachable from
# the given x,y,dir combination
sub energized_cells ($x, $y, $indir, @stack)
{
    no warnings 'recursion';

    state %newdir = (
        '/E' => 'N', '/W' => 'S', '/N' => 'E', '/S' => 'W',
        '\E' => 'S', '\W' => 'N', '\N' => 'W', '\S' => 'E',
    );

    my $key = join('_', $x, $y, $indir);

    if (($cache{$key} // '') eq 'cycle') {
        # use later to patch up cache to encompass entire cycle
        $cycles{$key} = [@stack];
        return ();
    }

    return $cache{$key}->@* if exists $cache{$key};

    my $set = sub ($x, $y, $indir, @segments) {
        my $key = join('_', $x, $y, $indir);
        $cache{$key} = \@segments;
        return @segments;
    };

    # temp for now to break cycles. We will overwrite with right value.
    $cache{$key} = 'cycle';
    push @stack, $key;

    my $tile = $grids[$y]->[$x];
    my $horiz = ($indir eq 'E' or $indir eq 'W');

    my @list; # results

    if ($horiz && ($tile eq '.' || $tile eq '-')) {
        my $row = $grids[$y];

        # all cells [$x,$end] will be blank. Up-to-and-including. Stop is just *before* a splitter/mirror.
        if ($indir eq 'E') {
            my $end = ((first { $row->[$_] ne '-' and $row->[$_] ne '.' } $x..($w-1)) // $w) - 1;
            @list = [$x, $y, $indir, $end - $x + 1];
            push @list, energized_cells($end + 1, $y, $indir, @stack)
                if $end < ($w - 1); # splitters
        } else {
            my $end = ((first { $row->[$_] ne '-' and $row->[$_] ne '.' } reverse 0..$x) // -1) + 1;
            @list = [$x, $y, $indir, $x - $end + 1];
            push @list, energized_cells($end - 1, $y, $indir, @stack)
                if $end > 0;
        }
    }
    elsif (!$horiz && ($tile eq '.' || $tile eq '|')) {
        # all cells [$y,$end] will be blank. Up-to-and-including. Stop is just *before* a splitter/mirror.
        if ($indir eq 'S') {
            my $end = ((first { $grids[$_]->[$x] ne '|' and $grids[$_]->[$x] ne '.' } $y..($h-1)) // $h) - 1;
            @list = [$x, $y, $indir, $end - $y + 1];
            push @list, energized_cells($x, $end + 1, $indir, @stack)
                if $end < ($h - 1);
        } else {
            my $end = ((first { $grids[$_]->[$x] ne '|' and $grids[$_]->[$x] ne '.' } reverse 0..$y) // -1) + 1;
            @list = [$x, $y, $indir, $y - $end + 1];
            push @list, energized_cells($x, $end - 1, $indir, @stack)
                if $end > 0;
        }
    }
    elsif ($tile eq '|' && $horiz) {
        @list = [$x, $y, $indir, 1];
        push @list, energized_cells($x, $y - 1, 'N', @stack)
            if $y > 0;
        push @list, energized_cells($x, $y + 1, 'S', @stack)
            if $y < ($h - 1);
    }
    elsif ($tile eq '-' && !$horiz) {
        @list = [$x, $y, $indir, 1];
        push @list, energized_cells($x + 1, $y, 'E', @stack)
            if $x < ($w - 1);
        push @list, energized_cells($x - 1, $y, 'W', @stack)
            if $x > 0;
    }
    else {
        @list = [$x, $y, $indir, 1];
        my $outdir = $newdir{"$tile$indir"} or die "dir bad";

        state %xoff = (E => 1, W => -1);
        state %yoff = (S => 1, N => -1);

        my $outx = $x + ($xoff{$outdir} // 0);
        my $outy = $y + ($yoff{$outdir} // 0);

        if ($outx >= 0 && $outx < $w && $outy >= 0 && $outy < $h) {
            push @list, energized_cells($outx, $outy, $outdir, @stack);
        }
    }

    # de-dup cruft from potential multiple results. This is just working to
    # ensure identical line segments stringify to identical strings to abuse
    # uniqueness of hash entries.
    my %h = map { (join('_', $_->@*), $_) } @list;
    die "how did we get here???" if scalar values %h == 0;
    return $set->($x, $y, $indir, values %h);
}

sub num_covered(@segments)
{
    my %visited;

    my %xoff = (E => 1, W => -1);
    my %yoff = (S => 1, N => -1);

    for (@segments) {
        my ($x, $y, $dir, $len) = $_->@*;

        for (my $i = 0; $i < $len; $i++) {
            my $outx = $x + $i * ($xoff{$dir} // 0);
            my $outy = $y + $i * ($yoff{$dir} // 0);
            $visited{"$outx,$outy"} = 1;
        }
    }

    return scalar %visited;
}

sub num_energized ($x, $y, $initialdir)
{
    # have to reset because the cache is not idempotent across multiple
    # initialdirs
#   %cache = (); # Uncomment to ensure correctness at expense of speed.

    my @segments = energized_cells($x, $y, $initialdir);

    return num_covered(@segments);
}
