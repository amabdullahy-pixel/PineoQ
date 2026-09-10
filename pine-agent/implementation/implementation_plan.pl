#!/usr/bin/perl
# ============================================================================
# implementation_plan.pl — Implementation Planning decision engine (pine-agent
# Phase 8)
# ============================================================================
# Core Perl 5, zero non-core dependencies (Digest::SHA, Encode, File::Temp,
# File::Basename are core). Runtime contract identical to router.pl /
# formalize.pl / pre_verify.pl / feasibility.pl.
#
# Inputs : the formalization contract (--contract), the Phase-6 pre result
#          (--pre), and the Phase-7 feasibility result (--feasibility) — all
#          exactly as the upstream engines emit them.
# Output : implementation PLANNING contract (schema v1.1 `planning:` block) +
#          exit code.
#   exit 0  planning_status READY | READY_WITH_WARNINGS
#   exit 2  BLOCKED | INVALID_INPUT
#
# Hard gate: ONLY READY / READY_WITH_WARNINGS set implementation_allowed=true
# and next_stage=IMPLEMENTATION. PARTIALLY_FEASIBLE / NOT_FEASIBLE / BLOCKED /
# INVALID_INPUT feasibility results are never reinterpreted as feasible.
#
# No semantic drift: conditions, formulas, timeframes, repaint classification,
# and feasibility constraints are mirrored VERBATIM; unresolved implementation
# choices become decisions[] (NEEDS_USER_INPUT) with warnings — never silently
# settled.
#
# NO-PINE RULE: this engine plans construction. It never emits Pine.
#
# Determinism: no clock, no randomness, no environment values.
# planning_id = "plan-" + first 12 hex of sha256 over the canonical body
# (see meta/implementation_planning_procedure.md §8).
# ============================================================================
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode);

# scratch accumulators shared with run_checks (reset per run in plan_text)
my ($ARCH, $FLOW, $STATE, $MTF, $SIGA, $DRAWA, $ALERTA, $PERF);
sub r_arch   { $ARCH   ||= []; return $ARCH; }
sub r_flow   { $FLOW   ||= []; return $FLOW; }
sub r_state  { $STATE  ||= []; return $STATE; }
sub r_mtf    { $MTF    ||= []; return $MTF; }
sub r_siga   { $SIGA   ||= []; return $SIGA; }
sub r_drawa  { $DRAWA  ||= []; return $DRAWA; }
sub r_alerta { $ALERTA ||= []; return $ALERTA; }
sub r_perf   { $PERF   ||= []; return $PERF; }

# ---------------------------------------------------------------------------
# tiny YAML-subset parsers (formalization contract: same format feasibility.pl
# parses; pre result: emitted by pre_verify.pl; feasibility result: emitted by
# feasibility.pl)
# ---------------------------------------------------------------------------
sub _unq { my $s = shift; return undef if !defined $s; $s =~ s/^'//; $s =~ s/'$//; $s =~ s/''/'/g; return $s; }

sub _parse_flow_map {
    my ($s) = @_;
    my %out;
    while ($s =~ /\G\s*,?\s*([\w.]+):\s*('(?:[^']|'')*'|[\w.\-]+)/gc) {
        my ($k, $v) = ($1, $2);
        $out{$k} = ($v eq 'null') ? undef : _unq($v);
    }
    return \%out;
}

sub parse_contract {
    my ($text) = @_;
    die "unparseable: empty input\n" if !defined $text || $text !~ /\S/;
    my %c;
    my $get_scalar = sub {
        my ($key, $t) = @_;
        return undef if $t !~ /^\s{2}\Q$key\E:\s*(.*)$/m;
        my $v = $1;
        return undef if $v eq '' || $v eq 'null' || $v eq '~';
        return ($v eq 'true') ? 1 : ($v eq 'false') ? 0 : _unq($v);
    };
    my $get_list_of_maps = sub {
        my ($key, $t) = @_;
        my @out;
        if ($t =~ /^\s{2}\Q$key\E:\s*\[\s*\]\s*$/m) { return \@out; }
        if ($t =~ /^\s{2}\Q$key\E:\s*\[(.+)\]\s*$/m) {
            my $inner = $1;
            while ($inner =~ /\{\s*([^}]*)\}/g) { push @out, _parse_flow_map($1); }
            return \@out;
        }
        if ($t =~ /^\s{2}\Q$key\E:\s*$/m) {
            my $capture = 0;
            my $entry;
            for my $line (split /\r?\n/, $t) {
                if ($line =~ /^\s{2}\Q$key\E:\s*$/) { $capture = 1; next; }
                next unless $capture;
                last if $line =~ /^\S/ || $line =~ /^\s{2}\w+:/;
                if ($line =~ /^\s{4,}-\s+\{(.*)\}\s*$/) { push @out, _parse_flow_map($1); $entry = undef; }
                elsif ($line =~ /^\s{4,}-\s+(\w+):\s*(.*)$/) { $entry = { $1 => _unq($2) // $2 }; push @out, $entry; }
                elsif ($entry && $line =~ /^\s{6}(\w+):\s*(.*)$/) { $entry->{$1} = _unq($2) // $2; }
            }
        }
        return \@out;
    };
    my $get_flow_list = sub {
        my ($key, $t) = @_;
        return [] if $t !~ /^\s{2}\Q$key\E:\s*(.*)$/m;
        my $v = $1;
        return [] if $v =~ /^\[\s*\]$/;
        my @out;
        while ($v =~ /'(?:[^']|'')*'/g) { push @out, _unq($&); }
        return \@out;
    };
    $c{request_id}          = $get_scalar->('request_id', $text);
    $c{approved_routing_id} = $get_scalar->('approved_routing_id', $text);
    $c{formalization_id}    = $get_scalar->('formalization_id', $text);
    $c{request_text}        = $get_scalar->('natural_language_request', $text) // $get_scalar->('normalized_request', $text);
    $c{mtf_flag}            = ($get_scalar->('mtf', $text) // 0) ? 1 : 0;
    $c{repaint_raw}         = $get_scalar->('repaint_risk', $text);
    my $ch_raw = ($text =~ /^\s{4}chart:[ \t]*(.*)$/m) ? $1 : undef;
    $c{tf_chart}            = (!defined $ch_raw || $ch_raw eq 'null' || $ch_raw eq '') ? undef : _unq($ch_raw);
    $c{variables}           = $get_list_of_maps->('variables', $text);
    $c{formulas}            = $get_list_of_maps->('formulas', $text);
    $c{conditions}          = $get_list_of_maps->('boolean_conditions', $text);
    $c{edge_cases}          = $get_list_of_maps->('edge_cases', $text);
    $c{required_data}       = $get_list_of_maps->('required_data', $text);
    $c{source_skills}              = $get_flow_list->('source_skills', $text);
    $c{verification_requirements}  = $get_flow_list->('verification_requirements', $text);
    $c{implementation_constraints} = $get_flow_list->('implementation_constraints', $text);
    die "unparseable: no formalization block\n" unless defined $c{request_id} || $text =~ /formalization/;
    return \%c;
}

sub parse_pre {
    my ($text) = @_;
    die "unparseable: empty input\n" if !defined $text || $text !~ /\S/;
    my %p;
    my $g = sub { my ($k) = @_; my ($v) = $text =~ /^\s{2}\Q$k\E:\s*'([^']*)'/m; return $v; };
    $p{request_id}          = $g->('request_id');
    $p{approved_routing_id} = $g->('approved_routing_id');
    $p{formalization_id}    = $g->('formalization_id');
    $p{verification_id}     = $g->('verification_id');
    $p{result}              = $g->('result');
    my ($nsq) = $text =~ /^\s{2}next_stage:\s*(\S+)/m;
    ($nsq)    = $text =~ /^\s{2}next_stage:\s*'([^']*)'/m unless defined $nsq;
    $p{next_stage}          = $nsq;
    my ($fa) = $text =~ /^\s{2}feasibility_allowed:\s*(true|false)/m;
    $p{feasibility_allowed} = (defined $fa && $fa eq 'true') ? 1 : 0;
    $p{blockers_empty} = ($text =~ /^  blockers: \[\]/m) ? 1 : 0;
    die "unparseable: no pre_verification block\n" unless $text =~ /pre_verification/;
    return \%p;
}

# feasibility result parser: reads the exact emit format of feasibility.pl
# result_to_yaml (quoted 2-space scalars; unquoted next_stage; '[]' empties;
# flow-map list items for warnings/constraints).
sub parse_feas {
    my ($text) = @_;
    die "unparseable: empty input\n" if !defined $text || $text !~ /\S/;
    my %f;
    my $g = sub { my ($k) = @_; my ($v) = $text =~ /^\s{2}\Q$k\E:\s*'([^']*)'/m; return $v; };
    $f{request_id}          = $g->('request_id');
    $f{approved_routing_id} = $g->('approved_routing_id');
    $f{formalization_id}    = $g->('formalization_id');
    $f{verification_id}     = $g->('verification_id');
    $f{feasibility_id}      = $g->('feasibility_id');
    $f{feasibility_status}  = $g->('feasibility_status');
    my ($ipa) = $text =~ /^\s{2}implementation_planning_allowed:\s*(true|false)/m;
    $f{planning_allowed} = (defined $ipa && $ipa eq 'true') ? 1 : 0;
    my ($ns) = $text =~ /^\s{2}next_stage:\s*(\S+)/m;
    ($ns)    = $text =~ /^\s{2}next_stage:\s*'([^']*)'/m unless defined $ns;
    $f{next_stage} = $ns;
    $f{blockers_empty} = ($text =~ /^  blockers: \[\]/m) ? 1 : 0;
    my $section = sub {
        my ($key) = @_;
        my @out;
        my $cap = 0;
        for my $line (split /\r?\n/, $text) {
            if ($line =~ /^  \Q$key\E:\s*$/) { $cap = 1; next; }
            next unless $cap;
            last if $line =~ /^\S/ || $line =~ /^  \w/;
            if ($line =~ /^\s*-\s*\{(.*)\}\s*$/) { push @out, _parse_flow_map($1); }
        }
        return \@out;
    };
    $f{warnings}    = $section->('warnings');
    $f{constraints} = $section->('constraints');
    die "unparseable: no feasibility block\n" unless $text =~ /feasibility/;
    return \%f;
}

