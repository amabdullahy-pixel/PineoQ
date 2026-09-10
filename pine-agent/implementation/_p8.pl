# ---------------------------------------------------------------------------
# selftest - Phase 9 acceptance suite (TEST-IMPL-001..008)
# ---------------------------------------------------------------------------
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
    for my $c (@chain) { unless ($ok_id->($c)) { $chain_ok = 0; last; } }
    $ok->($chain_ok, 'T-IMPL-002 identity chain well-formed');

    $ok->(scalar @{ $r->{checks} } == 9, 'T-IMPL-003 9 checks present');
    $ok->(!grep { $_->{verdict} eq 'fail' } @{ $r->{checks} }, 'T-IMPL-003b no check failed');

    $ok->(!@{ $r->{blockers} }, 'T-IMPL-004 no blockers');

    $ok->($r->{compile_status} eq 'UNKNOWN_REQUIRES_EXTERNAL_VALIDATION', 'T-IMPL-005 compile status honest');

    my $y = result_to_yaml($r);
    my $pine_free = 1;
    for my $tok ('//@version', 'indicator(', 'strategy(', 'library(', 'ta.sma', 'ta.rsi') { $pine_free = 0 if index($y, $tok) >= 0; }
    $ok->($pine_free, 'T-IMPL-006 no Pine constructs in result contract');

    my $r2 = run_pipeline($plan);
    $ok->($r->{implementation_id} eq $r2->{implementation_id}, 'T-IMPL-007 implementation_id stable');

    my $y2 = result_to_yaml($r2);
    $ok->($y eq $y2, 'T-IMPL-008 byte-identical result');

    print "SELFTEST: $pass passed, $fail failed\n";
    print "All TEST-IMPL-001..008 acceptance cases pass (implementation contract v1.1).\n" if !$fail;
    return $fail ? 1 : 0;
}