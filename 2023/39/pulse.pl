#!/usr/bin/env perl

# AoC 2023 - Puzzle 39
# This problem requires to read in an input file that ultimately
# lists information about comms modules that send pulses
# See the Advent of Code website.

use 5.038;
use autodie;
use experimental 'for_list';
#no warnings 'experimental::for_list';

use List::Util qw(any min max sum reduce);
use Mojo::JSON qw(j);
use Storable qw(dclone);

# Config
use constant G_DEBUG_INPUT => 0;
use constant G_DEBUG_EV => 0;

my $input_name = 'input';
$" = ', '; # For arrays interpolated into strings

my %modules; # broadcaster, button, flip-flop, inverters, conjunctors
my @events;  # event loop

# Code (Aux subs below)

do {
    open my $input_fh, '<', (shift @ARGV // $input_name);
    chomp(my @lines = <$input_fh>);

    %modules = load_input(@lines);
};

if (G_DEBUG_INPUT) {
    say j \%modules;
}

my $count = 0;

my @tally = (0, 0);

# push button a 1000 times
for (1..1000) {
    push @events, make_event('broadcaster', 'button', 0);
    while (@events) {
        $tally[handle_event(\@events)]++;
    }
}

say $tally[0] * $tally[1];

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
    my $e = shift $events_ref->@*;
    my $receiver = $modules{$e->{r}} or die "no receiver $e->{r}";

    say "Event: $e->{src} --($e->{t})--> $e->{r}" if G_DEBUG_EV;

    if ($receiver->{type} eq '%') {
        handle_flop($e, \@events);
    } elsif ($receiver->{type} eq '&') {
        handle_and($e, \@events);
    } elsif ($receiver->{type} eq 'b') {
        handle_broadcast($e, \@events);
    }

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
