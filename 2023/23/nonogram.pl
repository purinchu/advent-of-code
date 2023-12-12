#!/usr/bin/env perl

# AoC 2023 - Puzzle 23 (Day 11 Part 1)
# This problem requires to read in an input file that ultimately
# lists information about a nonogram-like set of info on a row to validate.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use Math::BigInt;
use List::Util qw(min max sum reduce none);
use Mojo::JSON qw(j);
use POSIX qw(ceil);
use Term::ANSIColor qw(:constants);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_ROWS => 0;
use constant G_DEBUG_MASK => 0;
use constant G_DEBUG_RESULTS => 0;
use constant G_DEBUG_COMBINATORICS => 0;

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

    if (G_DEBUG_RESULTS) {
        print sprintf("%-${maxmask}s: ", $template), scalar @valid, " options for ";
        say "[@partlens]";
    }
}

say $sum;

# Aux subs

sub factorial($n)
{
    my $ident = 1;
    $ident *= $n-- while $n > 1;
    return $ident;
}

sub fix_carry($maxlen, $extra_room, @subparts)
{
    my $idx = 0; # least-significant
    my @p = @subparts; # defensive copy

    # stop before last (most-significant) index reached
    while($idx < $#p) {
        if ($p[$idx] > $extra_room) {
            $p[$idx + 1]++;

            # reset... can't be zero because subpart must exist
            @p[0..$idx] = (1) x ($idx + 1);
        }

        $idx++;
    }

    return @p;
}

sub generate_all_options($maxlen, @partlens)
{
    my $partssum = sum @partlens;
    my $extra_room = $maxlen - $partssum - (@partlens - 1) + 1;
    my @subparts = (1) x (@partlens - 1);
    my @opts;

    # make all possible interiors. We'll then 'float' these into any
    # begin/end padding later
    if (@subparts) {
        while($subparts[$#subparts] <= $extra_room) {
            push @opts, [@subparts];
            $subparts[0]++;
            @subparts = fix_carry($maxlen, $extra_room, @subparts);
        }

        # remove impossible candidates
        @opts = grep { none { $_ == 0 } $_->@* } @opts;
        @opts = grep { (sum ($_->@*) + sum @partlens) <= $maxlen } @opts;
    }

    my @results;

    # turn generated interstitial lengths into candidate strings
    for my $opt (@opts) {
        my $total = $partssum + sum $opt->@*;

        # handle all possibilities of start/end padding for floating parts
        for (my $pad = 0; $pad <= ($maxlen - $total); $pad++) {
            my $str = '.' x $pad;
            $str .= '#' x $partlens[0];

            for (my $idx = 1; $idx < @partlens; $idx++) {
                $str .= '.' x $opt->[$idx - 1];
                $str .= '#' x $partlens[$idx];
            }

            $str .= '.' x ($maxlen - $total - $pad);

            push @results, $str;
        }
    }

    return @results;
}

# Generates all potentially-valid rows that meet restrictions of the
# template
sub generate_valid_rows($template, @partlens)
{
    my $maxlen = length $template;

    my @rows = generate_all_options($maxlen, @partlens);

    if (G_DEBUG_COMBINATORICS) {
        my $num_opts = $maxlen - sum(@partlens) + 1;
        my $num_parts = scalar @partlens;
        my $num_combinations = factorial($num_opts) / (factorial($num_parts) * factorial($num_opts - $num_parts));
        my $num_made = scalar @rows;
        say "$num_made generated for $template / @partlens";
        say "In theory, there should be $num_combinations options...";
        die "Didn't generate all possibilities for $template! Made $num_made vice $num_combinations!"
            unless $num_made == $num_combinations;
    }

    # These were all possible rows, now we need to make sure they
    # match the template mask provided. Use Perl's regexp engine to do the
    # heavy lifting for us.
    my $mask_re = ($template =~ s/\./[.]/gr); # Quote existing periods
    $mask_re =~ s/\?/[#.]/g;                  # Question marks as wildcards

    my $re = qr/^$mask_re$/;

    my @valid = grep { /$re/ } @rows;

    if (G_DEBUG_MASK) {
        my @invalid = grep { ! (/$re/) } @rows;

        say "======================================";
        say BRIGHT_YELLOW, $template, RED, " @partlens", RESET;
        say BRIGHT_YELLOW, (scalar @rows), " unique combinations:", RESET;

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
