#!/usr/bin/env perl

# AoC 2023 - Puzzle 44
# This problem requires to read in an input file that ultimately
# lists information about falling bricks.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

no warnings 'recursion'; # you betcha

use List::Util qw(first all min max reduce);
use Storable qw(dclone);
use Getopt::Long qw(:config auto_version auto_help);

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

use constant G_GRID_SIZE => 340;

# Command-line opts
my $show_input = 0;
my $show_grid = 0;
my $dump_settled = 0;

GetOptions(
    "show-input|i"    => \$show_input,
    "show-grid|g"     => \$show_grid,
    "dump-settled|s"  => \$dump_settled,
) or die "Error reading command line options";

# Bricks are stored as 2 different 2-D grids to help me visualize better.
# Access as $zx_grid[$z]->[$x]
my @zx_grid = map { [map { [] } 1..G_GRID_SIZE] } 1..G_GRID_SIZE;
my @zy_grid = map { [map { [] } 1..G_GRID_SIZE] } 1..G_GRID_SIZE;

my @min_grid = (1000, 1000, 1000);
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

    say "Loading ", scalar @lines, " lines of input.";
    load_input(@lines);
};

if ($show_grid) {
    show_grid();
}

say "Input loaded, ", scalar @bricks, " bricks, settling them.";
say "Grid extent: @min_grid to @max_grid";

settle_bricks();

if ($show_grid) {
    say "Post-settling:";
    show_grid();
}

say "Bricks settled, re-settling for support.";

# do this again to get valid info on what bricks are supporting what, as the
# support will change as bricks fall from under a supported brick
delete $_->{supporting} foreach @bricks;
settle_bricks(); # should be no motion this time

say "Resettling done. Building support map.";

if ($dump_settled) {
    dump_settled_bricks();
}

# Build support map. A brick can be disintegrated if its loss would not cause
# ANY other brick to fall. So for the list of bricks supported, each of those
# supported bricks would need to have at least one other source of support.
my %supported_by;
my %supports;

for my $idx (0..$#bricks) {
    my $b = $bricks[$idx];
    my $spt = $b->{supporting} // [];

    my %dedup;
    @dedup{@$spt} = (1) x @$spt;

    my @supported = keys %dedup;
    $supports{$idx} = [@supported];

    foreach (@supported) {
        $supported_by{$_} //= [ ];
        push $supported_by{$_}->@*, $idx;
    }
}

# Metadata built, do the checks

my $sum = 0;
for my $idx (0..$#bricks) {
    my $b = $bricks[$idx];
    my $spt = $b->{supporting} // [];

    my $removable = all { $supported_by{$_}->@* >= 2 } $spt->@*;
    $removable //= 1; # can be removed if we're not supporting anyone

    $sum++ if $removable;
}

say $sum;

# Now check for the largest 'chain reaction'

$sum = 0;

# First remove any nodes not already supported by something
# so we can use the absence of support as an indication it will fall
my @fixed_bricks = grep { $supported_by{$_}->@* == 0 } keys %supported_by;
delete @supported_by{@fixed_bricks};

for my $idx (0..$#bricks) {
    my $spt_by = dclone(\%supported_by);
    my $spts   = dclone(\%supports);

    $sum += chain_size($idx, $spts, $spt_by);
}

say $sum;

# Aux subs

# recursive
sub chain_size($idx, $spts, $spt_by)
{
    my @falling;

    my $sum = 0;

    for my $supported ($spts->{$idx}->@*) {
        my @supporters = $spt_by->{$supported}->@*;
        my $pillar_index = first { $supporters[$_] == $idx } 0..$#supporters;
        splice $spt_by->{$supported}->@*, $pillar_index, 1;
        push @falling, $supported unless $spt_by->{$supported}->@*;
    }

    $spts->{$idx}->@* = (); # not holding anything up now...

    $sum += @falling;

    # if we caused any new bricks to fall, remove them as well
    $sum += chain_size($_, $spts, $spt_by) foreach @falling;

    return $sum;
}

sub load_input(@lines)
{
    for (@lines) {
        my ($l, $r) = split('~');
        my ($x1, $y1, $z1) = split(',', $l);
        my ($x2, $y2, $z2) = split(',', $r);

        build_brick_x($y1, $z1, $x1, $x2) if $x1 != $x2;
        build_brick_y($x1, $z1, $y1, $y2) if $y1 != $y2;
        build_brick_z($x1, $y1, $z1, $z2) if $z1 != $z2;
        if ($x1 == $x2 && $y1 == $y2 && $z1 == $z2) {
            # of course this could happen
            build_brick_x($y1, $z1, $x1, $x2);
        }

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
        id => chr(ord('A') + ($brick_id % 26)),
        idx => $brick_id,
        x => [$x1, $x2],
        y => [$y, $y],
        z => [$z, $z],
        ori => 'x',
    };

    push $zy_grid[$z]->[$y]->@*, $brick_id;
    for my $x ($x1..$x2) {
        push $zx_grid[$z]->[$x]->@*, $brick_id;
    }

    $brick_id++;
}

sub build_brick_y($x, $z, $y1, $y2)
{
    ($y1, $y2) = ($y2, $y1) if $y1 > $y2;

    push @bricks, {
        id => chr(ord('A') + ($brick_id % 26)),
        idx => $brick_id,
        x => [$x, $x],
        y => [$y1, $y2],
        z => [$z, $z],
        ori => 'y',
    };

    push $zx_grid[$z]->[$x]->@*, $brick_id;
    for my $y ($y1..$y2) {
        push $zy_grid[$z]->[$y]->@*, $brick_id;
    }

    $brick_id++;
}

