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
use constant G_DEBUG_RESULTS => 1;
use constant G_DEBUG_COMBINATORICS => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

open my $input_fh, '<', (shift @ARGV // $input_name);

chomp(my @lines = <$input_fh>);

my @rows = map {
    my ($r, $crc) = split(' ', $_);
#   $r = join('?', ($r) x 5);
#   $crc = join(',', ($crc) x 5);

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

# counts all cases starting at template until there is no more room
sub count_sub_case($partlen, $template, $level, @rest)
{
    state $cache; # for memoization / DP
    local $" = ",";

    ll($level, "[$partlen;@rest]: $template");

    if (!$template and !@rest) {
        fi("none", 1);
        return 1;
    }

    unless ($template) {
        fi("still input", 0);
        return 0;
    }

    if ($partlen && !$template) {
        fi("still parts", 0);
        return 0;
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
        # FIXME: In theory no matching is needed here ???
        unless ($template) {
            fi("ran out of input skipping empty", 0);
            return 0;
        }
    }

    # We have an input to match
    if ($cur_char eq '#') {
        # if we can't match here, we're done
        unless ($template =~ $re) {
            fi("match needed on $template but failed", 0);
            return 0;
        }

        # we've matched, consume the input
        $template = substr ($template, $partlen + (@rest ? 1 : 0));

        # if we *can* match here, see if there's later parts or input.
        if (!@rest && $template =~ /^[.?]*$/) {
            fi("more filler input to consume, no more parts", 1);
            return 1;
        }
        if (!@rest && $template) {
            fi("more substantive input to consume, but no more parts", 0);
            return 0;
        }
        if (@rest && !$template) {
            fi("more parts but no more input", 0);
            return 0;
        }

        # potential for this to be a match, if we match later as well
        my ($next_part, @next_rest) = @rest;
        select()->flush();
#       die "$template" unless $next_part;
        fi ("prospective match, delegating", 1);
        my $count = count_sub_case($next_part, $template, $level + 1, @next_rest);
        ll($level, "[$partlen;@rest]: $template");
        fi ("completed match, result", $count);
        return $count;
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
        return $count;
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