# ---------------------------------------------------------------------------
# deterministic module derivation (procedure §5) — none of it invented
# ---------------------------------------------------------------------------
my %RANK = ('M-DATA' => 0, 'M-CALC' => 1, 'M-STATE' => 2, 'M-SIGNAL' => 3,
            'M-DRAW' => 4, 'M-ALERT' => 5, 'M-INTEG' => 6);
my $STATE_RE = qr/\b(cross(?:es)?\s+(?:over|under)|crossover|crossunder|previous|prior|cumulative|accumulat|streak|since)/i;
my $DRAW_RE  = qr/\b(label|line|box|table|plot|bgcolor|fill|shape)/i;
my $LOOP_RE  = qr/\b(for every bar|loop over all|iterate over all|every bar in history|all historical bars)/i;
my %DEF_HOOK = (
    'M-DATA'   => 'data series become available exactly at the declared boundaries (no substitute sources)',
    'M-CALC'   => 'mathematical equivalence to the contract formulas',
    'M-STATE'  => 'state behavior across historical and realtime bars matches the documented execution semantics',
    'M-SIGNAL' => 'condition equivalence to the contract boolean conditions',
    'M-DRAW'   => 'requested outputs present; unrequested outputs absent',
    'M-ALERT'  => 'alerts fire only on the contracted conditions',
    'M-INTEG'  => 'integrated behavior matches the plan; every edge case honored',
);

