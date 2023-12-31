#!/usr/bin/env perl

# AoC 2023 - Puzzle 49
# This problem requires to read in an input file that ultimately
# lists information about module connections.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(first all min max reduce uniqint);
use Storable qw(dclone);
use Getopt::Long qw(:config auto_version auto_help);
use JSON;

use Array::Heap::ModifiablePriorityQueue;

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Command-line opts
my $show_input = 0;

GetOptions(
    "show-input|i"    => \$show_input,
) or die "Error reading command line options";

# Load/dump input

my %nodes; # from => connection_num
my %edges; # from/to or to/from, aliased to same info
my %dist;  # from => to => dist.

do {
    $input_name = shift @ARGV // $input_name;

    open my $input_fh, '<', $input_name;
    chomp(my @lines = <$input_fh>);

    if ($show_input) {
        say for @lines;
        exit 0;
    }

    load_input(@lines);
};

my @sorted_nodes = sort keys %nodes;
for my $k (@sorted_nodes) {
    best_paths($k);

    my @all_others = grep { $_ ne $k } @sorted_nodes;

    for my $other (@all_others) {
        next unless defined $dist{$k}->{$other}->[1];
        my @path = trace_path($k, $other);
        my $d = $dist{$k}->{$other}->[0];

        # include edges from k -> vias and vias -> last
        # in accounting for edge usage
        @path = ($k, @path, $other);

        for (my $i = 1; $i < @path; $i++) {
            # find edge conveying route and inc its usage
            my ($l, $r) = @path[($i-1)..$i];
            $edges{$l}->{$r}->[1] += $d;
        }
    }
}

my %edge_weights;
for my $l (sort keys %edges) {
    for my $r (sort keys $edges{$l}->%*) {
        my $key = join('-', sort ($l, $r));
        $edge_weights{$key} += $edges{$l}->{$r}->[1] // 0;
    }
}

my @top =
    map { $_->[0] }
    sort { $b->[1] <=> $a->[1] }
    map { [ $_ => $edge_weights{$_} ] }
    keys %edge_weights;

@top = @top[0..2]; # top 3

say "Top 3 nodes by connections: @top";

# remove edges and count connections
for my $pair (@top) {
    my ($l, $r) = split('-', $pair);
    delete $edges{$l}->{$r};
    delete $edges{$r}->{$l};
}

my $n = $sorted_nodes[0]; # just pick a node and count
my @neighbors = neighbors_of($n);
my %visited;

while (@neighbors) {
    my %new_neighbors;
    for my $n (@neighbors) {
        my @ns = grep { !exists $visited{$_} } neighbors_of($n);
        @new_neighbors{@ns} = (1) x @ns;
    }

    @visited{@neighbors} = (1) x @neighbors;
    @neighbors = keys %new_neighbors;
}

my $num_nodes   = %nodes;
my $num_cluster = %visited;
my $num_other   = $num_nodes - $num_cluster;
say "There are $num_nodes nodes and $num_cluster in 1 cluster, $num_other in the other.";
say "Product is ", $num_other * $num_cluster;

# Aux subs

# Runs Dijkstra's algorithm to update program state to reflect best available
# path from $from to other nodes in the graph.
sub best_paths($from)
{
    my %visited;
    my $visit = Array::Heap::ModifiablePriorityQueue->new;
    my $dist;

    $visit->add($from, 0);
    while ($visit->size > 0) {
        $dist = $visit->min_weight + 1; # weight of the item we're about to get
        my $node = $visit->get;

        my @neighbors = grep { !exists $visited{$_} } neighbors_of($node);
        foreach my $n (@neighbors) {
            my $w = $visit->weight($n);
            next if defined $w and $w <= $dist;
            $visit->add($n, $dist);
            set_distance_to($from, $n, $node, $dist);
        }

        $visited{$node} = 1;
    }
}

sub neighbors_of($n)
{
    my @neighbors = sort keys $edges{$n}->%*;
}

sub set_distance_to($f, $n, $via, $d)
{
    my $distref = [ 1, undef ];
    $dist{$n}->{$f} //= $distref;
    $dist{$f}->{$n} //= $distref;

    $dist{$n}->{$f}->[0] = $d;
    $dist{$n}->{$f}->[1] = $via;
}

# return intermediate steps on route from $from to $to, if any. If it's a
# direct route the return value will be an empty list. If there's no route the
# return value is undef.
sub trace_path($from, $to)
{
    # may be no path
    return unless $dist{$from}->{$to}->[1];

    my @path;
    my $via = $dist{$from}->{$to}->[1];
    while($via ne $from) {
        unshift @path, $via;
        $via = $dist{$from}->{$via}->[1];
    }

    return @path;
}

sub load_input(@lines)
{
    for (@lines) {
        my ($l, $r) = split(': ');
        my @ns = split(' ', $r);

        # add edges first
        $edges{$l} //= { };
        for my $n (@ns) {
            $edges{$n} //= { };
            my $dist = [ 1, 0 ];
            $edges{$l}->{$n} = $dist;
            $edges{$n}->{$l} = $dist; # same listref
        }

        # dist between nodes
        $dist{$l} //= { };
        for my $n (@ns) {
            $dist{$n} //= { };
        }

        # record node existence
        push @ns, $l;
        @nodes{@ns} = (1) x @ns;
    }
}

=head1 SYNOPSIS

A puzzle about connections.

Usage: ./wiring.pl [-i] [FILE_NAME] -- [x] [y]

  -i | --show-input -> Echo input back and exit.

FILE_NAME specifies the wiring info to use, and is 'input' if not specified.

=back