sub build_brick_z($x, $y, $z1, $z2)
{
    ($z1, $z2) = ($z2, $z1) if $z1 > $z2;

    push @bricks, {
        id => chr(ord('A') + ($brick_id % 26)),
        idx => $brick_id,
        x => [$x, $x],
        y => [$y, $y],
        z => [$z1, $z2],
        ori => 'z',
    };

    for my $z ($z1..$z2) {
        push $zx_grid[$z]->[$x]->@*, $brick_id;
        push $zy_grid[$z]->[$y]->@*, $brick_id;
    }

    $brick_id++;
}

sub move_by_index($dest, $src, $idx)
{
    my $dest_idx = first { $dest->[$_] == $idx } 0..($dest->@*-1);
    my $src_idx  = first { $src ->[$_] == $idx } 0..($src->@*-1);

    push $dest->@*, $idx unless $dest_idx;
    splice $src->@*, $src_idx, 1;
}

sub settle_bricks()
{
    my @falling_bricks = sort { $a->{z}->[0] <=> $b->{z}->[0] } @bricks;
    for my $b (@falling_bricks) {
        while (!is_supported($b->{idx})) {
            my ($x1, $y1, $z1) = map { $_->[0] } $b->@{qw/x y z/};
            my ($x2, $y2, $z2) = map { $_->[1] } $b->@{qw/x y z/};
            my ($dx, $dy, $dz) = map { $_ eq $b->{ori} } qw/x y z/;

            # move block down by 1
            for my $z ($z1..$z2) {
                for my $x ($x1..$x2) {
                    move_by_index($zx_grid[$z - 1]->[$x], $zx_grid[$z]->[$x], $b->{idx});
                }

                for my $y ($y1..$y2) {
                    move_by_index($zy_grid[$z - 1]->[$y], $zy_grid[$z]->[$y], $b->{idx});
                }
            }

            $b->{z}->[0]--;
            $b->{z}->[1]--;
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

    my %supporting_bricks;

    # must have something below in both zx and zy planes, and that
    # something must have stopped falling itself.
    my @bricks_below =
                map { @bricks[$_->@*] }
                grep { $_->@* > 0 } $zx_grid[$z1-1]->@[$x1..$x2];
    my @zx_bricks = grep { !($_->{falling} // 1) } @bricks_below;
    $supporting_bricks{$_->{idx}} |= 1 foreach @zx_bricks;

    @bricks_below =
                map { @bricks[$_->@*] }
                grep { $_->@* > 0 } $zy_grid[$z1-1]->@[$y1..$y2];
    my @zy_bricks = grep { !($_->{falling} // 1) } @bricks_below;
    $supporting_bricks{$_->{idx}} |= 2 foreach @zy_bricks;

    my @touching = grep { $supporting_bricks{$_} == 3 } keys %supporting_bricks;
    for (@touching) {
        my $b = $bricks[$_];
        $b->{supporting} //= [ ];
        if (!($b->{falling} // 1)) {
            push $b->{supporting}->@*, $idx;
        }
    }

    return @touching > 0;
}

sub dump_settled_bricks()
{
    open my $fh, '>', 'out';
    foreach my $b (@bricks) {
        my ($x1, $y1, $z1) = map { $_->[0] } $b->@{qw/x y z/};
        my ($x2, $y2, $z2) = map { $_->[1] } $b->@{qw/x y z/};

        say $fh "$x1,$y1,$z1~$x2,$y2,$z2";
    }
    close $fh;
    say "Dumped to out";
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

    for my $ch (($min_grid[0])..($max_grid[0])) {
        print "\e[92;3m". ($ch % 10);
    }

    $y_pos = $xz_width + 2;
    print "\e[${y_pos}G";
    for my $ch (($min_grid[1])..($max_grid[1])) {
        print "\e[92;3m". ($ch % 10);
    }

    print "\e[0m\n";

    for (my $row = $max_grid[2]; $row > 0; $row--) {
        for (my $x = $min_grid[0]; $x <= $max_grid[0]; $x++) {
            my $b = ($zx_grid[$row]->[$x]->@* > 1)
                    ? '?'
                    : (($zx_grid[$row]->[$x]->[0]) // "\e[2;36m.\e[0m");
            $b = ($b % 10) unless $b =~ /[?.]/;
            print $b;
        }

        print " \e[92;3m", ($row % 10), "\e[0m";

        print " z" if $row == int(($max_grid[2] + 1) / 2);

        print "\e[${y_pos}G\e[0m";
        for (my $y = 0; $y <= $max_grid[1]; $y++) {
            my $b = ($zy_grid[$row]->[$y]->@* > 1)
                    ? '?'
                    : (($zy_grid[$row]->[$y]->[0]) // "\e[2;36m.\e[0m");
            $b = ($b % 10) unless $b =~ /[?.]/;
            print $b;
        }

        print " \e[92;3m", ($row % 10), "\e[0m";

        print " z" if $row == int(($max_grid[2] + 1) / 2);

        print "\n";
    }

    print (('-') x ($max_grid[0] - $min_grid[0] + 1));
    print " \e[92;3m0";

    print "\e[${y_pos}G\e[0m";
    print (('-') x ($max_grid[1] - $min_grid[1] + 1));
    print " \e[92;3m0";

    print "\e[0m\n";
}

=head1 SYNOPSIS

A puzzle about falling bricks to be disintegrated.

Usage: ./tetris.pl [-i] [FILE_NAME]

  -i | --show-input -> Echo input back and exit.
  -g | --show-grid  -> Show puzzle grid after setup, and keep running.
  -s | --dump-settled -> Spit out the settled bricks in the input format.

FILE_NAME specifies the brick snapshot to use, and is 'input' if not specified.

=back