sub derive_modules {
    my ($c) = @_;
    my @mods;
    my $prose = $c->{request_text} // '';
    my $has_data  = @{ $c->{required_data} || [] } ? 1 : 0;
    my $has_calc  = @{ $c->{formulas} || [] } ? 1 : 0;
    my $has_sig   = @{ $c->{conditions} || [] } ? 1 : 0;
    my $has_state = ($prose =~ $STATE_RE) ? 1 : 0;
    my $has_draw  = ($prose =~ $DRAW_RE)  ? 1 : 0;
    my $has_alert = ($prose =~ /\balert/i) ? 1 : 0;
    my @d_refs    = map { "required_data[$_]" } 1 .. scalar @{ $c->{required_data} || [] };
    my @f_ids     = map { $_->{id} // () } @{ $c->{formulas} || [] };
    my @c_ids     = map { $_->{id} // () } @{ $c->{conditions} || [] };
    my @c_state   = grep { ($_->{condition} // '') =~ $STATE_RE } @{ $c->{conditions} || [] };
    my @e_ids     = map { $_->{id} // () } @{ $c->{edge_cases} || [] };
    my $vr   = $c->{verification_requirements} || [];
    my $vsel = sub { my $re = shift; my @h = grep { /$re/ } @$vr; return \@h; };

    if ($has_data) {
        push @mods, { module_id => 'M-DATA', purpose => 'acquire the declared external data at exactly the request.* boundaries the contract declares',
            inputs => ['required_data entries (mirrored verbatim)'], outputs => ['data series available to calculations'],
            dependencies => [], source_requirements => \@d_refs, verification_requirements => $vsel->('repaint|data|mtf') };
    }
    if ($has_calc) {
        my @deps = $has_data ? ('M-DATA') : ();
        push @mods, { module_id => 'M-CALC', purpose => 'compute the contracted formulas exactly as written (mathematical equivalence)',
            inputs => ['price/data series', 'contract formulas (mirrored verbatim)'], outputs => ['formula result series'],
            dependencies => \@deps, source_requirements => \@f_ids, verification_requirements => $vsel->('math|logic') };
    }
    if ($has_state) {
        my @src  = @c_state ? (map { $_->{id} } @c_state) : ('natural_language_request');
        my @deps = $has_calc ? ('M-CALC') : ();
        push @mods, { module_id => 'M-STATE', purpose => 'maintain the per-bar prior-value / crossover mechanics the contract requires',
            inputs => ['formula/price series'], outputs => ['state series'],
            dependencies => \@deps, source_requirements => \@src, verification_requirements => $vsel->('logic|repaint|edge') };
    }
    if ($has_sig) {
        my @deps; push @deps, 'M-CALC' if $has_calc; push @deps, 'M-STATE' if $has_state;
        push @mods, { module_id => 'M-SIGNAL', purpose => 'evaluate the contracted boolean conditions exactly as written (condition equivalence)',
            inputs => ['formula/state series'], outputs => ['condition results'],
            dependencies => \@deps, source_requirements => \@c_ids, verification_requirements => $vsel->('logic|ambigu') };
    }
    if ($has_draw) {
        push @mods, { module_id => 'M-DRAW', purpose => 'present the outputs the request wording asks for (responsibilities planned; budgets stay UNKNOWN_REQUIRES_VERIFICATION)',
            inputs => ['condition/formula results'], outputs => ['visual outputs'],
            dependencies => $has_sig ? ['M-SIGNAL'] : [], source_requirements => ['natural_language_request'],
            verification_requirements => $vsel->('edge|repaint') };
    }
    if ($has_alert) {
        push @mods, { module_id => 'M-ALERT', purpose => 'fire alerts whose trigger conditions mirror the contract verbatim (timing is user alert-configuration)',
            inputs => ['condition results'], outputs => ['alert events'],
            dependencies => $has_sig ? ['M-SIGNAL'] : [], source_requirements => ['natural_language_request'],
            verification_requirements => $vsel->('repaint|logic') };
    }
    {
        my @others = map { $_->{module_id} } @mods;
        push @mods, { module_id => 'M-INTEG', purpose => 'wire modules, enforce the Pine v6 target, and honor every edge case and implementation constraint',
            inputs => ['all module outputs'], outputs => ['integrated behavior (planned only)'],
            dependencies => \@others, source_requirements => [ @e_ids ? @e_ids : (), 'pine_version_target=6' ],
            verification_requirements => [@$vr] };
    }
    return \@mods;
}

sub graph_find_cycle {
    my ($mods) = @_;
    my %deps = map { $_->{module_id} => [ @{ $_->{dependencies} || [] } ] } @$mods;
    my %color; my @path; my $found;
    my $visit;
    $visit = sub {
        my ($n) = @_;
        return if $found;
        $color{$n} = 1; push @path, $n;
        for my $d (@{ $deps{$n} || [] }) {
            next unless exists $deps{$d};
            if (($color{$d} // 0) == 1) {
                my ($i) = grep { $path[$_] eq $d } 0 .. $#path;
                $found = [ @path[$i .. $#path] ];
                return;
            }
            $visit->($d) if ($color{$d} // 0) == 0;
            return if $found;
        }
        pop @path; $color{$n} = 2;
    };
    $visit->($_) for sort keys %deps;
    return $found;
}

sub graph_find_missing {
    my ($mods) = @_;
    my %ids = map { $_->{module_id} => 1 } @$mods;
    my @missing;
    for my $m (@$mods) {
        for my $d (@{ $m->{dependencies} || [] }) { push @missing, "$m->{module_id}->$d" unless $ids{$d}; }
    }
    return \@missing;
}

sub topo_order {
    my ($mods) = @_;
    my %deps = map { $_->{module_id} => [ @{ $_->{dependencies} || [] } ] } @$mods;
    my %done; my @order;
    while (@order < scalar(keys %deps)) {
        my @ready = sort { ($RANK{$a} // 99) <=> ($RANK{$b} // 99) || $a cmp $b }
                    grep { !$done{$_} && !grep { !$done{$_} } @{ $deps{$_} || [] } } keys %deps;
        last unless @ready;
        $done{ $ready[0] } = 1;
        push @order, $ready[0];
    }
    return \@order;
}

# ---------------------------------------------------------------------------
# the 14 checks — each appends findings and (for IP04..IP12) plan sections
# finding = { check_id, severity, code, message, refs[], reqs[] }
# ---------------------------------------------------------------------------
my @DOMAINS = (
    ['IP01', 'identity_traceability'],    ['IP02', 'planning_handoff_gate'],
    ['IP03', 'requirements_coverage'],    ['IP04', 'architecture'],
    ['IP05', 'module_decomposition'],     ['IP06', 'data_flow'],
    ['IP07', 'state_architecture'],       ['IP08', 'mtf_architecture'],
    ['IP09', 'signal_architecture'],      ['IP10', 'drawing_architecture'],
    ['IP11', 'alert_architecture'],       ['IP12', 'performance_plan'],
    ['IP13', 'dependency_graph'],         ['IP14', 'verification_hooks'],
);

sub run_checks {
    my ($c, $p, $fe) = @_;
    my @F;
    my $add = sub {
        my ($cid, $sev, $code, $msg, $refs, $reqs) = @_;
        push @F, { check_id => $cid, severity => $sev, code => $code, message => $msg,
                   refs => $refs || [], reqs => $reqs || [] };
    };
    my $mods = defined $c ? derive_modules($c) : [];

    # --- IP01 identity chain (all three inputs) ------------------------------
    my $ok_id = sub { return defined $_[0] && $_[0] =~ /^(req|rout|form)-[0-9a-f]{12}$/ };
    {
        my @bad;
        push @bad, 'contract.request_id'          unless $ok_id->($c->{request_id});
        push @bad, 'contract.approved_routing_id' unless $ok_id->($c->{approved_routing_id});
        push @bad, 'contract.formalization_id'    unless $ok_id->($c->{formalization_id});
        push @bad, 'pre.verification_id'  unless defined $p->{verification_id}  && $p->{verification_id}  =~ /^pre-[0-9a-f]{12}$/;
        push @bad, 'feas.verification_id' unless defined $fe->{verification_id} && $fe->{verification_id} =~ /^pre-[0-9a-f]{12}$/;
        push @bad, 'feas.feasibility_id'  unless defined $fe->{feasibility_id}  && $fe->{feasibility_id}  =~ /^feas-[0-9a-f]{12}$/;
        push @bad, 'pre.request_id'          unless $ok_id->($p->{request_id});
        push @bad, 'pre.approved_routing_id' unless $ok_id->($p->{approved_routing_id});
        push @bad, 'pre.formalization_id'    unless $ok_id->($p->{formalization_id});
        push @bad, 'feas.request_id'          unless $ok_id->($fe->{request_id});
        push @bad, 'feas.approved_routing_id' unless $ok_id->($fe->{approved_routing_id});
        push @bad, 'feas.formalization_id'    unless $ok_id->($fe->{formalization_id});
        if (@bad) { $add->('IP01', 'blocker', 'B-CHAIN', 'identity chain malformed or missing: ' . join(', ', @bad), \@bad); }
        for my $k ('request_id', 'approved_routing_id', 'formalization_id') {
            my @defined = grep { defined } (map { $_->{$k} } ($c, $p, $fe));
            if (@defined && (@defined < 3 || grep { $_ ne $defined[0] } @defined)) {
                $add->('IP01', 'blocker', 'B-HANDOFF-CHAIN', "$k mismatch across the three inputs", [$k]);
            }
        }
        if (defined $p->{verification_id} && defined $fe->{verification_id} && $p->{verification_id} ne $fe->{verification_id}) {
            $add->('IP01', 'blocker', 'B-HANDOFF-CHAIN', 'verification_id mismatch between pre result and feasibility result', ['verification_id']);
        }
    }
    # --- IP02 planning handoff gate (hard gates) ------------------------------
    {
        my $res = $fe->{feasibility_status} // 'null';
        unless (defined $fe->{feasibility_status} && ($fe->{feasibility_status} eq 'FEASIBLE' || $fe->{feasibility_status} eq 'FEASIBLE_WITH_WARNINGS')) {
            $add->('IP02', 'blocker', 'B-HANDOFF-STATUS',
                "feasibility_status is '$res' — PARTIALLY_FEASIBLE is never reinterpreted as feasible; only FEASIBLE or FEASIBLE_WITH_WARNINGS opens Implementation Planning",
                ['feasibility.feasibility_status']);
        }
        unless ($fe->{blockers_empty}) {
            $add->('IP02', 'blocker', 'B-HANDOFF-BLOCKERS', 'feasibility result carries blockers — downstream use refused', ['feasibility.blockers']);
        }
        unless ($fe->{planning_allowed}) {
            $add->('IP02', 'blocker', 'B-HANDOFF-GATE', 'feasibility implementation_planning_allowed is false — downstream use refused', ['feasibility.implementation_planning_allowed']);
        }
        if (!defined $fe->{next_stage} || $fe->{next_stage} ne 'IMPLEMENTATION_PLANNING') {
            $add->('IP02', 'blocker', 'B-HANDOFF-STAGE', "feasibility next_stage is '" . ($fe->{next_stage} // 'null') . "' — IMPLEMENTATION_PLANNING required", ['feasibility.next_stage']);
        }
        unless (defined $p->{result} && $p->{result} =~ /^PASS/) {
            $add->('IP02', 'blocker', 'B-HANDOFF-PRE-STATUS', "pre-verification result is '" . ($p->{result} // 'null') . "' — inherited Phase-6 gate re-checked, never bypassed", ['pre_verification.result']);
        }
        unless ($p->{feasibility_allowed}) {
            $add->('IP02', 'blocker', 'B-HANDOFF-PRE-GATE', 'pre-verification feasibility_allowed is false — inherited Phase-6 gate re-checked', ['pre_verification.feasibility_allowed']);
        }
        if (defined $p->{next_stage} && $p->{next_stage} ne 'FEASIBILITY') {
            $add->('IP02', 'blocker', 'B-HANDOFF-PRE-STAGE', "pre-verification next_stage is '" . $p->{next_stage} . "' — FEASIBILITY required (inherited gate)", ['pre_verification.next_stage']);
        }
    }
    # --- IP03 requirements coverage ------------------------------------------
    {
        my %cover;
        for my $m (@$mods) { $cover{$_} = $m->{module_id} for @{ $m->{source_requirements} || [] }; }
        my @uncov;
        push @uncov, map { $_->{id} // () } grep { !$cover{ $_->{id} // '' } } @{ $c->{conditions} || [] };
        push @uncov, map { $_->{id} // () } grep { !$cover{ $_->{id} // '' } } @{ $c->{formulas} || [] };
        push @uncov, map { $_->{id} // () } grep { !$cover{ $_->{id} // '' } } @{ $c->{edge_cases} || [] };
        for my $i (1 .. scalar @{ $c->{required_data} || [] }) { push @uncov, "required_data[$i]" unless $cover{"required_data[$i]"}; }
        if (@uncov) {
            $add->('IP03', 'blocker', 'B-COVERAGE', 'requirements not attached to any module: ' . join(', ', @uncov), \@uncov, \@uncov);
        }
    }
    # --- IP04 architecture (deterministic layer model) ------------------------
    {
        my %hasm = map { $_->{module_id} => 1 } @$mods;
        push @{ r_arch() }, { layer => 'INTEGRATION', description => 'single integration point wiring all modules; Pine Script v6 target only', basis => 'formalization implementation_constraints (mirrored verbatim)' };
        push @{ r_arch() }, { layer => 'REPAINT_DISCIPLINE', description => ($c->{repaint_raw} // 'repaint classification not recorded upstream'), basis => 'formalization repaint_risk (mirrored verbatim; never reclassified)' } if defined $c->{repaint_raw};
        push @{ r_arch() }, { layer => 'DATA_ACQUISITION', description => 'request.* data boundaries exactly as declared; no substituted sources', basis => 'formalization required_data + feasibility platform_requirements (mirrored verbatim)' } if $hasm{'M-DATA'};
        push @{ r_arch() }, { layer => 'CALCULATION', description => 'formula evaluation with mathematical equivalence to the contract', basis => 'formalization formulas (mirrored verbatim)' } if $hasm{'M-CALC'};
        push @{ r_arch() }, { layer => 'STATE', description => 'per-bar series state with documented execution semantics; behavior never silently changed', basis => 'documented execution model via feasibility platform_requirements' } if $hasm{'M-STATE'};
        push @{ r_arch() }, { layer => 'SIGNAL', description => 'condition evaluation preserving the exact formalized clauses', basis => 'formalization boolean_conditions (mirrored verbatim)' } if $hasm{'M-SIGNAL'};
        push @{ r_arch() }, { layer => 'PRESENTATION', description => 'drawing responsibilities planned from request wording only', basis => 'natural_language_request (mechanical detection)' } if $hasm{'M-DRAW'};
        push @{ r_arch() }, { layer => 'ALERTING', description => 'alert triggers mirror the contract; timing stays user alert-configuration', basis => 'natural_language_request (mechanical detection)' } if $hasm{'M-ALERT'};
    }
    # --- IP05 module decomposition (field completeness) ------------------------
    {
        for my $m (@$mods) {
            for my $field ('module_id', 'purpose', 'inputs', 'outputs', 'dependencies', 'source_requirements', 'verification_requirements') {
                unless (defined $m->{$field}) {
                    $add->('IP05', 'blocker', 'B-MODULE-FIELD', "module '" . $m->{module_id} . "' missing field '$field'", [$m->{module_id}]);
                }
            }
        }
    }
    # --- IP06 data flow -------------------------------------------------------
    {
        for my $m (@$mods) {
            for my $d (@{ $m->{dependencies} || [] }) {
                push @{ r_flow() }, { producer => $d, transformation => "processing in $m->{module_id}", consumer => $m->{module_id} };
            }
        }
    }
    # --- IP07 state architecture ----------------------------------------------
    {
        my %hasm = map { $_->{module_id} => 1 } @$mods;
        if ($hasm{'M-STATE'}) {
            my @src = map { ($_->{condition} // '') =~ $STATE_RE ? $_->{id} : () } @{ $c->{conditions} || [] };
            push @{ r_state() }, { subject => 'per-bar prior-value / crossover mechanics',
                state_kind => 'per-bar series state (initialized on first available bar; one logical update per confirmed bar)',
                lifecycle => 'historical bars update at close; realtime bars follow the documented recalc-and-rollback execution semantics — behavior never silently changed',
                refs => [ @src ? @src : 'natural_language_request' ] };
        }
        if (@{ $c->{edge_cases} || [] }) {
            push @{ r_state() }, { subject => 'edge-case handling points',
                state_kind => 'initialization / warm-up / insufficient-history behavior',
                lifecycle => 'every edge case must behave per its contract required_behavior (never invented)',
                refs => [ map { $_->{id} // () } @{ $c->{edge_cases} || [] } ] };
        }
    }
    # --- IP08 MTF architecture -------------------------------------------------
    {
        my $is_mtf = ($c->{mtf_flag} || @{ $c->{required_data} || [] }) ? 1 : 0;
        if ($is_mtf) {
            push @{ r_mtf() }, { element => 'chart timeframe', value => ($c->{tf_chart} // 'not recorded upstream'), basis => 'formalization timeframe.chart (mirrored verbatim; never altered)' };
            my $i = 0;
            for my $d (@{ $c->{required_data} || [] }) {
                $i++;
                push @{ r_mtf() }, { element => "required_data[$i] (" . ($d->{kind} // '') . ')', value => ($d->{timeframe} // 'not recorded'), basis => 'formalization required_data (mirrored verbatim; never altered)' };
            }
            my $disc = (grep { ($_->{constraint} // '') =~ /HTF|repaint|MTF/i } @{ $fe->{constraints} || [] })[0];
            push @{ r_mtf() }, defined $disc
                ? { element => 'confirmation discipline', value => $disc->{constraint}, basis => 'feasibility constraints (mirrored verbatim)' }
                : { element => 'confirmation discipline', value => 'explicit user-confirmed HTF discipline required downstream (no behavior invented here)', basis => 'AGENT_RULES 3.12/3.13 via feasibility constraints' };
        }
    }
    # --- IP09 signal architecture (verbatim preservation + precedence) ---------
    {
        my $prec = 0;
        for my $cd (@{ $c->{conditions} || [] }) {
            $prec++;
            my %hasm = map { $_->{module_id} => 1 } @$mods;
            my @prereq = $hasm{'M-STATE'} ? ('M-STATE') : (); push @prereq, 'M-CALC' if $hasm{'M-CALC'};
            push @{ r_siga() }, { signal_ref => ($cd->{id} // 'C-?'), condition_verbatim => ($cd->{condition} // ''),
                prerequisites => [ @prereq ? @prereq : 'none' ], precedence => $prec };
        }
    }
    # --- IP10 drawing architecture ----------------------------------------------
    {
        my %hasm = map { $_->{module_id} => 1 } @$mods;
        if ($hasm{'M-DRAW'}) {
            push @{ r_drawa() }, { element => 'object budget', value => 'UNKNOWN_REQUIRES_VERIFICATION (exact per-tier budgets not evidenced; verify downstream)', basis => 'feasibility documentation-evidence policy (no invented limits)' };
            push @{ r_drawa() }, { element => 'requested presentation', value => 'drawing/output wording present in the request — responsibilities limited to what is worded (plots/labels/lines/tables as worded)', basis => 'natural_language_request (mechanical detection)' };
            my $cn = (grep { ($_->{constraint} // '') =~ /drawing/i } @{ $fe->{constraints} || [] })[0];
            push @{ r_drawa() }, { element => 'verification constraint', value => $cn->{constraint}, basis => 'feasibility constraints (mirrored verbatim)' } if $cn;
        }
    }
    # --- IP11 alert architecture --------------------------------------------------
    {
        my %hasm = map { $_->{module_id} => 1 } @$mods;
        if ($hasm{'M-ALERT'}) {
            my @cids = map { $_->{id} // () } @{ $c->{conditions} || [] };
            push @{ r_alerta() }, { element => 'trigger conditions', value => 'mirror the contracted conditions verbatim (' . join(', ', @cids) . ')', basis => 'formalization boolean_conditions (mirrored verbatim)' };
            push @{ r_alerta() }, { element => 'timing/frequency', value => 'user alert-configuration — never decided by the plan', basis => 'alerts-and-webhooks skill via feasibility platform_requirements' };
            my $rt = (grep { ($_->{constraint} // '') =~ /realtime|alert timing/i } @{ $fe->{constraints} || [] })[0];
            push @{ r_alerta() }, { element => 'realtime interaction', value => $rt->{constraint}, basis => 'feasibility constraints (mirrored verbatim)' } if $rt;
        }
    }
    # --- IP12 performance plan --------------------------------------------------------
    {
        my $nd = scalar @{ $c->{required_data} || [] };
        push @{ r_perf() }, { element => 'request.* boundaries', value => "$nd declared data acquisition(s)", basis => 'mechanical count over the contract (advisory)' } if $nd;
        my $prose = $c->{request_text} // '';
        if ($prose =~ $LOOP_RE) {
            $add->('IP12', 'warning', 'W-LOOP-BOUND', 'unbounded-history loop wording — the exact bound and iteration strategy need a user decision; recorded as NEEDS_USER_INPUT (never silently chosen)', ['natural_language_request']);
            push @{ r_decisions() }, { id => 'D-LOOP', subject => 'loop bound and iteration strategy for unbounded-history wording', status => 'NEEDS_USER_INPUT', refs => ['natural_language_request'] };
        }
        for my $w (@{ $fe->{warnings} || [] }) {
            next unless ($w->{code} // '') =~ /^W-PERF/;
            push @{ r_perf() }, { element => "carried feasibility warning " . ($w->{code} // ''), value => ($w->{message} // ''), basis => 'feasibility warnings (mirrored verbatim; advisory)' };
        }
    }
    # --- IP13 dependency graph (cycles / missing) ---------------------------------------
    {
        my $cyc = graph_find_cycle($mods);
        if ($cyc) { $add->('IP13', 'blocker', 'B-DEP-CYCLE', 'dependency cycle detected: ' . join(' -> ', @$cyc), [@$cyc]); }
        my $miss = graph_find_missing($mods);
        if (@$miss) { $add->('IP13', 'blocker', 'B-DEP-MISSING', 'unresolved dependencies: ' . join(', ', @$miss), $miss); }
    }
    # --- IP14 verification hooks -----------------------------------------------------------
    {
        for my $m (@$mods) {
            my %seen;
            for my $h (@{ $m->{verification_requirements} || [] }) { $seen{$h} = 1; }
            push @{ r_hooks() }, { module_id => $m->{module_id}, hook => $DEF_HOOK{ $m->{module_id} } // 'module boundary behaves as planned', upstream_ref => 'formalization verification_requirements / engine default' };
            for my $h (sort keys %seen) {
                push @{ r_hooks() }, { module_id => $m->{module_id}, hook => $h, upstream_ref => 'formalization verification_requirements' };
            }
        }
    }
    return (\@F, $mods);
}

# decisions accumulator (declared with the others; used by IP12)
my $DEC;
sub r_decisions { $DEC ||= []; return $DEC; }
my $HOOKS;
sub r_hooks { $HOOKS ||= []; return $HOOKS; }

# ---------------------------------------------------------------------------
# planning orchestration
# ---------------------------------------------------------------------------
sub _finalize {
    my ($r, $c, $p, $fe, $mods) = @_;
    my @findings = @{ $r->{findings} || [] };
    my $i = 0;
    for my $f (@findings) { $i++; $f->{id} = sprintf('H-%03d', $i); }
    my @blockers = grep { ($_->{severity} // '') eq 'blocker' } @findings;
    my @warnings = grep { ($_->{severity} // '') eq 'warning' } @findings;
    # carried upstream feasibility warnings (surfaced verbatim, non-blocking)
    my @carried;
    {
        my $j = 0;
        for my $w (@{ $fe->{warnings} || [] }) {
            $j++;
            push @carried, { id => sprintf('C-%03d', $j), check_id => 'FEAS', code => ($w->{code} // 'W-UPSTREAM'),
                message => ($w->{message} // 'upstream warning'), refs => ['feasibility.warnings'] };
        }
    }
    my @checks;
    for my $d (@DOMAINS) {
        my ($cid, $dom) = @$d;
        my @mine = grep { ($_->{check_id} // '') eq $cid } @findings;
        my $verdict = (grep { ($_->{severity} // '') eq 'blocker' } @mine) ? 'fail' : (@mine ? 'warn' : 'pass');
        push @checks, { check_id => $cid, domain => $dom, verdict => $verdict, findings => [map { $_->{id} } @mine] };
    }
    my $order = topo_order($mods);
    # coverage map (deterministic; part of identity)
    my %cover;
    for my $m (@$mods) { $cover{$_} = $m->{module_id} for @{ $m->{source_requirements} || [] }; }
    # --- deterministic identity ---------------------------------------------------
    # identity is minted only for parseable inputs — INVALID_INPUT has no planning_id
    my $pid = undef;
    if (!$r->{input_invalid}) {
        my @body = ($r->{request_id} // '', $r->{approved_routing_id} // '', $r->{formalization_id} // '',
                    $r->{verification_id} // '', $r->{feasibility_id} // '',
                    $r->{contract_sha} // '', $r->{pre_sha} // '', $r->{feas_sha} // '');
        for my $m (@$mods) { push @body, $m->{module_id}, $m->{purpose}, join("\x1E", @{ $m->{dependencies} || [] }); }
        push @body, map { "$_=" . ($cover{$_} // '') } sort keys %cover;
        push @body, map { $_->{code} } @warnings, @carried;
        push @body, map { ($_->{id} // '') . '=' . ($_->{status} // '') } @{ r_decisions() || [] };
        $pid = 'plan-' . substr(sha256_hex(encode('UTF-8', join("\x1F", @body))), 0, 12);
    }
    # --- status decision (mandated order) ---------------------------------------------
    my $result = $r->{input_invalid} ? 'INVALID_INPUT'
               : @blockers ? 'BLOCKED'
               : (@warnings || @carried) ? 'READY_WITH_WARNINGS'
               : 'READY';
    my $open = ($result eq 'READY' || $result eq 'READY_WITH_WARNINGS') ? 1 : 0;
    my %ord; $ord{ $order->[$_] } = $_ + 1 for 0 .. $#$order;
    $r->{checks}                 = \@checks;
    $r->{findings}               = \@findings;
    $r->{blockers}               = \@blockers;
    $r->{warnings}               = [ @warnings, @carried ];
    $r->{decisions}              = [ @{ r_decisions() || [] } ];
    $r->{architecture}           = [ @{ r_arch() || [] } ];
    $r->{modules}                = [ map { { module_id => $_->{module_id}, purpose => $_->{purpose},
        dependencies => $_->{dependencies}, source_requirements => $_->{source_requirements},
        verification_requirements => $_->{verification_requirements}, order => ($ord{ $_->{module_id} } // 0) } } @$mods ];
    $r->{data_flow}              = [ @{ r_flow() || [] } ];
    $r->{state_architecture}     = [ @{ r_state() || [] } ];
    $r->{mtf_architecture}       = [ @{ r_mtf() || [] } ];
    $r->{signal_architecture}    = [ @{ r_siga() || [] } ];
    $r->{drawing_architecture}   = [ @{ r_drawa() || [] } ];
    $r->{alert_architecture}     = [ @{ r_alerta() || [] } ];
    $r->{performance_plan}       = [ @{ r_perf() || [] } ];
    $r->{dependency_graph}       = [ map { { module_id => $_->{module_id}, depends_on => $_->{dependencies} } } @$mods ];
    $r->{implementation_order}   = $order;
    $r->{verification_hooks}     = [ @{ r_hooks() || [] } ];
    $r->{traceability} = $c ? {
        source_skills              => $c->{source_skills} // [],
        verification_requirements  => $c->{verification_requirements} // [],
        implementation_constraints => $c->{implementation_constraints} // [],
    } : { source_skills => [], verification_requirements => [], implementation_constraints => [] };
    $r->{planning_id}            = $pid;
    $r->{planning_status}        = $result;
    $r->{implementation_allowed} = $open;
    $r->{next_stage}             = $open ? 'IMPLEMENTATION' : 'HALT';
    return $r;
}

sub plan_text {
    my ($contract_text, $pre_text, $feas_text) = @_;
    ($ARCH, $FLOW, $STATE, $MTF, $SIGA, $DRAWA, $ALERTA, $PERF, $DEC, $HOOKS) = (undef) x 10;
    my $bad = sub {
        my ($which, $err) = @_;
        $err = defined $err ? "$err" : 'unknown error';
        $err =~ s/\s+$//; $err =~ s/ at .* line \d+\.*$//;
        return _finalize({ input_invalid => 1, findings => [{ check_id => 'IP01', severity => 'blocker', code => 'B-INPUT', message => "$which could not be parsed: $err", refs => [$which] }] }, undef, undef, undef, []);
    };
    return $bad->('contract_file', 'missing or empty')     if !defined $contract_text || $contract_text !~ /\S/;
    return $bad->('pre_file', 'missing or empty')          if !defined $pre_text     || $pre_text     !~ /\S/;
    return $bad->('feasibility_file', 'missing or empty')  if !defined $feas_text    || $feas_text    !~ /\S/;
    my $c  = eval { parse_contract($contract_text) };
    return $bad->('contract_file', $@ // 'unknown error')    unless $c;
    my $p  = eval { parse_pre($pre_text) };
    return $bad->('pre_file', $@ // 'unknown error')         unless $p;
    my $fe = eval { parse_feas($feas_text) };
    return $bad->('feasibility_file', $@ // 'unknown error') unless $fe;
    my ($F, $mods) = run_checks($c, $p, $fe);
    return _finalize({
        (map { $_ => $c->{$_} } qw(request_id approved_routing_id formalization_id)),
        verification_id => $p->{verification_id},
        feasibility_id  => $fe->{feasibility_id},
        contract_sha => sha256_hex(encode('UTF-8', $contract_text)),
        pre_sha      => sha256_hex(encode('UTF-8', $pre_text)),
        feas_sha     => sha256_hex(encode('UTF-8', $feas_text)),
        findings     => $F,
    }, $c, $p, $fe, $mods);
}

# ---------------------------------------------------------------------------
# result emitter (fixed field order; same style as feasibility.pl)
# ---------------------------------------------------------------------------
sub _q  { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _qb { my $b = shift; return ($b) ? 'true' : 'false'; }
sub _ql { my ($l) = @_; return '[]' unless @{ $l || [] }; return '[' . join(', ', map { _q($_) } @$l) . ']'; }

sub plan_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# implementation plan — generated by implementation_plan.pl (schema v1.1; meta/implementation_planning_procedure.md)';
    push @o, 'schema_version: "1.1"', 'stage: implementation_planning', 'predecessor: feasibility', 'successor: implementation', '';
    push @o, 'planning:';
    push @o, '  request_id: ' . _q($r->{request_id});
    push @o, '  approved_routing_id: ' . _q($r->{approved_routing_id});
    push @o, '  formalization_id: ' . _q($r->{formalization_id});
    push @o, '  verification_id: ' . _q($r->{verification_id});
    push @o, '  feasibility_id: ' . _q($r->{feasibility_id});
    push @o, '  planning_id: ' . _q($r->{planning_id});
    push @o, '  planning_status: ' . _q($r->{planning_status});
    push @o, '  implementation_allowed: ' . _qb($r->{implementation_allowed});
    push @o, '  next_stage: ' . ($r->{next_stage} // 'null');
    push @o, '  checks:';
    for my $ck (@{ $r->{checks} }) {
        push @o, '    - { check_id: ' . _q($ck->{check_id}) . ', domain: ' . _q($ck->{domain}) . ', verdict: ' . _q($ck->{verdict}) . ', findings: ' . _ql($ck->{findings}) . ' }';
    }
    if (!@{ $r->{findings} }) { push @o, '  findings: []'; }
    else {
        push @o, '  findings:';
        for my $f (@{ $r->{findings} }) {
            push @o, '    - { id: ' . _q($f->{id}) . ', check_id: ' . _q($f->{check_id}) . ', severity: ' . _q($f->{severity}) . ', code: ' . _q($f->{code}) . ', message: ' . _q($f->{message}) . ', refs: ' . _ql($f->{refs}) . ' }';
        }
    }
    if (!@{ $r->{blockers} }) { push @o, '  blockers: []'; }
    else {
        push @o, '  blockers:';
        for my $b (@{ $r->{blockers} }) { push @o, '    - { id: ' . _q($b->{id}) . ', check_id: ' . _q($b->{check_id}) . ', reason: ' . _q(($b->{code} // '') . ' — ' . ($b->{message} // '')) . ' }'; }
    }
    if (!@{ $r->{warnings} }) { push @o, '  warnings: []'; }
    else {
        push @o, '  warnings:';
        for my $w (@{ $r->{warnings} }) { push @o, '    - { id: ' . _q($w->{id}) . ', check_id: ' . _q($w->{check_id}) . ', code: ' . _q($w->{code}) . ', message: ' . _q($w->{message}) . ' }'; }
    }
    if (!@{ $r->{decisions} }) { push @o, '  decisions: []'; }
    else {
        push @o, '  decisions:';
        for my $d (@{ $r->{decisions} }) { push @o, '    - { id: ' . _q($d->{id}) . ', subject: ' . _q($d->{subject}) . ', status: ' . _q($d->{status}) . ', refs: ' . _ql($d->{refs}) . ' }'; }
    }
    if (!@{ $r->{architecture} }) { push @o, '  architecture: []'; }
    else {
        push @o, '  architecture:';
        for my $a (@{ $r->{architecture} }) { push @o, '    - { layer: ' . _q($a->{layer}) . ', description: ' . _q($a->{description}) . ', basis: ' . _q($a->{basis}) . ' }'; }
    }
    if (!@{ $r->{modules} }) { push @o, '  modules: []'; }
    else {
        push @o, '  modules:';
        for my $m (@{ $r->{modules} }) {
            push @o, '    - { module_id: ' . _q($m->{module_id}) . ', purpose: ' . _q($m->{purpose}) . ', dependencies: ' . _ql($m->{dependencies}) . ', source_requirements: ' . _ql($m->{source_requirements}) . ', verification_requirements: ' . _ql($m->{verification_requirements}) . ', order: ' . ($m->{order} || 0) . ' }';
        }
    }
    if (!@{ $r->{data_flow} }) { push @o, '  data_flow: []'; }
    else {
        push @o, '  data_flow:';
        for my $d (@{ $r->{data_flow} }) { push @o, '    - { producer: ' . _q($d->{producer}) . ', transformation: ' . _q($d->{transformation}) . ', consumer: ' . _q($d->{consumer}) . ' }'; }
    }
    if (!@{ $r->{state_architecture} }) { push @o, '  state_architecture: []'; }
    else {
        push @o, '  state_architecture:';
        for my $s (@{ $r->{state_architecture} }) { push @o, '    - { subject: ' . _q($s->{subject}) . ', state_kind: ' . _q($s->{state_kind}) . ', lifecycle: ' . _q($s->{lifecycle}) . ', refs: ' . _ql($s->{refs}) . ' }'; }
    }
    if (!@{ $r->{mtf_architecture} }) { push @o, '  mtf_architecture: []'; }
    else {
        push @o, '  mtf_architecture:';
        for my $m (@{ $r->{mtf_architecture} }) { push @o, '    - { element: ' . _q($m->{element}) . ', value: ' . _q($m->{value}) . ', basis: ' . _q($m->{basis}) . ' }'; }
    }
    if (!@{ $r->{signal_architecture} }) { push @o, '  signal_architecture: []'; }
    else {
        push @o, '  signal_architecture:';
        for my $s (@{ $r->{signal_architecture} }) { push @o, '    - { signal_ref: ' . _q($s->{signal_ref}) . ', condition_verbatim: ' . _q($s->{condition_verbatim}) . ', prerequisites: ' . _ql($s->{prerequisites}) . ', precedence: ' . ($s->{precedence} || 0) . ' }'; }
    }
    if (!@{ $r->{drawing_architecture} }) { push @o, '  drawing_architecture: []'; }
    else {
        push @o, '  drawing_architecture:';
        for my $d (@{ $r->{drawing_architecture} }) { push @o, '    - { element: ' . _q($d->{element}) . ', value: ' . _q($d->{value}) . ', basis: ' . _q($d->{basis}) . ' }'; }
    }
    if (!@{ $r->{alert_architecture} }) { push @o, '  alert_architecture: []'; }
    else {
        push @o, '  alert_architecture:';
        for my $a (@{ $r->{alert_architecture} }) { push @o, '    - { element: ' . _q($a->{element}) . ', value: ' . _q($a->{value}) . ', basis: ' . _q($a->{basis}) . ' }'; }
    }
    if (!@{ $r->{performance_plan} }) { push @o, '  performance_plan: []'; }
    else {
        push @o, '  performance_plan:';
        for my $p (@{ $r->{performance_plan} }) { push @o, '    - { element: ' . _q($p->{element}) . ', value: ' . _q($p->{value}) . ', basis: ' . _q($p->{basis}) . ' }'; }
    }
    if (!@{ $r->{dependency_graph} }) { push @o, '  dependency_graph: []'; }
    else {
        push @o, '  dependency_graph:';
        for my $g (@{ $r->{dependency_graph} }) { push @o, '    - { module_id: ' . _q($g->{module_id}) . ', depends_on: ' . _ql($g->{depends_on}) . ' }'; }
    }
    push @o, '  implementation_order: ' . _ql($r->{implementation_order});
    if (!@{ $r->{verification_hooks} }) { push @o, '  verification_hooks: []'; }
    else {
        push @o, '  verification_hooks:';
        for my $h (@{ $r->{verification_hooks} }) { push @o, '    - { module_id: ' . _q($h->{module_id}) . ', hook: ' . _q($h->{hook}) . ', upstream_ref: ' . _q($h->{upstream_ref}) . ' }'; }
    }
    push @o, '  traceability:';
    push @o, '    source_skills: ' . _ql($r->{traceability}{source_skills});
    push @o, '    verification_requirements: ' . _ql($r->{traceability}{verification_requirements});
    push @o, '    implementation_constraints: ' . _ql($r->{traceability}{implementation_constraints});
    push @o, '  next_stage_note: ' . _q((($r->{next_stage} // '') eq 'IMPLEMENTATION') ? 'Implementation may start against this blueprint' : 'pipeline halted — downstream progression forbidden');
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# gate-check on a PLAN file: approved iff planning_id well-formed,
# planning_status READY|READY_WITH_WARNINGS, blockers [],
# implementation_allowed true, next_stage IMPLEMENTATION
# ---------------------------------------------------------------------------
sub gate_check_text {
    my ($t) = @_;
    my ($pid) = $t =~ /^\s{2}planning_id:\s*'([^']*)'/m;
    my ($res) = $t =~ /^\s{2}planning_status:\s*'([^']*)'/m;
    my ($ia)  = $t =~ /^\s{2}implementation_allowed:\s*(true|false)/m;
    my ($ns)  = $t =~ /^\s{2}next_stage:\s*(\S+)/m;
    my $blockers_empty = ($t =~ /^  blockers: \[\]/m) ? 1 : 0;
    return (0, 'planning_id missing or malformed') unless defined $pid && $pid =~ /^plan-[0-9a-f]{12}$/;
    return (0, "planning_status is '$res' — downstream progression forbidden") unless defined $res && ($res eq 'READY' || $res eq 'READY_WITH_WARNINGS');
    return (0, 'blockers list is non-empty') unless $blockers_empty;
    return (0, "implementation_allowed is '$ia'") unless defined $ia && $ia eq 'true';
    return (0, "next_stage is '$ns'") unless defined $ns && $ns eq 'IMPLEMENTATION';
    return (1, "approved_plan_id = $pid");
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return decode('UTF-8', $t); }

sub main {
    my ($contract_file, $pre_file, $feas_file, $out_file, $gate, $plan_file) = (undef, undef, undef, undef, 0, undef);
    while (@ARGV) {
        my $a = shift @ARGV;
        if    ($a eq '--contract')   { $contract_file = shift @ARGV; }
        elsif ($a eq '--pre')        { $pre_file = shift @ARGV; }
        elsif ($a eq '--feasibility'){ $feas_file = shift @ARGV; }
        elsif ($a eq '--out')        { $out_file = shift @ARGV; }
        elsif ($a eq '--plan')       { $plan_file = shift @ARGV; }
        elsif ($a eq '--gate-check') { $gate = 1; }
        elsif ($a eq '--selftest')   { my $st = selftest(); exit $st; }
        else { die "unknown argument '$a'\n"; }
    }
    if ($gate) {
        die "usage with --gate-check: --plan FILE\n" unless defined $plan_file && $plan_file ne '';
        my $t = _slurp($plan_file);
        my ($ok, $msg) = gate_check_text($t);
        print "$msg\n";
        exit($ok ? 0 : 2);
    }
    die "usage: implementation_plan.pl --contract FILE --pre FILE --feasibility FILE [--out FILE] | --gate-check --plan FILE | --selftest\n"
        if !$contract_file || !$pre_file || !$feas_file;
    my $r = plan_text(_slurp($contract_file), _slurp($pre_file), _slurp($feas_file));
    my $yaml = encode('UTF-8', plan_to_yaml($r));
    if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh $yaml; close $fh; }
    else { print $yaml; }
    exit(($r->{planning_status} eq 'READY' || $r->{planning_status} eq 'READY_WITH_WARNINGS') ? 0 : 2);
}

# ---------------------------------------------------------------------------
# selftest — the 27 mandated acceptance cases (TEST-PLAN-001..027)
# Fixtures are AUTHENTIC: feasibility results are produced by the real
# feasibility.pl engine (subprocess, same interpreter) — no hand-faked gates.
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };
    require File::Temp;

    my ($engine) = (__FILE__ =~ /^(.+)[\\\/][^\\\/]+$/ ? $1 : '.');
    $engine =~ s{\\}{/}g;
    my $feas_pl = "$engine/../feasibility/feasibility.pl";

    my $BASE_C = <<'EOC';
# formalization contract — generated by formalize.pl (schema v1.1; meta/formalization_procedure.md)
schema_version: "1.1"
stage: formalization
predecessor: skill_routing
successor: pre_verification

formalization:
  request_id: 'req-aaaaaaaaaaaa'
  approved_routing_id: 'rout-bbbbbbbbbbbb'
  formalization_id: 'form-cccccccccccc'
  supersedes: null
  natural_language_request: 'close crosses over 30 on bar close'
  normalized_request: 'close crosses over 30 on bar close'
  variables:
    - { name: 'close', type: 'series float', description: 'built-in source token', source: 'request (verbatim)' }
  formulas: []
  boolean_conditions:
    - { id: 'C-1', condition: 'close crosses over 30', meaning: 'verbatim request clause', used_by: 'entry' }
  assumptions: []
  ambiguities: []
  edge_cases:
    - { id: 'E-NA', case: 'na values during warm-up (insufficient history)', required_behavior: null }
    - { id: 'E-FIRST', case: 'first bars / insufficient history for lookbacks', required_behavior: null }
  timeframe:
    chart: '15m'
    calculation: null
  mtf: false
  required_data: []
  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'
  source_skills: ['strategy-engine', 'momentum-indicators']
  verification_requirements: ['logic_valid', 'math_valid', 'variables_defined', 'assumptions_documented', 'ambiguities_resolved_or_recorded', 'edge_cases_checked', 'repaint_risk_classified']
  implementation_constraints: ['Target Pine Script v6 only (no v5/v4 syntax).']
  status: 'completed'
  blockers: []
  implementation_allowed: true
EOC

    my $mk_pre = sub {
        my (%o) = @_;
        my $result = $o{result} // 'PASS';
        my $fa = ($result =~ /^PASS/) ? 'true' : 'false';
        my $ns = ($result =~ /^PASS/) ? 'FEASIBILITY' : 'HALT';
        my $warnings = "  warnings: []";
        $warnings = "  warnings:\n$o{warn_block}" if $o{warn_block};
        my $blockers = '  blockers: []';
        $blockers = "  blockers:\n    - { id: 'G-001', check_id: 'PC07', reason: 'upstream failure' }" if $result ne 'PASS' && $result ne 'PASS_WITH_WARNINGS';
        return <<"EOP";
# pre-verification result — generated by pre_verify.pl (schema v1.1; meta/pre_verification_procedure.md)
schema_version: "1.1"
stage: pre_verification
predecessor: formalization
successor: feasibility

pre_verification:
  request_id: '$o{request_id}'
  approved_routing_id: '$o{approved_routing_id}'
  formalization_id: '$o{formalization_id}'
  verification_id: '$o{vid}'
  result: '$result'
  status: '$o{status}'
  implementation_allowed: $fa
  feasibility_allowed: $fa
  next_stage: $ns
  checks: []
  findings: []
$blockers
$warnings
  ambiguities: []
  unresolved_items: []
  next_stage_note: 'generated fixture'
EOP
    };
    my $PRE = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-cccccccccccc', vid => 'pre-111111111111', result => 'PASS', status => 'passed');
    my $fx = sub { my %o = @_; my $t = $BASE_C; $t =~ s/\Q$_\E/$o{$_}/g for keys %o; return $t; };

    # run the REAL feasibility engine on a (contract, pre) pair -> result text
    my $run_feas = sub {
        my ($ct, $pt) = @_;
        my ($fh1, $c1) = File::Temp::tempfile(SUFFIX => '.yaml');
        binmode $fh1, ':raw'; print $fh1 encode('UTF-8', $ct); close $fh1;
        my ($fh2, $c2) = File::Temp::tempfile(SUFFIX => '.yaml');
        binmode $fh2, ':raw'; print $fh2 encode('UTF-8', $pt); close $fh2;
        my ($fh3, $c3) = File::Temp::tempfile(SUFFIX => '.yaml'); close $fh3;
        my $rc = system($^X, $feas_pl, '--contract', $c1, '--pre', $c2, '--out', $c3);
        my $code = ($rc == -1) ? -1 : (($rc & 127) ? -1 : ($rc >> 8));
        # the engine legitimately exits 0 (feasible) or 2 (blocked/not-feasible/partial);
        # anything else is a crash
        die "selftest: feasibility engine crashed (raw=$rc)\n" if $code != 0 && $code != 2;
        my $t = _slurp($c3);
        die "selftest: feasibility engine produced no result\n" if $t !~ /\S/;
        1 while unlink $c1; 1 while unlink $c2; 1 while unlink $c3;
        return $t;
    };
    my $plan = sub { return plan_text($_[0], $_[1], $_[2]); };
    my $blk_has = sub { my ($r, $code) = @_; return scalar grep { ($_->{code} // '') eq $code } @{ $r->{blockers} || [] }; };

    # authentic upstream fixtures
    my $FEAS_OK   = $run_feas->($BASE_C, $PRE);                                    # FEASIBLE
    my $high_c    = $fx->("repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "repaint_risk: 'high — mechanism: unconfirmed HTF data'");
    my $pre_w     = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-cccccccccccc', vid => 'pre-222222222222', result => 'PASS_WITH_WARNINGS', status => 'passed',
        warn_block => "    - { id: 'G-001', check_id: 'PC10', code: 'W-REPAINT-ACCEPT', message: 'high repaint' }");
    my $FEAS_WARN = $run_feas->($high_c, $pre_w);                                  # FEASIBLE_WITH_WARNINGS
    my $tick_c    = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on every tick with an alert'");
    my $FEAS_PART = $run_feas->($tick_c, $PRE);                                    # PARTIALLY_FEASIBLE
    my $q_c       = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on bar close using quandl data'");
    my $FEAS_NF   = $run_feas->($q_c, $PRE);                                       # NOT_FEASIBLE
    my $pre_b     = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-cccccccccccc', vid => 'pre-333333333333', result => 'BLOCKED', status => 'blocked');
    my $FEAS_BLK  = $run_feas->($BASE_C, $pre_b);                                  # BLOCKED
    # full-spec contract: data + formula + draw + alert wording
    my $FULL_C    = $fx->(
        "  formulas: []" => "  formulas:\n    - { id: 'F-1', expression: 'smoothed = average of close over 10 bars', description: 'smoothing formula', depends_on: 'close' }",
        "  required_data: []" => "  required_data:\n    - { kind: 'htf price', symbol_hint: null, timeframe: '1h', notes: 'htf context' }",
        "  mtf: false" => '  mtf: true',
        "natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on bar close and plot a table label with an alert'",
    );
    my $FEAS_FULL = $run_feas->($FULL_C, $PRE);                                    # whatever the engine says (status-independent tests use it)

    # T-PLAN-001 valid happy path -> READY, gates open, 14 checks pass (mandated #1)
    my $r1 = $plan->($BASE_C, $PRE, $FEAS_OK);
    $ok->(defined $r1 && $r1->{planning_status} eq 'READY', 'T-PLAN-001 status READY');
    $ok->($r1->{implementation_allowed} && $r1->{next_stage} eq 'IMPLEMENTATION', 'T-PLAN-001 gates open');
    $ok->((scalar @{ $r1->{checks} } == 14 && !grep { $_->{verdict} ne 'pass' } @{ $r1->{checks} }), 'T-PLAN-001 14 checks all pass');

    # T-PLAN-002 FEASIBLE_WITH_WARNINGS -> READY_WITH_WARNINGS + carried warning (mandated #2)
    my $r2 = $plan->($high_c, $pre_w, $FEAS_WARN);
    $ok->($r2->{planning_status} eq 'READY_WITH_WARNINGS' && $r2->{implementation_allowed}, 'T-PLAN-002 warnings do not block');
    $ok->((grep { ($_->{code} // '') eq 'W-REPAINT-ACCEPT' && ($_->{check_id} // '') eq 'FEAS' } @{ $r2->{warnings} }), 'T-PLAN-002 upstream warning carried verbatim');

    # T-PLAN-003 PARTIALLY_FEASIBLE -> BLOCKED, never reinterpreted (mandated #3)
    my $r3 = $plan->($tick_c, $PRE, $FEAS_PART);
    $ok->($r3->{planning_status} eq 'BLOCKED' && $r3->{next_stage} eq 'HALT' && !$r3->{implementation_allowed}, 'T-PLAN-003 PARTIALLY_FEASIBLE halts');
    $ok->($blk_has->($r3, 'B-HANDOFF-STATUS'), 'T-PLAN-003 B-HANDOFF-STATUS');

    # T-PLAN-004 NOT_FEASIBLE -> BLOCKED (mandated #4)
    my $r4 = $plan->($q_c, $PRE, $FEAS_NF);
    $ok->($r4->{planning_status} eq 'BLOCKED' && $blk_has->($r4, 'B-HANDOFF-STATUS'), 'T-PLAN-004 NOT_FEASIBLE refused');

    # T-PLAN-005 feasibility blockers -> B-HANDOFF-BLOCKERS (mandated #5)
    my $r5 = $plan->($BASE_C, $pre_b, $FEAS_BLK);
    $ok->($r5->{planning_status} eq 'BLOCKED' && $blk_has->($r5, 'B-HANDOFF-BLOCKERS'), 'T-PLAN-005 blockers refused');

    # T-PLAN-006 planning_allowed false -> B-HANDOFF-GATE (mandated #6)
    my $fe_g = $FEAS_OK; $fe_g =~ s/implementation_planning_allowed: true/implementation_planning_allowed: false/;
    my $r6 = $plan->($BASE_C, $PRE, $fe_g);
    $ok->($blk_has->($r6, 'B-HANDOFF-GATE'), 'T-PLAN-006 gate flag refused');

    # T-PLAN-007 feasibility next_stage HALT -> B-HANDOFF-STAGE (mandated #7)
    my $fe_s = $FEAS_OK; $fe_s =~ s/next_stage: IMPLEMENTATION_PLANNING/next_stage: HALT/;
    my $r7 = $plan->($BASE_C, $PRE, $fe_s);
    $ok->($blk_has->($r7, 'B-HANDOFF-STAGE'), 'T-PLAN-007 stage refused');

    # T-PLAN-008 inherited Phase-6 gate: pre BLOCKED -> B-HANDOFF-PRE-STATUS (mandated #8)
    my $r8 = $plan->($BASE_C, $pre_b, $FEAS_OK);
    $ok->($blk_has->($r8, 'B-HANDOFF-PRE-STATUS'), 'T-PLAN-008 inherited pre gate re-checked');

    # T-PLAN-009 inherited Phase-6 gate: pre feasibility_allowed false (mandated #9)
    my $pre_g = $PRE; $pre_g =~ s/feasibility_allowed: true/feasibility_allowed: false/;
    my $r9 = $plan->($BASE_C, $pre_g, $FEAS_OK);
    $ok->($blk_has->($r9, 'B-HANDOFF-PRE-GATE'), 'T-PLAN-009 pre gate flag re-checked');

    # T-PLAN-010 chain mismatch contract vs pre -> B-HANDOFF-CHAIN (mandated #10)
    my $pre_m = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-dddddddddddd', vid => 'pre-111111111111', result => 'PASS', status => 'passed');
    my $r10 = $plan->($BASE_C, $pre_m, $FEAS_OK);
    $ok->($blk_has->($r10, 'B-HANDOFF-CHAIN'), 'T-PLAN-010 chain mismatch refused');

    # T-PLAN-011 verification_id mismatch pre vs feasibility -> B-HANDOFF-CHAIN (mandated #11)
    my $fe_v = $FEAS_OK; $fe_v =~ s/verification_id: 'pre-111111111111'/verification_id: 'pre-999999999999'/;
    my $r11 = $plan->($BASE_C, $PRE, $fe_v);
    $ok->($blk_has->($r11, 'B-HANDOFF-CHAIN'), 'T-PLAN-011 verification_id mismatch refused');

    # T-PLAN-012 malformed input -> INVALID_INPUT + HALT (mandated #12)
    my $r12 = $plan->("\tnot a contract }}}", $PRE, $FEAS_OK);
    $ok->($r12->{planning_status} eq 'INVALID_INPUT' && $r12->{next_stage} eq 'HALT', 'T-PLAN-012a malformed contract');
    my $r12b = $plan->($BASE_C, undef, $FEAS_OK);
    $ok->($r12b->{planning_status} eq 'INVALID_INPUT' && !defined $r12b->{planning_id}, 'T-PLAN-012b missing pre');
    my $r12c = $plan->($BASE_C, $PRE, undef);
    $ok->($r12c->{planning_status} eq 'INVALID_INPUT', 'T-PLAN-012c missing feasibility');

    # T-PLAN-013 base module derivation: exactly M-STATE, M-SIGNAL, M-INTEG (mandated #13)
    {
        my @ids = sort map { $_->{module_id} } @{ $r1->{modules} };
        $ok->((join(',', @ids) eq 'M-INTEG,M-SIGNAL,M-STATE'), 'T-PLAN-013 base modules exact');
    }

    # T-PLAN-014 full contract -> all 7 modules (mandated #14)
    {
        my $rf = $plan->($FULL_C, $PRE, $FEAS_FULL);
        my @ids = sort map { $_->{module_id} } @{ $rf->{modules} };
        my %has = map { $_ => 1 } @ids;
        $ok->(scalar(@ids) == 7 && $has{'M-DATA'} && $has{'M-CALC'} && $has{'M-DRAW'} && $has{'M-ALERT'},
            'T-PLAN-014 full modules 7');
    }

    # T-PLAN-015 coverage: every requirement attached (no B-COVERAGE) (mandated #15)
    {
        my $rf = $plan->($FULL_C, $PRE, $FEAS_FULL);
        $ok->(!$blk_has->($rf, 'B-COVERAGE'), 'T-PLAN-015a full contract fully covered');
        $ok->(!$blk_has->($r1, 'B-COVERAGE'), 'T-PLAN-015b base contract fully covered');
    }

    # T-PLAN-016 implementation order: deterministic topological (mandated #16)
    {
        my $rf = $plan->($FULL_C, $PRE, $FEAS_FULL);
        my $exp = join(',', qw(M-DATA M-CALC M-STATE M-SIGNAL M-DRAW M-ALERT M-INTEG));
        $ok->(join(',', @{ $rf->{implementation_order} }) eq $exp, 'T-PLAN-016a full order exact');
        $ok->($rf->{implementation_order}[-1] eq 'M-INTEG', 'T-PLAN-016b integration last');
    }

    # T-PLAN-017 signal architecture preserves conditions VERBATIM (mandated #17)
    {
        my @sa = grep { ($_->{signal_ref} // '') eq 'C-1' } @{ $r1->{signal_architecture} };
        $ok->(scalar @sa == 1 && $sa[0]{condition_verbatim} eq 'close crosses over 30', 'T-PLAN-017 verbatim condition');
    }

    # T-PLAN-018 MTF architecture iff data/mtf; chart TF mirrored verbatim (mandated #18)
    {
        $ok->(!@{ $r1->{mtf_architecture} }, 'T-PLAN-018a no MTF section without data/mtf');
        my $rf = $plan->($FULL_C, $PRE, $FEAS_FULL);
        my ($chart) = grep { ($_->{element} // '') eq 'chart timeframe' } @{ $rf->{mtf_architecture} };
        $ok->(defined $chart && $chart->{value} eq '15m', 'T-PLAN-018b chart TF mirrored verbatim');
    }

    # T-PLAN-019 drawing budget stays UNKNOWN — no invented limits (mandated #19)
    {
        my $rf = $plan->($FULL_C, $PRE, $FEAS_FULL);
        my ($bud) = grep { ($_->{element} // '') eq 'object budget' } @{ $rf->{drawing_architecture} };
        $ok->(defined $bud && $bud->{value} =~ /UNKNOWN_REQUIRES_VERIFICATION/ && $bud->{value} !~ /\d+ objects/, 'T-PLAN-019 budget unknown, no invented numbers');
    }

    # T-PLAN-020 alert architecture iff alert wording; timing stays user-config (mandated #20)
    {
        $ok->(!@{ $r1->{alert_architecture} }, 'T-PLAN-020a no alert section without wording');
        my $rf = $plan->($FULL_C, $PRE, $FEAS_FULL);
        my ($timing) = grep { ($_->{element} // '') eq 'timing/frequency' } @{ $rf->{alert_architecture} };
        $ok->(defined $timing && $timing->{value} =~ /user alert-configuration/, 'T-PLAN-020b timing never decided by plan');
    }

    # T-PLAN-021 unbounded-loop wording -> warning + NEEDS_USER_INPUT decision, not blocker (mandated #21)
    {
        my $loop_c = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'for every bar in history check close crosses over 30'");
        my $FEAS_LOOP = $run_feas->($loop_c, $PRE);
        my $rl = $plan->($loop_c, $PRE, $FEAS_LOOP);
        $ok->($rl->{planning_status} eq 'READY_WITH_WARNINGS', 'T-PLAN-021a loop decision does not block');
        $ok->((grep { ($_->{code} // '') eq 'W-LOOP-BOUND' } @{ $rl->{warnings} }), 'T-PLAN-021b W-LOOP-BOUND surfaced');
        $ok->((grep { ($_->{id} // '') eq 'D-LOOP' && ($_->{status} // '') eq 'NEEDS_USER_INPUT' } @{ $rl->{decisions} }), 'T-PLAN-021c decision NEEDS_USER_INPUT recorded');
    }

    # T-PLAN-022 performance: mechanical count + carried W-PERF warning (mandated #22)
    {
        my $d5 = "  required_data:\n"
            . join('', map { "    - { kind: 'htf price', symbol_hint: null, timeframe: '1h', notes: 'd$_' }\n" } 1 .. 5);
        my $c5 = $fx->('  required_data: []' => $d5, '  mtf: false' => '  mtf: true');
        my $FEAS_D5 = $run_feas->($c5, $PRE);
        my $r5d = $plan->($c5, $PRE, $FEAS_D5);
        $ok->((grep { ($_->{code} // '') =~ /^W-PERF/ } @{ $r5d->{warnings} }), 'T-PLAN-022a carried W-PERF warning');
        $ok->((grep { ($_->{element} // '') =~ /W-PERF/ } @{ $r5d->{performance_plan} }), 'T-PLAN-022b carried warning in performance plan');
        $ok->((grep { ($_->{element} // '') eq 'request.* boundaries' } @{ $r5d->{performance_plan} }), 'T-PLAN-022c mechanical data count');
    }

    # T-PLAN-023 deterministic planning_id; content-sensitive (mandated #23)
    {
        my ($ra, $rb) = ($plan->($BASE_C, $PRE, $FEAS_OK), $plan->($BASE_C, $PRE, $FEAS_OK));
        $ok->($ra->{planning_id} eq $rb->{planning_id}, 'T-PLAN-023a id stable');
        my $rc = $plan->($fx->("    chart: '15m'" => "    chart: '1h'"), $PRE, $run_feas->($fx->("    chart: '15m'" => "    chart: '1h'"), $PRE));
        $ok->($ra->{planning_id} ne $rc->{planning_id}, 'T-PLAN-023b id content-sensitive');
        $ok->($ra->{planning_id} =~ /^plan-[0-9a-f]{12}$/, 'T-PLAN-023c id well-formed');
    }

    # T-PLAN-024 byte-identical repeated output (mandated #24)
    {
        my ($ra, $rb) = ($plan->($BASE_C, $PRE, $FEAS_OK), $plan->($BASE_C, $PRE, $FEAS_OK));
        $ok->(plan_to_yaml($ra) eq plan_to_yaml($rb), 'T-PLAN-024 byte-identical');
    }

    # T-PLAN-025 NO-PINE output invariant (mandated #25)
    {
        my $out = plan_to_yaml($r1);
        my $pine_free = 1;
        for my $tok ('//@version', 'indicator(', 'strategy(', 'library(', 'ta.sma', 'ta.rsi') { $pine_free = 0 if index($out, $tok) >= 0; }
        $ok->($pine_free, 'T-PLAN-025 no Pine constructs in plan');
    }

    # T-PLAN-026 downstream --gate-check (mandated #26)
    {
        my ($fh1, $p1) = File::Temp::tempfile(SUFFIX => '.yaml');
        binmode $fh1, ':raw'; print $fh1 encode('UTF-8', plan_to_yaml($r1)); close $fh1;
        my ($okg, $msgg) = gate_check_text(_slurp($p1));
        $ok->($okg && $msgg =~ /approved_plan_id = plan-[0-9a-f]{12}/, 'T-PLAN-026a gate approves READY');
        my ($fh2, $p2) = File::Temp::tempfile(SUFFIX => '.yaml');
        binmode $fh2, ':raw'; print $fh2 encode('UTF-8', plan_to_yaml($r3)); close $fh2;
        my ($okb, $msgb) = gate_check_text(_slurp($p2));
        $ok->(!$okb && $msgb =~ /forbidden|non-empty|malformed/, 'T-PLAN-026b gate refuses BLOCKED');
        1 while unlink $p1; 1 while unlink $p2;
    }

    # T-PLAN-027 state architecture: crossover mechanics + documented semantics (mandated #27)
    {
        my ($st) = grep { ($_->{subject} // '') =~ /crossover/ } @{ $r1->{state_architecture} };
        $ok->((defined $st && grep { $_ eq 'C-1' } @{ $st->{refs} }), 'T-PLAN-027a state refs trace to C-1');
        $ok->(defined $st && $st->{lifecycle} =~ /recalc-and-rollback/, 'T-PLAN-027b documented execution semantics verbatim');
        $ok->((grep { ($_->{subject} // '') =~ /edge-case/ } @{ $r1->{state_architecture} }), 'T-PLAN-027c edge cases in state architecture');
    }

    print "SELFTEST: $pass passed, $fail failed\n";
    print "All TEST-PLAN-001..027 acceptance cases pass (implementation planning contract v1.1).\n" if !$fail;
    return $fail ? 1 : 0;
}

main() unless caller;

1;
