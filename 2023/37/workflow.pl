#!/usr/bin/env perl

# AoC 2023 - Puzzle 37
# This problem requires to read in an input file that ultimately
# lists information about workflows and parts to evaluate.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use Math::BigInt;
use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);

# Config
use constant G_DEBUG_INPUT => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

my ($workflow, $inputs);

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    local $/ = ""; # go into 'paragraph mode'
    chomp(my @paragraphs = <$input_fh>);
    ($workflow, $inputs) = load_input(@paragraphs);
};

if (G_DEBUG_INPUT) {
    say foreach $workflow->@*;
    say foreach $inputs->@*;
}

my %work_insns;

# build workflow engine
foreach ($workflow->@*) {
    my ($name, $r) = /^([a-z]+)\{([^}]+)}$/;

    # each rule has a condition followed by a destination.
    # but the condition is optional for the last rule in the workflow
    my @rules = split (',', $r);

    my $last_rule = pop @rules; # no condition
    $work_insns{$name} = [ map { [ split(':') ] } @rules ];
    push $work_insns{$name}->@*, [ undef, $last_rule ];
}

my $sum = 0;
foreach ($inputs->@*) {
    s/^.//; s/.$//; # remove leading/trailing {}

    $sum += run_workflow($_, \%work_insns);
}

say $sum;

# Aux subs

sub run_workflow($input, $workflows)
{
    my $cur_workflow = 'in';
    my ($x, $m, $a, $s) =
        map { int }
        map { s/^..//; $_ } # remove label and =
        split (',', $input);

    my %val = (x => $x, m => $m, a => $a, s => $s);

    while (1) {
        my $w = $workflows->{$cur_workflow};
        for my $rule ($w->@*) {
            my ($cond, $action) = $rule->@*;

            my $do_action = !defined $cond;

            # if cond wasn't undef, eval it first
            if (!$do_action) {
                my $var = substr $cond, 0, 1;
                my $op  = substr $cond, 1, 1;
                my $value = substr $cond, 2;

                if ($op eq '>') {
                    $do_action = ($val{$var} > $value);
                } elsif ($op eq '<') {
                    $do_action = ($val{$var} < $value);
                } else {
                    die "unhandled op $op";
                }
            }

            if ($do_action) {
                return sum ($x, $m, $a, $s) if $action eq 'A';
                return 0 if $action eq 'R';
                $cur_workflow = $action;
                last;
            }
        }
    }
}

sub load_input(@paras)
{
    # should be two paragraphs for this exercise
    s,\n+$,, foreach @paras; # remove any stray ending newlines

    my @workflows = split(/\n+/, $paras[0]);
    my @inputs    = split(/\n+/, $paras[1]);

    return (\@workflows, \@inputs);
}
