#!/usr/bin/env perl

# This problem requires to read in an input file one line at a time
# Each line contains one or more digits and other extraneous info
# Each line produces a 2-digit calibration value, the first and last digit in that order
# The sum of all these lines is the first puzzle solution.

use 5.036;
use autodie;

# Config
my $input_name = 'input';
my $debug = 0;

# Globals
my $sum = 0;

# Code

open my $input_fh, '<', $input_name;

while (my $line = <$input_fh>) {
    my ($first) = $line =~ /^[^0-9]*([0-9])/;
    my ($second) = (scalar reverse $line) =~ /^[^0-9]*([0-9])/;
    say "${first}${second}" if $debug;
    $sum += int($first . $second);
}

say "Sum is $sum";
