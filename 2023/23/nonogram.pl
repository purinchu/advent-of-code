#!/usr/bin/env perl

# AoC 2023 - Puzzle 23 (Day 11 Part 1)
# This problem requires to read in an input file that ultimately
# lists information about a nonogram-like set of info on a row to validate.
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
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_ROWS => 0;
use constant G_DEBUG_MASK => 0;
my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', (shift @ARGV // $input_name);

chomp(my @lines = <$input_fh>);

my @rows = map {
    my ($r, $crc) = split(' ', $_);
    my @sums = split(',', $crc);
    [$r, @sums];
} @lines;

if (G_DEBUG_INPUT) {
    for (@rows) {
        my ($row, @checksums) = $_->@*;
        say "Row $row, @checksums";
    }
    say "Read ", scalar @rows, " rows";
}

my $maxmask = max(map { length $_->[0] } @rows);

my $sum = 0;
for my $row (@rows) {
    my ($template, @partlens) = $row->@*;
    my @valid = generate_valid_rows($template, @partlens);
    $sum += @valid;
    print sprintf("%-${maxmask}s: ", $template), scalar @valid, " options for ";
    say "[@partlens]";
}

say $sum;

# Aux subs

# Generates all potentially-valid rows that meet restrictions of the
# template
sub generate_valid_rows($template, @partlens)
{
    my $maxlen = length $template;
    my $minlen = sum(@partlens) + (@partlens - 1);

    my %ok_rows; # store as hash keys for free de-dup

    for (my $i = 0; $i <= ($maxlen - $minlen); $i++) {
        my @rows = generate_rows_with_padding($i, $template, @partlens);
        @ok_rows{@rows} = (1) x @rows;
    }

    # These were all possible rows, now we need to make sure they
    # match the template mask provided. Use Perl's regexp engine to do the
    # heavy lifting for us.
    my $mask_re = ($template =~ s/\./[.]/gr); # Quote existing periods
    $mask_re =~ s/\?/[#.]/g;                  # Question marks as wildcards

    my $re = qr/^$mask_re$/;

    my @valid = grep { /$re/ } keys %ok_rows;

    if (G_DEBUG_MASK) {
        my @invalid = grep { ! (/$re/) } keys %ok_rows;

        say "These entries were flagged as invalid:";
        foreach (sort @invalid) {
            say BRIGHT_BLUE, "\t$template";
            say RESET, "\t$_";
        }

        say "These entries were flagged as OK!";
        foreach (sort @valid) {
            say BRIGHT_BLUE, "\t$template";
            say BRIGHT_GREEN, "\t$_";
        }

        say RESET;
    }

    return @valid;
}

# Generates all possible rows of same length as $template, with consecutive
# runs of springs in the rows of part lengths gives by @partlens and with
# start/end padding as specified.
sub generate_rows_with_padding($pad_len, $template, @partlens)
{
    my @startlens; # Fixed at beginning
    my @endlens = @partlens; # Fixed at end
    my $maxlen = length ($template) - $pad_len;
    my $padding = '.' x $pad_len;

    my @rows;

    my $cur_len = shift @endlens;
    while ($cur_len) {
        # fix the end bounds
        my $start = join('.', map { '#' x $_ } @startlens);
        my $end   = join('.', map { '#' x $_ } @endlens);

        # ensure these are broken off from mid
        $start = "$start." if $start;
        $end = ".$end" if $end;

        my $piece = '#' x $cur_len;

        my $len_remaining = $maxlen - (length "$start$end");

        if (G_DEBUG_ROWS) {
            say "Can try up to $len_remaining positions to fit $cur_len into [$start ... $end] / [", length $start, ",", length $end, "]";
            say "\tlengths: rem: $len_remaining, max $maxlen, start+end, ", (length "$start$end");
        }

        for (my $offset = 0; $offset <= ($len_remaining - $cur_len); $offset++) {
            my $pad = '.' x $offset;
            my $endpad = '.' x ($len_remaining - $cur_len - $offset);
            my $row = "$pad$piece$endpad";

            # start and end already include stand-off padding
            $row = "$start$row" if $start;
            $row = "$row$end" if $end;

            # but need to account for potential non-use at far ends
            for (my $p = 0; $p <= $pad_len; $p++) {
                my $startpad = '.' x $p;
                my $endpad = '.' x ($pad_len - $p);
                push @rows, "$startpad$row$endpad";
            }
        }

        push @startlens, $cur_len;
        $cur_len = shift @endlens;
    }

    return @rows;
}
