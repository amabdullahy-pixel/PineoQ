#!/usr/bin/perl
# Fix the selftest function in implement.pl.
# The bug: "for my $c (@chain, 'T-IMPL-002...')" is parsed as a statement modifier.
# Fix: replace the entire selftest function with a corrected version.
use strict; use warnings;
my $f = $ARGV[0];
open my $fh, "<:raw", $f or die $!;
local $/; my $t = <$fh>; close $fh;

# Find the selftest function and replace it.
# Use a marker-based approach to avoid regex quoting issues.
my $start_marker = "sub selftest {";
my $end_marker = "    return \$fail ? 1 : 0;\n}";

my $start_idx = index($t, $start_marker);
die "selftest start not found\n" if $start_idx < 0;
my $end_idx = index($t, $end_marker, $start_idx);
die "selftest end not found\n" if $end_idx < 0;
$end_idx += length($end_marker);

my $new_func = <<'NEWFUNC';
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };
    my $plan = _slurp("C:/Users/Kabir/OneDrive/Documents/PineScript.6/pine-agent/implementation/phase9_authoritative_plan.yaml");

    my $r = run_pipeline($plan);
    $ok->($r->{implementation_status} eq 'COMPLETED', 'T-IMPL-001 status COMPLETED');
    $ok->($r->{implementation_allowed} && $r->{next_stage} eq 'POST_VERIFICATION', 'T-IMPL-001b gates open');

    my $ok_id = sub { return defined $_[0] && $_[0] =~ /^(req|rout|form|pre|feas|plan|impl)-[0-9a-f]{12}$/ };
    my @chain = map { $r->{$_} } qw(request_id approved_routing_id formalization_id verification_id feasibility_id planning_id implementation_id);
    my $chain_ok = 1;
    for my $c (@chain) {
        unless ($ok_id->($c)) { $chain_ok = 0; last; }
    }
    $ok->($chain_ok, 'T-IMPL-002 identity chain well-formed');

    $ok->(scalar @{ $r->{checks} } == 9, 'T-IMPL-003 9 checks present');
    my $no_fail = 1;
    for my $ck (@{ $r->{checks} }) {
        if (($ck->{verdict}//'') eq 'fail') { $no_fail = 0; last; }
    }
    $ok->($no_fail, 'T-IMPL-003b no check failed');

    $ok->(!@{ $r->{blockers} }, 'T-IMPL-004 no blockers');

    $ok->($r->{compile_status} eq 'UNKNOWN_REQUIRES_EXTERNAL_VALIDATION', 'T-IMPL-005 compile status honest');

    my $y = result_to_yaml($r);
    my $pine_free = 1;
    for my $tok ('//@version', 'indicator(', 'strategy(', 'library(', 'ta.sma', 'ta.rsi') {
        $pine_free = 0 if index($y, $tok) >= 0;
    }
    $ok->($pine_free, 'T-IMPL-006 no Pine constructs in result contract');

    my $r2 = run_pipeline($plan);
    $ok->($r->{implementation_id} eq $r2->{implementation_id}, 'T-IMPL-007 implementation_id stable');

    my $y2 = result_to_yaml($r2);
    $ok->($y eq $y2, 'T-IMPL-008 byte-identical result');

    print "SELFTEST: $pass passed, $fail failed\n";
    print "All TEST-IMPL-001..008 acceptance cases pass (implementation contract v1.1).\n" if !$fail;
    return $fail ? 1 : 0;
}
NEWFUNC

substr($t, $start_idx, $end_idx - $start_idx) = $new_func;

open my $o, ">:raw", $f or die $!;
print $o $t; close $o;
print "fixed\n";