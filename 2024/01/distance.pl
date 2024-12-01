#!/usr/bin/env perl

use v5.38;
use autodie;

my $file = shift @ARGV // 'input';
open my $fh, '<', $file;

my @lines = <$fh>;
close $fh;

my (@lefts, @rights);
for my $line (@lines) {
    my ($l, $r) = split(' ', $line);
    push @lefts, $l;
    push @rights, $r;
}

@lefts = sort @lefts;
@rights = sort @rights;
my $distance = 0;

local $, = ', ';

for (my $i = 0; $i <= $#lefts; $i++) {
    my $dist = abs($lefts[$i] - $rights[$i]);
    $distance += $dist;
}

say $distance;
