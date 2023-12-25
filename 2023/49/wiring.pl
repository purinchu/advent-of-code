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

# Config
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Command-line opts
my $show_input = 0;

GetOptions(
    "show-input|i"    => \$show_input,
) or die "Error reading command line options";

# Load/dump input

my @hail;

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

# Aux subs

# TODO: Derive this programmatically.  I already got the star, but did so with manual use of GraphViz and some text-editing tools.
# 1. Generate a graph.dot using the code below.
# 2. Use "neato", *without* edge labels, and it makes it pretty apparent on my input what edges to trim.
# 3. Manually go to the input and remove those edges
# 4. Re-run the code below against the updated input.
# 5. This will generate a .dot without any subgraph clusters so we're still in
#    a tough spot... but just run 'ccomps' (part of GraphViz) and it will find
#    subgraphs for you and spit that out into a separate .dot file.
# 6. Copy the node-to-node edges out of the two subcomponents in the updated .dot file into individual files
# 7. Use vim to cleanup and then sort | uniq | wc -l to find the number of components.
# 8. Basic multiplication and you're done.
sub load_input(@lines)
{
    say "graph {";
    my $i = 0;
    for (@lines) {
        my ($l, $r) = split(': ');
        my @nodes = split(' ', $r);

        say "\t$l--$_" foreach @nodes;
        $i++
    }
    say "}";
}

=head1 SYNOPSIS

A puzzle about connections.

Usage: ./wiring.pl [-i] [FILE_NAME] -- [x] [y]

  -i | --show-input -> Echo input back and exit.

FILE_NAME specifies the wiring info to use, and is 'input' if not specified.

=back
