#!/usr/bin/env perl

# AoC 2023 - Puzzle 24 (Day 11 Part 2)
# This problem requires to read in an input file that ultimately
# lists information about a nonogram-like set of info on a row to validate.
# Since the input is bigger, brute force is no longer an option. People seem
# to suggest dynamic programming will work.
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
use constant G_DEBUG_CACHE_STATS => 1;
use constant G_DEBUG_COMBINATORICS => 0;

my $input_name = '../23/input';
$" = ', '; # For arrays interpolated into strings

# Globals
my %cache; # for memoization / DP
my $cache_hits = 0;
my $cache_attempts = 0;
my $cache_inserts = 0;

# Code (Aux subs below)

open my $input_fh, '<', (shift @ARGV // $input_name);

chomp(my @lines = <$input_fh>);

my @rows = map {
    my ($r, $crc) = split(' ', $_);
    $r = join('?', ($r) x 5);
    $crc = join(',', ($crc) x 5);

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
    my $count = count_valid_rows($template, @partlens);
    $sum += $count;

    if (G_DEBUG_RESULTS) {
        print sprintf("%-${maxmask}s: ", $template), " $count options for ";
        say "[@partlens]";
    }
}

say $sum;

if (G_DEBUG_CACHE_STATS) {
    say "Cache attempts: $cache_attempts";
    say "Cache inserts: $cache_inserts";
    say "Cache size: ", scalar keys %cache;
    say "Cache hits: $cache_hits";
    say "Hit rate: ", sprintf("%0.3f", 100.0 * $cache_hits / $cache_attempts);
}

# Aux subs

sub ll($level, $msg) {
    return unless G_DEBUG_ROWS;
    my $indent = (' ') x $level;
    return if $level > 80;
    print "$indent$msg -> ";
}

sub fi($char, $result) {
    return unless G_DEBUG_ROWS;
    say "$char ($result)";
}

sub get_cached($key)
{
    $cache_attempts++;
    if (exists $cache{$key}) {
        $cache_hits++;
        return $cache{$key};
    }

    return;
}

sub set_cached($key, $value)
{
    $cache_inserts++;
    $cache{$key} = $value;
    return $value;
}

# counts all cases starting at template until there is no more room
sub count_sub_case($partlen, $template, $level, @rest)
{
    my $key = join(',', $template, $partlen, @rest);

    ll($level, "[$partlen;@rest]: $template");

    my $result = get_cached($key);
    return $result if defined $result;

    if (!$template and !@rest) {
        fi("none", 1);
        return set_cached($key, 1);
    }

    unless ($template) {
        fi("still input", 0);
        return set_cached($key, 0);
    }

    if ($partlen && !$template) {
        fi("still parts", 0);
        return set_cached($key, 0);
    }

    # last subsegment doesn't need '.' but does need to end the string
    my $re_str = ('[#?]') x $partlen;
    $re_str .= '[.?]' if @rest; # ensure part actually ends

    my $re = qr/^$re_str/;

    # be strict on cases. we look at one char and that's it...
    # this reads but does not consume input from template
    my $cur_char = substr ($template, 0, 1);

    while ($cur_char eq '.') {
        # skip parts of template that can't consume input

        # consume input we peeked at earlier
        substr ($template, 0, 1, '');

        $cur_char = substr ($template, 0, 1);

        # if no template to consume input against, finish up
        unless ($template) {
            fi("ran out of input skipping empty", 0);
            return set_cached($key, 0);
        }
    }

    # We have an input to match
    if ($cur_char eq '#') {
        # if we can't match here, we're done
        unless ($template =~ $re) {
            fi("match needed on $template but failed", 0);
            return set_cached($key, 0);
        }

        # we've matched, consume the input
        $template = substr ($template, $partlen + (@rest ? 1 : 0));

        # if we *can* match here, see if there's later parts or input.
        if (!@rest && $template =~ /^[.?]*$/) {
            fi("more filler input to consume, no more parts", 1);
            return set_cached($key, 1);
        }
        if (!@rest && $template) {
            fi("more substantive input to consume, but no more parts", 0);
            return set_cached($key, 0);
        }
        if (@rest && !$template) {
            fi("more parts but no more input", 0);
            return set_cached($key, 0);
        }

        # potential for this to be a match, if we match later as well
        my ($next_part, @next_rest) = @rest;

        fi ("prospective match, delegating", 1);
        my $count = count_sub_case($next_part, $template, $level + 1, @next_rest);

        ll($level, "[$partlen;@rest]: $template");
        fi ("completed match, result", $count);

        return set_cached($key, $count);
    } elsif ($cur_char eq '?') {
        # combine both paths by calling cur path again using both possibilities
        my $templ_filled = $template;
        my $templ_empty = $template;
        substr($templ_filled, 0, 1) = '#'; # replace '?' with '#'
        substr($templ_empty, 0, 1) = '.'; # replace '?' with '.'

        fi ("wildcard, delegating", 1);
        my $count = count_sub_case($partlen, $templ_filled, $level + 1, @rest)
            + count_sub_case($partlen, $templ_empty, $level + 1, @rest);

        ll($level, "[$partlen;@rest]: $template");
        fi ("completed wildcard", $count);

        return set_cached($key, $count);
    } else {
        die "unhandled char $cur_char";
    }
    die "should not get here";
}

sub count_valid_rows($template, @partlens)
{
    my ($part, @rest) = @partlens;
    return count_sub_case($part, $template, 0, @rest);
}
