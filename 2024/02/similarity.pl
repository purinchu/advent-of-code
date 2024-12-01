#!/usr/bin/env perl

use v5.38;
use autodie;
use List::Util qw(sum);

my $file = shift @ARGV // '../01/input';
open my $fh, '<', $file;

my @lines = <$fh>;
close $fh;

my @lefts;
my %counts;

for my $line (@lines) {
    my ($l, $r) = split(' ', $line);
    $counts{$r}++;
    push @lefts, $l;
}

# Calculate similarity based on these counts
say (sum map { $_ * ($counts{$_} // 0) } @lefts);
