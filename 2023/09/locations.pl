#!/usr/bin/env perl

# AoC 2023 - Puzzle 09
# This problem requires to read in an input file that ultimately
# maps seed to locations through a bunch of intermediate steps. See
# the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(min max sum);
use Mojo::JSON qw(j);

# Config
my $input_name = @ARGV ? $ARGV[0] : 'input';
my $debug = 0;
$" = ', '; # For arrays interpolated into strings

# Globals
my @seeds;       # seed ids

my %name_maps;   # name of dest map for src
my %id_maps;     # src name holds map of src-id to [$start, $len, $offset]

my $src;         # controls where maps are read in
my $dest;

# Code (Aux subs below)

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    chomp(my $orig_line = $line);

    next if $line =~ /^ *$/;

    if ($line =~ /^seeds:/) {
        read_seeds($line);
    } elsif ($line =~ /map:/) {
        ($src, $dest) = $line =~ /^([^-]+)-to-([^ ]+) map:/;
        say "$src to $dest" if $debug;
        $name_maps{$src} = $dest;
        $id_maps  {$src} = [ ];
    } else {
        read_map_range($src, $dest, $line);
    }
}

say "maps:", j \%id_maps if $debug;

# Maps seeds all the way to locations

my $min_loc = min (map { location_from_seed($_) } @seeds);
say "Lowest location found: $min_loc";

# Aux subs

sub read_seeds($line)
{
    (undef, my $nums) = split(/: */, $line);
    @seeds = split(' ', $nums);
    say "@seeds" if $debug;
}

sub read_map_range($src, $dest, $line)
{
    my ($dest_start, $src_start, $len) = split(' ', $line);
    my $id_ref = $id_maps{$src};

    say "$len items zipped starting at $src_start->$dest_start" if $debug;

    my $start = int $src_start;

    # Look for overlap with existing src-to-dest maps, which may be a problem
    my ($match) = grep { $start >= $_->[0] && ($start - $_->[0]) < $_->[1] } $id_maps{$src}->@*;
    die "Overlap found $src->$dest at id $start" if $match;

    push @$id_ref, [int $src_start, int $len, $dest_start - $src_start];
}

sub location_from_seed($seed)
{
    my $cur_source = 'seed';
    my $id = $seed;

    while ($cur_source ne 'location') {
        my $cur_dest = $name_maps{$cur_source};
        print "$cur_source $id, " if $debug;

        my ($match) = grep { $id >= $_->[0] && ($id - $_->[0]) < $_->[1] } $id_maps{$cur_source}->@*;
        my $offset = $match->[2] // 0;
        $id = $id + $offset;
        $cur_source = $cur_dest;
    }

    print "location $id\n" if $debug;
    return $id;
}
