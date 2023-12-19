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

# Config
use constant G_DEBUG_INPUT => 0;

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
        push $preds{$false_node->{name}}->@*, $last_node->{name}.',f';

        $last_node = $false_node;
    }
}

#say j \%nodes;

# Now that we have graph and predecessors list built, work backwards from
# Accept state to see what numbers could have led to each state.

my @accepts = $preds{A}->@*;

use DDP max_depth => 1;

for my $acc (@accepts) {
    my %ranges = ( map { ($_ => [0, 4000]) } qw(x m a s));

    my %res = constrain_range_to_node($acc, %ranges);
#   say "for $acc: ";
#   p %res;
}

dump_dot();

# Aux subs

# Takes the x/m/a/s range in %ranges and constrains them
# based on all nodes reachable through $pred. Returns the constrained
# range
sub constrain_range_to_node($pred, %ranges)
{
    my $n = node(substr $pred, 0, -2); # remove last 2 chars to find name
    my $edge = substr $pred, -1;       # last char

    if ($edge eq 't') {
        # only got here if cond was true, so whatever cond wanted must
        # be in range
    } else {
    }

    return %ranges;
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
        } elsif ($k eq 'A' or $k eq 'R') {
            say <<~END;
                "$k"
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

