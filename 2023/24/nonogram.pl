#!/usr/bin/env perl

# AoC 2023 - Puzzle 24 (Day 11 Part 2)
# This problem requires to read in an input file that ultimately
# lists information about a nonogram-like set of info on a row to validate.
# Since the input is bigger, brute force is no longer an option. People seem
# to suggest dynamic programming will work.
# See the Advent of Code website.

use 5.038;
use autodie;

use List::Util qw(sum);

my $input_name = '../23/input';
$" = ', '; # For arrays interpolated into strings

# Globals
my %cache; # for memoization / DP

# Code (Aux subs below)

open my $input_fh, '<', (shift @ARGV // $input_name);

say sum map {
    chomp;
    my ($r, $crc) = split(' ', $_);
    count_sub_case(
        join('?', ($r) x 5),
        (split(',', $crc)) x 5
    );
} <$input_fh>;

# Aux subs

sub get_cached($key)
{
    return $cache{$key} if exists $cache{$key};
    return;
}

sub set_cached($key, $value)
{
    return $cache{$key} = $value;
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

    # be strict on cases. we look at one char and match or not.
    my $cur_char = substr ($template, 0, 1, ''); # changes $template
    die "unhandled char $cur_char"
        unless $cur_char eq '#' or $cur_char eq '?';

    # base case for both ? and # handling (regexp treats them the same)
    my $count;
    $count //= 0 unless $template =~ build_re($partlen, !!@rest);
    $count //= 1 unless @rest; # only undef if regexp did match

    # if we've not matched so far, consume rest of the input and keep looking
    # by coincidence the math works out to cancel out offsets naturally
    $count //= count_sub_case(substr ($template, $partlen), @rest);

    # check for alt. reality in wildcard case
    $count += count_sub_case($template, $partlen, @rest) if $cur_char eq '?';

    return set_cached($key, $count);
}
