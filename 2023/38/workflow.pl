#!/usr/bin/env perl

# AoC 2023 - Puzzle 38
# This problem requires to read in an input file that ultimately
# lists information about workflows and parts to evaluate.
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';
#no warnings 'experimental::for_list';

use List::Util qw(min max sum reduce);
use Mojo::JSON qw(j);
use Storable qw(dclone);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_DOT => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

# Code (Aux subs below)

my ($workflow);

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    local $/ = ""; # go into 'paragraph mode'
    chomp(my @paragraphs = <$input_fh>);

    # second input not needed for part 2 / puzzle 38
    ($workflow, undef) = load_input(@paragraphs);
};

if (G_DEBUG_INPUT) {
    say foreach $workflow->@*;
}

# workflow is stored as a graph. nodes contain a condition to run, which may be
# undef (for true). Each node that isn't A/R has exactly 2 outgoing edges to
# either the next step in a workflow, or the start of a different workflow.
# Edges are stored with the node, not as a separate array.
# 'A' state is accept, 'R' state is reject.

my %nodes;
my %preds;

# build workflow engine
foreach ($workflow->@*) {
    my ($name, $r) = /^([a-z]+)\{([^}]+)}$/;

    # each rule has a condition followed by a destination.
    # but the condition is optional for the last rule in the workflow
    my @rules = split (',', $r);

    my $last_node = node("$name/0");

    # after the unconditional first rule, build condition-based edges to the
    # final state in the workflow
    for my $idx (1..@rules) {
        my $rule = $rules[$idx - 1];
        my ($cond, $dest) = split(':', $rule);

        # handle final rule w/out condition
        ($dest, $cond) = ($cond, $dest) unless $dest;
        $dest = "$dest/0" unless $dest eq 'A' or $dest eq 'R';

        my ($true_node, $false_node);

        $true_node = node($dest);

        if (defined $cond) {
            $false_node = node("$name/$idx");
        } else {
            $false_node = $true_node;
        }

        $last_node->{cond} = $cond;
        $last_node->{t}    = $true_node;
        $last_node->{f}    = $false_node;

        # add backedges for tracing
        $preds{$true_node->{name}}  //= [ ];
        $preds{$false_node->{name}} //= [ ];
        push $preds{$true_node->{name}}->@* , $last_node->{name}.',t';
        push $preds{$false_node->{name}}->@*, $last_node->{name}.',f'
            if defined $cond; # can only fail condition if it's present

        $last_node = $false_node;
    }
}

if (G_DEBUG_DOT) {
    dump_dot();
    exit 0;
}

# Now that we have graph and predecessors list built, work backwards from
# Accept state to see what numbers could have led to each state.

my %ranges = map { ($_ => [1, 4000]) } qw(x m a s);

my $sum = 0;

for my $out (trace_forwards(\%ranges, 'in/0', 'in/0')) {
    $sum += reduce { $a * $b }
            map { ($_->[1] - $_->[0] + 1) }
            values $out->%*;
}

say $sum;

# Aux subs

sub trace_forwards($ranges, $node_name, $full)
{
    my $n = node($node_name);

    return $ranges if $n->{name} eq 'A';
    return if $n->{name} eq 'R';

    return trace_forwards($ranges, $n->{t}->{name}, "$full -> $n->{t}->{name}")
        unless defined $n->{cond};

    # we have a condition. apply it and subdivide to see what happens
    my ($var, $op, $value) = split('', $n->{cond}, 3);

    # first pretend condition was met
    my $new_range = dclone $ranges;
    if ($op eq '>') {
        $new_range->{$var}->[0] = max($new_range->{$var}->[0], $value + 1);
    } else {
        $new_range->{$var}->[1] = min($new_range->{$var}->[1], $value - 1);
    }

    my @list = trace_forwards($new_range, $n->{t}->{name}, "$full -> $n->{t}->{name}");

    # now pretend the condition failed
    $new_range = dclone $ranges;
    if ($op eq '>') {
        # <=
        $new_range->{$var}->[1] = min($new_range->{$var}->[1], $value);
    } else {
        # >=
        $new_range->{$var}->[0] = max($new_range->{$var}->[0], $value);
    }

    push @list, trace_forwards($new_range, $n->{f}->{name}, "$full -> $n->{f}->{name}");

    return @list;
}

sub node($name)
{
    if (!exists $nodes{$name}) {
        $nodes{$name} = {
            name => $name,
            cond => undef,
        };
    }

    return $nodes{$name};
}

sub load_input(@paras)
{
    # should be two paragraphs for this exercise
    s,\n+$,, foreach @paras; # remove any stray ending newlines

    my @workflows = split(/\n+/, $paras[0]);
    my @inputs    = split(/\n+/, $paras[1]);

    return (\@workflows, \@inputs);
}

sub dump_dot
{
    say <<~END;
    digraph workflow {
        label="Workflows"
        graph [ fontname="Noto Sans" ]
        node  [ fontname="Noto Sans" ]
        edge  [ fontname="Noto Sans" ]
    END

    for my ($k, $v) (%nodes) {
        if (defined $v->{cond}) {
            my $t_dest = $v->{t}->{name};
            my $cond   = $v->{cond};
            my $f_dest = $v->{f}->{name};

            say <<~END;
                "$k"
                "$k" -> "$t_dest" [ label = "$cond" ]
                "$k" -> "$f_dest" [ label = "!$cond" ]
            END
        } elsif ($k eq 'A') {
            say <<~END;
                "$k" [shape=doublecircle style=filled fillcolor=green]
            END
        } elsif ($k eq 'R') {
            say <<~END;
                "$k" [shape=doubleoctagon style=filled fillcolor=yellow]
            END
        } else {
            # final rule in workflow
            my $dest = $v->{t}->{name};
            say <<~END;
                "$k" -> "$dest"
            END
        }
    }

    say "}";
}
