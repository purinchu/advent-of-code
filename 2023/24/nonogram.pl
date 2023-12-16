#!/usr/bin/env perl

# AoC 2023 - Puzzle 24 (Day 11 Part 2)
# This problem requires to read in an input file that ultimately
# lists information about a nonogram-like set of info on a row to validate.
# Since the input is bigger, brute force is no longer an option. People seem
# to suggest dynamic programming will work.
# See the Advent of Code website.

use 5.038;
use autodie;

my $input_name = '../23/input';
$" = ', '; # For arrays interpolated into strings

# Globals
my %cache; # for memoization / DP
my %cache_lru;
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

my $sum = 0;
for my $row (@rows) {
    my ($template, @partlens) = $row->@*;
    my $count = count_valid_rows($template, @partlens);
    $sum += $count;
}

say $sum;

# Aux subs

sub get_cached($key)
{
    $cache_attempts++;
    if (exists $cache{$key}) {
        $cache_hits++;
        $cache_lru{$key} = $cache_attempts;
        return $cache{$key};
    }

    return;
}

sub set_cached($key, $value)
{
    $cache_inserts++;
    $cache{$key} = $value;
    $cache_lru{$key} = $cache_attempts;
    if (%cache > 6000) {
        my @sorted_keys =
            map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, $cache_lru{$_} ]}
            keys %cache_lru;
        splice(@sorted_keys, 1000); # remove 1000 old entries
        delete @cache{@sorted_keys};
        delete @cache_lru{@sorted_keys};
    }
    return $value;
}

sub build_re($partlen, $in_middle)
{
    # my input has part nums from 1-15. RE looks for 0-14 since first # is consumed
    # by time it's called.
    #
    # match for end and middle match, resp
    state @re_cache = map { (qr/^[#?]{$_}[.?]*$/an, qr/^[#?]{$_}[.?]/an) } 0..14;

    return $re_cache[($partlen - 1) * 2 + !!$in_middle];
}

# counts all cases starting at template until there is no more room
sub count_sub_case($template, $partlen, @rest)
{
    my $key = join(',', $template, $partlen, @rest);

    my $result = get_cached($key);
    return $result if defined $result;

    $template =~ s/^[.]*//; # skip leading '.'
    return set_cached($key, 0) unless $template;

    # be strict on cases. we look at one char and that's it...
    my $cur_char = substr ($template, 0, 1, ''); # changes $template

    # We have an input to match
    if ($cur_char eq '#') {
        # last subsegment doesn't need '.'
        my $re = build_re($partlen, !!@rest);

        # if we can't match here, we're done
        return set_cached($key, 0) unless $template =~ $re;

        # if we did match without remaining parts, the regexp confirmed the match
        return set_cached($key, 1) if !@rest;

        # we've matched so far, consume rest of the input and keep looking
        # NB deliberate missed second param in recursion for destructuring
        return set_cached($key, count_sub_case(substr ($template, $partlen), @rest));
    } elsif ($cur_char eq '?') {
        # combine both paths (# or .) by calling cur path again using both
        # possibilities. with . we just keep going rather than add it in

        my $count =
            count_sub_case("#$template", $partlen, @rest) +
            count_sub_case(  $template , $partlen, @rest);

        return set_cached($key, $count);
    } else {
        die "unhandled char $cur_char";
    }
    die "should not get here";
}

sub count_valid_rows($template, @partlens)
{
    return count_sub_case($template, @partlens);
}
