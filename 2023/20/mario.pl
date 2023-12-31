#!/usr/bin/env perl

# AoC 2023 - Puzzle 20
# This problem requires to read in an input file that ultimately
# lists information about a maze of pipes to unwind.
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
use constant G_DEBUG_FINAL => 0;
use constant G_DEBUG_INPUT => 0;
my $input_name = @ARGV ? $ARGV[0] : '../19/input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

my $stride;
my $rows = 0;
my $maze;

while (chomp(my $line = <$input_fh> // '')) {
    die "non-square input"
        if $stride and length($line) != $stride;
    $stride = length($line)
        unless $stride;

    # Give padding to avoid bounds checks later
    # MUST BE REFLECTED IN STRIDE CALCULATIONS
    $maze .= ".$line.";

    $rows++;
}

# Now add leading/trailing padding
substr($maze, 0, 0, '.' x ($stride + 2));
$maze .= '.' x ($stride + 2);

if (G_DEBUG_INPUT) {
    say "Read $rows rows (padding added)";
    for (my $i = 0; $i < $rows + 2; $i++) {
        say substr($maze, ($stride + 2) * $i, $stride + 2);
    }
}

my $trapped_cells = explore_maze($maze, $stride, $rows);

# Aux subs

sub offset_of($maze, $stride, $x, $y)
{
    return $y * ($stride + 2) + $x;
}

sub char_at($maze, $stride, $x, $y)
{
    return substr($maze, $y * ($stride + 2) + $x, 1);
}

# stride includes passing but rows does not, rows is 1-based
sub find_start($maze, $stride, $rows)
{
    my $char_at = sub($x, $y) { char_at($maze, $stride, $x, $y); };

    for (my $y = 1; $y <= $rows; $y++) {
        for (my $x = 1; $x <= $stride; $x++) {
            return ($x, $y) if $char_at->($x, $y) eq 'S';
        }
    }

    die "did not find start";
}

# Flood fills the region starting from x,y with val, but blocked by piping
sub flood_fill($maze, $stride, $rows, $x, $y, $val)
{
    # can't got through these
    my $block_cells = "|-LJ7F$val";

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

# outputs list of next steps to try in the maze
# coming from direction $from (N/S/E/W)
sub next_steps($maze, $stride, $x, $y, $from, $len)
{
    # We can only arrive in some cells through certain directions
    state %in_dirs = (
        W => 'J-7',
        E => '-FL',
        S => '7F|',
        N => '|LJ',
        x => '|-LJ7F', # start state only
    );

    # We may be able to come into a neighboring cell from a direction
    # that we can't actually leave *here* from. Check both.
    state %out_dirs = (
        '|' => 'NS',
        '-' => 'EW',
        '7' => 'WS',
        'J' => 'WN',
        'F' => 'ES',
        'L' => 'EN',
        'S' => 'NSEW',
    );

    # possible dirs:
    # offset_x, offset_y, dir_from, dir_to
    # (note: from directions are as considered by the new cell we're examining,
    # not the current cell)
    state @poss_dirs = (
        [+ 1,   0, 'W', 'E'],
        [- 1,   0, 'E', 'W'],
        [  0, + 1, 'N', 'S'],
        [  0, - 1, 'S', 'N'],
    );

    my $cell = char_at($maze, $stride, $x, $y);

    my @steps =
        grep { # valid in-dir in the next cell?
            my $ncell = char_at($maze, $stride, $_->[0], $_->[1]);
            my $in_ok = $in_dirs{$_->[2]};
            (index($in_ok, $ncell) != -1);
        }
        map { [ $x + $_->[0], $y + $_->[1], $_->[2], $len ] } # info on next cell
        grep { index($out_dirs{$cell}, $_->[3]) != -1 } # valid out-dirs?
        @poss_dirs;

    return @steps;
}

# Expands the give maze into a bigger one with connecting piping between
# appropriate pieces, so that the bigger one can be flood-filled. You should
# have already removed junk pipe pieces that aren't part of the final loop.
sub bloat_maze($maze, $stride, $rows)
{
    my $can = sub($c, $dir) {
        state %dirs = ( E => '-FLS', W => 'J-7S', N => 'J|LS', S => 'F|7S' );
        return index($dirs{$dir}, $c) != -1;
    };

    my $char_at = sub($x, $y) { char_at($maze, $stride, $x, $y); };

    my $result;
    my $c = $char_at->(0, 0);
    my $was_c = $c;

    # We know the first row/col will be blank spaces, this can simplify
    # printing

    # First row, special case
    $result .= $c;
    for (my $cx = 1; $cx < $stride + 2; $cx++) {
        $c = $char_at->($cx, 0);

        $result .= " $c";
    }

    for (my $cy = 1; $cy < $rows + 2; $cy++) {
        # interstitial row between value rows

        # first column, again a special case.
        $result .= " ";

        # remaining columns of interstitial
        for (my $cx = 1; $cx < $stride + 2; $cx++) {
            my $above_c = $char_at->($cx, $cy - 1);
            $c = $char_at->($cx, $cy);
            my $char = ($can->($above_c, 'S') && $can->($c, 'N'))
                ? " |"
                : "  ";

            $result .= $char;
        }

        # value row

        # first column, again a special case.
        $c = $char_at->(0, $cy);

        $result .= $c;

        for (my $cx = 1; $cx < $stride + 2; $cx++) {
            $c = $char_at->($cx, $cy);
            my $char = ($can->($was_c, 'E') && $can->($c, 'W'))
                ? "-$c"
                : " $c";

            $result .= $char;
            $was_c = $c;
        }
    }

    return $result;
}

sub explore_maze($maze, $stride, $rows)
{
    my @lengths = (undef) x length($maze); # hold data on lengths
    my $char_at = sub($x, $y) { char_at($maze, $stride, $x, $y); };
    my $set_char = sub($x, $y, $v) { substr($maze, $y * ($stride + 2) + $x, 1, $v) };
    my $len = sub($x, $y, $val = undef) {
        my $p = $y * ($stride+2) + $x;
        $lengths[$p] = $val // $lengths[$p];
        $lengths[$p]
    };

    my $show = sub {
        for (my $j = 1; $j <= $rows; $j++) {
            for (my $i = 1; $i <= $stride; $i++) {
                my $col = defined $len->($i, $j) ? GREEN : RESET;
                print $col . $char_at->($i, $j);
            }

            print RESET . "\t\t";

            for (my $i = 1; $i <= $stride; $i++) {
                my $val = $len->($i, $j) // '.';
                print sprintf("%03d ", $len->($i, $j)) if $val ne '.';
                print BLUE . sprintf(" .  ") . RESET if $val eq '.';
            }
            print "\n";
        }
        print "\n";
    };

    my ($x, $y) = find_start($maze, $stride, $rows);
    $len->($x, $y, 0); # init start pos with 0

    my @queue;
    my $i = 0;

    # starting dir is 'x', then one of N/E/S/W from there
    push @queue, next_steps($maze, $stride, $x, $y, 'x', 1);
    while (@queue) {
        my $cur = shift @queue;
        my ($nx, $ny, $ndir, $nlen) = @$cur; # n for 'next cell'
        if (!$len->($nx, $ny) || $len->($nx, $ny) > $nlen) {
            $len->($nx, $ny, $nlen);

            # found shorter path, update and keep searching
            my @new_steps = next_steps($maze, $stride, $nx, $ny, $ndir, $nlen + 1);
            push @queue, @new_steps;
        }

        $show->() if G_DEBUG_INTERMEDIATE;

        die "too long" if ++$i > 1000000;
    }

    # Now that maze is mapped out, look for trapped cells by flood fill
    # starting from the padding.

    $show->() if G_DEBUG_FINAL;

    # ANY piece of pipe not attached to the main loop can count as
    # area inside the loop for purposes of the puzzle. To avoid having
    # to separate between them, turn all pipe pieces not in the loop into
    # a '.'
    for (my $i = 0; $i < @lengths; $i++) {
        my $len = $lengths[$i];
        if (!defined $len && index('JF7L-|', substr($maze, $i, 1)) != -1) {
            substr($maze, $i, 1, '.');
        }
    }

    # expand puzzle into something we can flood fill
    my $maze2 = bloat_maze($maze, $stride, $rows);

    my $new_stride = ($stride + 2) * 2 - 1;
    my $new_rows = ($rows + 2) * 2 - 1;

    if (G_DEBUG_FINAL) {
        for (my $yy = 0; $yy < $new_rows; $yy++) {
            say substr($maze2, $yy * $new_stride, $new_stride)
        }
    }

    my $maze3 = flood_fill($maze2, $new_stride, $new_rows, 0, 0, '@');

    if (G_DEBUG_FINAL) {
        for (my $yy = 0; $yy < $new_rows; $yy++) {
            say substr($maze3, $yy * $new_stride, $new_stride)
        }
    }

    my $count = grep { $_ eq '.' } split('', $maze3);
    say "$count entries unscathed.";
}
