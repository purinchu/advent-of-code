#!/usr/bin/env perl

# AoC 2023 - Puzzle 39
# This problem requires to read in an input file that ultimately
# lists information about comms modules that send pulses
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';

use List::Util qw(any min max sum reduce);
use JSON;
use Storable qw(dclone);
use Getopt::Long qw(:config auto_version auto_help);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_EV => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

my %modules; # broadcaster, button, flip-flop, inverters, conjunctors
my @events;  # event loop

# Code (Aux subs below)

my $max_cycles = 1000; # stop after this many cycles
my $watched;           # node name to watch
my $spam_msgs;         # output every watched message in/out

GetOptions(
    "cycles|c=i"   => \$max_cycles,
    "watch|w=s"    => \$watched,
    "spam|s"       => \$spam_msgs,
)
    or die "Error reading command line options";

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    chomp(my @lines = <$input_fh>);

    %modules = load_input(@lines);
};

die "Unknown watch node $watched"
    if $watched and !$modules{$watched};
die "Need to know what node to spam for"
    if $spam_msgs and !$watched;

if (G_DEBUG_INPUT) {
    say encode_json \%modules;
}

my $count = 0;
my @tally = (0, 0);

# push button repeatedly
for (1..$max_cycles) {
    push @events, make_event('broadcaster', 'button', 0);
    while (@events) {
        $tally[handle_event(\@events)]++;
    }
}

if (!$watched) {
    say $tally[0] * $tally[1];
} else {
    my $json = JSON->new->pretty;
    say $json->encode($modules{$watched});
}

# Aux subs

sub load_input(@lines)
{
    my %modules;

    for (@lines) {
        my ($mod, $receivers) = split (' -> ');
        my ($type, $name) = split('', $mod, 2);
        my @recv = split(/, */, $receivers);

        if ($mod eq 'broadcaster') {
            $name = $mod;
            $type = 'b';
        }

        $modules{$name} = {
            name => $name,
            out  => [@recv],
            type => $type,
        };

        # 0 = off, 1 = on
        $modules{$name}->{mod_state} = 0 if $type eq '%';

        # potential for untyped output modules? don't want to crash
        # on them doing error checking so give some kind of node to
        # show they're possible
        $modules{$_} //= { name => $_, type => '?' } foreach @recv;
    }

    # conjunction modules need to know who is sending them input to
    # set aside mod_state for them

    for my ($name, $mod) (%modules) {
        for my $recv ($mod->{out}->@*) {
            if ($modules{$recv}->{type} eq '&') {
                # sending to a conjunction module.
                $modules{$recv}->{in} //= { };
                $modules{$recv}->{in}->{$name} = 0; # low pulse
            }
        }
    }

    return %modules;
}

sub make_event($recv, $src, $pulse)
{
    { r => $recv, src => $src, t => $pulse };
}

sub handle_event($events_ref)
{
    state $event_num = 0;
    my $e = shift $events_ref->@*;
    # receiver of event
    my $r = $modules{$e->{r}} or die "no r $e->{r}";

    say "Event: $e->{src} --($e->{t})--> $e->{r}" if G_DEBUG_EV;

    if ($r->{type} eq '%') {
        handle_flop($e, \@events);
    } elsif ($r->{type} eq '&') {
        handle_and($e, \@events);
    } elsif ($r->{type} eq 'b') {
        handle_broadcast($e, \@events);
    }

    if ($watched && $e->{r} eq $watched) {
        my $p = $e->{t};
        say "$event_num: $watched: received $e->{t} from $e->{src}"
            if $spam_msgs;

        # see if a periodic cycle is there
        my $last_ev = $r->{"last_$p"} // 0;
        if ($last_ev) {
            my $this_cycle = $event_num - $last_ev;
            my $last_cycle = $r->{"cycle_$p"} // 0;

            $r->{"cycle_$p"} = $this_cycle;

            if ($last_cycle && $last_cycle != $this_cycle) {
                say "$event_num: $watched: cycle $p went from $last_cycle to $this_cycle!";
            } elsif (!$last_cycle) {
                say "$event_num: $watched: detected cycle of length $this_cycle for $p.";
            }
        }

        $r->{"last_$p"} = $event_num;
    } elsif ($watched && $e->{src} eq $watched) {
        say "$event_num: $watched: sent $e->{t} to $e->{r}"
            if $spam_msgs;
    }

    $event_num++;
    return $e->{t}; # 0 or 1 depending on pulse handled
}

sub send_msgs($from, $pulse, $events_ref)
{
    for my $r ($modules{$from}->{out}->@*) {
        push @$events_ref, make_event($r, $from, $pulse);
    }
}

sub handle_flop($e, $events_ref)
{
    return if $e->{t}; # ignore high pulse

    my $m = $modules{$e->{r}};
    $m->{mod_state} = $m->{mod_state} ? 0 : 1;

    send_msgs($e->{r}, $m->{mod_state}, $events_ref);
}

sub handle_and($e, $events_ref)
{
    my $m = $modules{$e->{r}};
    my $sender = $e->{src};
    $m->{in}->{$sender} = $e->{t};

    # send low if all are 1, otherwise send high
    my $pulse = (any { $_ == 0 } values $m->{in}->%*) ? 1 : 0;
    send_msgs($e->{r}, $pulse, $events_ref);
}

sub handle_broadcast($e, $events_ref)
{
    my $m = $modules{'broadcaster'};
    send_msgs('broadcaster', $e->{t}, $events_ref);
}

=head1 SYNOPSIS

Runs a simulator of flip-flops and conjunction nodes connected in a graph,
potentially including cycles. Uses a simulated event loop to keep things
straight.

Usage: ./pulse.pl [-c NUM] [-s] [-w NODE_NAME] [FILE_NAME]

  -c | --cycles     -> number of cycles to run and then exit. A value based on
                       the number of high/low pulses seen is output.
  -w | --watch      -> switch to a mode where a node is watched and
                       the number of cycles between receiving low pulses is
                       output.
  -s | --spam       -> When watching a node, also output msgs sent/received.

FILE_NAME specifies the network configuration to simulate, and is 'input'
if not specified.

=back
