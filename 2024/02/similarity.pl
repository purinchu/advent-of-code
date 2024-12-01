#!/usr/bin/env perl

use v5.38;
use autodie;

my $file = shift @ARGV // '../01/input';
open my $fh, '<', $file;

my @lines = <$fh>;
close $fh;

my (@lefts, @rights);
for my $line (@lines) {
    my ($l, $r) = split(' ', $line);
    push @lefts, $l;
    push @rights, $r;
}

my $similarity = 0;
my %counts;

# Count number of times number on right is ever encountered
$counts{$_}++ foreach @rights;

# Calculate similarity based on these counts
for my $left (@lefts) {
    $similarity += $left * ($counts{$left} // 0);
}

say $similarity;
