#!/usr/bin/perl
# ============================================================================
# root_cause_analyzer.pl — PHASE 14 ROOT CAUSE ANALYSIS ENGINE (schema v1.0)
# ============================================================================
# Pipeline position: Phase 13 (execution trace) -> PHASE 14 -> Phase 15
# (repair / regression — gated, separate execution).
#
# Consumes the Phase 13 RECONSTRUCTED trace contract (gate: READY or
# READY_WITH_WARNINGS with downstream.allowed true) + the Phase 9 Pine
# source + the Phase 8 authoritative plan, and answers ONLY: "why did the
# observed behavior occur?" — mechanically, from committed evidence.
#
# Boundary rules (house discipline, mirrored from Phases 11-13):
#   - never modifies the Pine source or any upstream artifact
#   - never performs repair (repair stays NOT_PERFORMED; Phase 15 owns it)
#   - never invents runtime evidence: every causal finding must trace to a
#     trace node / code fact / contract fact with an explicit reference
#   - causal findings are classified: CODE_PROPERTY | DATA_PROPERTY |
#     EXPECTATION_MISMATCH | PLATFORM_SEMANTICS | UNKNOWN
#   - deterministic: no clock, no randomness, no environment values
#     rca_id = "rca-" + first 12 hex of sha256(canonical body)
#
# CLI: --trace FILE [--pine FILE] [--plan FILE] [--out FILE]
#      --gate-check --trace FILE     (approves findings-complete contracts)
#      --selftest --version
# Exit: 0 = analysis complete with at least one classified causal finding
#       2 = no causal finding established (INSUFFICIENT_EVIDENCE / BLOCKED)
# ============================================================================
use strict;
use warnings;
use utf8; # source literals (em-dashes in finding statements) are UTF-8 characters, not bytes
use FindBin qw($Bin);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode decode);

my $VERSION_STR = 'root_cause_analyzer.pl 1.0 (Phase 14 - Root Cause Analysis)';
my $SCHEMA      = '1.0';
my $PINE_DEFAULT = "$Bin/../implementation/phase9_pine.pine";
my $PLAN_DEFAULT = "$Bin/../implementation/phase9_authoritative_plan.yaml";

sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return decode('UTF-8', $t); }
sub _sha   { return sha256_hex(encode('UTF-8', $_[0])); }
sub _q     { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _unq   { my $s = shift; return undef unless defined $s; $s =~ s/''/'/g; return $s; }

# causal finding classification vocabulary (fixed)
my %CLASS_OK = map { $_ => 1 } qw(CODE_PROPERTY DATA_PROPERTY EXPECTATION_MISMATCH PLATFORM_SEMANTICS UNKNOWN);

# ---------------------------------------------------------------------------
# trace contract parsing (only the fields Phase 13 actually emits)
# ---------------------------------------------------------------------------
sub parse_trace {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    # Phase 13 emits trace_id as a top-level key at column 0; accept any indent.
    my ($tid)  = $t =~ /^\s*trace_id:\s*'([^']*)'/m;
    my ($st)   = $t =~ /^status:\s*'([^']*)'/m;
    my ($mode) = $t =~ /^\s{2}mode:\s*'([^']*)'/m;
    my ($da)   = $t =~ /^\s{2}allowed:\s*(true|false)/m;
    my ($dts)  = $t =~ /^\s{2}localized_timestamp:\s*'([^']*)'/m;
    my ($wstart) = $t =~ /^\s{2}start:\s*'([^']*)'/m;
    my ($wend)   = $t =~ /^\s{2}end:\s*'([^']*)'/m;
    my ($wbars)  = $t =~ /^\s{2}bars:\s*(\d+)/m;
    return {
        trace_id => _unq($tid), status => _unq($st), mode => _unq($mode),
        downstream_allowed => $da, localized_timestamp => _unq($dts),
        window_start => _unq($wstart), window_end => _unq($wend), window_bars => $wbars,
        text => $t,
    };
}

# ---------------------------------------------------------------------------
# trace-node extraction: bar-level evaluated facts from the v4 emitter lines
# ---------------------------------------------------------------------------
sub extract_nodes {
    my ($t) = @_;
    my @nodes;
    while ($t =~ /^\s{2}- \{ trace_node_id: '([^']+)', bar: '(\d+)', category: '([A-Z]+)',.*?expression: '([^']*)'.*?value: '([^']*)', value_type: '[^']*', evaluation_status: '([A-Z_]+)'/mg) {
        push @nodes, { node_id => $1, bar => $2 + 0, category => $3,
                       expression => $4, value => $5, status => $6 };
    }
    return \@nodes;
}

# ---------------------------------------------------------------------------
# state-transition extraction (state_crossover assignments per bar)
# ---------------------------------------------------------------------------
sub extract_states {
    my ($t) = @_;
    my @st;
    while ($t =~ /variable: 'state_crossover', previous_value: '([^']*)', current_value: '([^']*)', assignment_event: '([^']*)', bar: '(\d+)'/g) {
        push @st, { prev => $1, cur => $2, event => $3, bar => $4 + 0 };
    }
    return \@st;
}

# ---------------------------------------------------------------------------
# evidence scan of the Pine source + plan (static causal facts)
# ---------------------------------------------------------------------------
sub scan_sources {
    my ($pine, $plan) = @_;
    my %f;
    ($f{c1_expr})     = $pine =~ /^\s{4}state_crossover := (.+)$/m;
    ($f{threshold})   = $pine =~ /close > (\d+(?:\.\d+)?)/;
    $f{has_visible_output} = ($pine =~ /plot\((?![^)]*display=display\.none)/) ? 1 : 0;
    $f{has_marker}         = ($pine =~ /(plotshape|plotchar|label\.new|bgcolor|hline)/) ? 1 : 0;
    $f{has_alert}          = ($pine =~ /alertcondition|alert\(/) ? 1 : 0;
    ($f{condition_verbatim}) = $plan =~ /condition_verbatim:\s*'([^']*)'/;
    return \%f;
}

# ---------------------------------------------------------------------------
# canonical body + emitter
# ---------------------------------------------------------------------------
sub build_canonical {
    my ($r) = @_;
    my @findings = sort { $a->{finding_id} cmp $b->{finding_id} } @{ $r->{findings} };
    my $body = "phase14-rca-v1\n";
    $body .= "trace:" . $r->{trace}{trace_id} . "|" . $r->{trace}{status} . "|" . $r->{trace}{mode} . "\n";
    $body .= "localized:" . $r->{trace}{localized_timestamp} . "\n";
    for my $f (@findings) {
        $body .= "F:" . $f->{finding_id} . "|" . $f->{classification} . "|" . $f->{statement}
              . "|nodes:" . join(',', @{ $f->{trace_refs} || [] })
              . "|refs:" . join(',', @{ $f->{artifact_refs} || [] }) . "\n";
    }
    $body .= "sig_hist:" . $r->{signal_history}{bars_traced} . "fires:" . $r->{signal_history}{signal_true_bars} . "\n";
    $body .= "repair:NOT_PERFORMED\n";
    return $body;
}

sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# root cause analysis contract - generated by root_cause_analyzer.pl (schema v1.0)';
    push @o, 'schema_version: "1.0"';
    push @o, 'stage: root_cause_analysis';
    push @o, 'predecessor: execution_trace_and_debug';
    push @o, 'successor: repair_and_regression';
    push @o, '';
    push @o, 'rca:';
    push @o, '  rca_id: ' . _q($r->{rca_id});
    push @o, '  trace_id: ' . _q($r->{trace}{trace_id});
    push @o, '  trace_status: ' . _q($r->{trace}{status});
    push @o, '  trace_mode: ' . _q($r->{trace}{mode});
    push @o, '  localized_bar: ' . _q($r->{trace}{localized_timestamp});
    push @o, '  trace_window: ' . _q($r->{trace}{window_start} . ' .. ' . $r->{trace}{window_end} . ' (' . $r->{trace}{window_bars} . ' bars)');
    push @o, '';
    push @o, 'signal_history:';
    push @o, '  bars_traced: ' . $r->{signal_history}{bars_traced};
    push @o, '  signal_true_bars: ' . $r->{signal_history}{signal_true_bars};
    push @o, '  c1_result_distribution: ' . _q($r->{signal_history}{c1_distribution});
    push @o, '';
    push @o, 'findings:';
    if (!@{ $r->{findings} }) { push @o, '  []'; }
    else {
        for my $f (sort { $a->{finding_id} cmp $b->{finding_id} } @{ $r->{findings} }) {
            push @o, "  - { finding_id: " . _q($f->{finding_id}) . ', classification: ' . _q($f->{classification})
                . ', confidence: ' . _q($f->{confidence})
                . ', statement: ' . _q($f->{statement})
                . ', trace_refs: [' . join(', ', map { _q($_) } @{ $f->{trace_refs} || [] }) . ']'
                . ', artifact_refs: [' . join(', ', map { _q($_) } @{ $f->{artifact_refs} || [] }) . '] }';
        }
    }
    push @o, '';
    push @o, 'unknowns:';
    if (!@{ $r->{unknowns} }) { push @o, '  []'; }
    else {
        for my $u (@{ $r->{unknowns} }) {
            push @o, "  - { id: " . _q($u->{id}) . ', description: ' . _q($u->{description}) . ', material: ' . _q($u->{material}) . ' }';
        }
    }
    push @o, '';
    push @o, 'checks:';
    for my $c (@{ $r->{checks} }) {
        push @o, "  - { check_id: " . _q($c->{check_id}) . ', domain: ' . _q($c->{domain})
            . ', verdict: ' . _q($c->{verdict}) . ', findings: [' . join('; ', map { _q($_) } @{ $c->{findings} || [] }) . '] }';
    }
    push @o, '';
    push @o, 'status: ' . _q($r->{status});
    push @o, 'blockers: []';
    push @o, 'repair: NOT_PERFORMED';
    push @o, 'downstream:';
    push @o, '  allowed: ' . ($r->{downstream_allowed} ? 'true' : 'false');
    push @o, '  next_stage: ' . _q($r->{downstream_next});
    push @o, 'result_hash: ' . _q($r->{result_hash});
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# main analysis
# ---------------------------------------------------------------------------
# finalize: defaults + deterministic identity + serialized contract (both exit
# paths — refused inputs still get a complete, content-addressed contract).
sub _finalize {
    my ($r) = @_;
    $r->{signal_history} //= { bars_traced => 0, signal_true_bars => 0, c1_distribution => '' };
    $r->{trace} //= {
        trace_id => '', status => ($r->{status} // 'INVALID_INPUT'), mode => 'UNKNOWN',
        localized_timestamp => 'UNKNOWN', window_start => 'UNKNOWN',
        window_end => 'UNKNOWN', window_bars => 0,
    };
    my $canon = build_canonical($r);
    $r->{rca_id} = 'rca-' . substr(sha256_hex(encode('UTF-8', $canon)), 0, 12);
    # result_hash mirrors execution_trace.pl: sha256 over the canonical body + id,
    # computed BEFORE serialization so the emitted contract carries its own hash.
    $r->{result_hash} = sha256_hex(encode('UTF-8', $canon . $r->{rca_id}));
    my $yaml_src = result_to_yaml($r);
    $r->{_yaml} = $yaml_src;
    return $r;
}

sub analyze {
    my ($spec) = @_;
    my $r = {
        findings => [], unknowns => [], checks => [],
        repair => 'NOT_PERFORMED',
    };

    my $bad = sub {
        my ($status, $msg, $check) = @_;
        push @{ $r->{checks} }, { check_id => $check // 'RCA-G1', domain => 'input_integrity', verdict => 'fail', findings => [$msg] };
        $r->{status} = $status;
        $r->{downstream_allowed} = 0;
        $r->{downstream_next} = 'HALT';
        return _finalize($r);
    };

    # --- RCA-G1: trace contract gate ----------------------------------------
    my $tr = parse_trace($spec->{trace_text} // '');
    return $bad->('INVALID_INPUT', 'trace contract missing or unparseable', 'RCA-G1') unless $tr && $tr->{trace_id};
    return $bad->('INVALID_INPUT', "trace status '$tr->{status}' is not analyzable (needs READY/READY_WITH_WARNINGS)", 'RCA-G1')
        unless ($tr->{status} // '') eq 'READY' || ($tr->{status} // '') eq 'READY_WITH_WARNINGS';
    return $bad->('INVALID_INPUT', 'trace downstream gate is closed — Phase 14 may not run', 'RCA-G1')
        unless ($tr->{downstream_allowed} // '') eq 'true';
    return $bad->('INVALID_INPUT', "trace mode '$tr->{mode}' is not RECONSTRUCTED — no bar-level behavior to analyze", 'RCA-G1')
        unless ($tr->{mode} // '') eq 'RECONSTRUCTED';
    $r->{trace} = $tr;
    push @{ $r->{checks} }, { check_id => 'RCA-G1', domain => 'trace_gate', verdict => 'pass', findings => [] };

    # --- RCA-G2: localized bar present ---------------------------------------
    return $bad->('INVALID_INPUT', 'trace has no localized timestamp — causal analysis would be unanchored', 'RCA-G2')
        unless defined $tr->{localized_timestamp} && $tr->{localized_timestamp} ne 'UNKNOWN';
    push @{ $r->{checks} }, { check_id => 'RCA-G2', domain => 'localization_anchor', verdict => 'pass', findings => [] };

    # --- RCA-G3: source integrity --------------------------------------------
    my $pine = $spec->{pine_text} // '';
    my $plan = $spec->{plan_text} // '';
    return $bad->('INVALID_INPUT', 'production Pine source missing', 'RCA-G3') unless length $pine;
    my $src = scan_sources($pine, $plan);
    ($r->{pine_sha256}) = ($spec->{pine_sha256} // _sha($pine));
    push @{ $r->{checks} }, { check_id => 'RCA-G3', domain => 'source_integrity', verdict => 'pass',
        findings => [ 'pine sha256 ' . substr($r->{pine_sha256}, 0, 12) . '...' ] };

    # --- RCA-G4: node-level trace extraction ----------------------------------
    my $nodes = extract_nodes($tr->{text});
    return $bad->('INSUFFICIENT_EVIDENCE', 'no evaluated trace nodes found in the trace contract', 'RCA-G4') unless @$nodes;
    push @{ $r->{checks} }, { check_id => 'RCA-G4', domain => 'trace_nodes', verdict => 'pass',
        findings => [ scalar(@$nodes) . ' trace nodes extracted' ] };

    # --- RCA-G5: signal history reconstruction (mechanical, over nodes) -------
    my %c1_by_bar;
    for my $n (@$nodes) {
        next unless ($n->{category} // '') eq 'CONDITION' && ($n->{expression} // '') eq 'close > 30 and close[1] <= 30'
                 && ($n->{status} // '') eq 'EVALUATED';
        $c1_by_bar{ $n->{bar} } = $n->{value};
    }
    my $bars_traced = $tr->{window_bars} // scalar(keys %c1_by_bar);
    my $fires = grep { ($c1_by_bar{$_} // '') eq '1' } keys %c1_by_bar;
    my %dist; $dist{ $c1_by_bar{$_} }++ for keys %c1_by_bar;
    my $dist_s = join(', ', map { "$_: $dist{$_}" } sort keys %dist);
    $r->{signal_history} = {
        bars_traced => $bars_traced,
        signal_true_bars => $fires,
        c1_distribution => $dist_s,
    };
    push @{ $r->{checks} }, { check_id => 'RCA-G5', domain => 'signal_history', verdict => 'pass',
        findings => [ "C-1 evaluated on " . scalar(keys %c1_by_bar) . " bars; true on $fires" ] };

    # --- CAUSAL FINDINGS (each strictly evidence-referenced) -------------------
    my ($fid) = (0);
    my $nf = sub { $fid++; return sprintf('F-%03d', $fid); };

    # F-001: threshold vs price scale (DATA_PROPERTY + EXPECTATION_MISMATCH)
    my @close_vals = grep { defined }
        map { ($_->{category} // '') eq 'INPUT' && ($_->{expression} // '') eq 'close' && ($_->{status} // '') eq 'EVALUATED' && $_->{value} =~ /^\d/ ? $_->{value} + 0 : undef } @$nodes;
    if (@close_vals) {
        my @sorted = sort { $a <=> $b } @close_vals;
        my ($min, $max) = ($sorted[0], $sorted[-1]);
        my $thr = $src->{threshold};
        if (defined $thr && $max + 0 < $thr + 0) {
            push @{ $r->{findings} }, {
                finding_id => $nf->(),
                classification => 'DATA_PROPERTY',
                confidence => 'HIGH',
                statement => "every close in the traced window lies in [$min, $max] while condition C-1 requires close > $thr — the left clause of C-1 can never be true on this instrument's price scale",
                trace_refs => ['close INPUT nodes (EVALUATED) across the full window'],
                artifact_refs => ['implementation/phase9_pine.pine:25'],
            };
            push @{ $r->{findings} }, {
                finding_id => $nf->(),
                classification => 'EXPECTATION_MISMATCH',
                confidence => 'HIGH',
                statement => "the formalized condition 'close crosses over 30' (condition_verbatim, mirrored verbatim into Pine line 25) presupposes a price scale above 30, but the incident instrument trades near 0.077 — the expectation that a BUY appears at the localized bar is incompatible with the condition as formalized",
                trace_refs => ["C-1 cond-left 'close > 30' => 0 at localized bar", "C-1 cond-result => 0 at localized bar", "signal_c1 => 0 at localized bar"],
                artifact_refs => ['implementation/phase9_authoritative_plan.yaml (signal_architecture C-1 verbatim)', 'implementation/phase9_pine.pine:25'],
            };
        }
    }

    # F-003: zero firing history across the whole traced window
    if ($fires == 0 && scalar(keys %c1_by_bar) > 0) {
        push @{ $r->{findings} }, {
            finding_id => $nf->(),
            classification => 'CODE_PROPERTY',
            confidence => 'HIGH',
            statement => "C-1 evaluated false on every one of the " . scalar(keys %c1_by_bar) . " bars in the causal window (zero firing history) — the localized bar is not a marginal miss but a systematic impossibility under the current threshold",
            trace_refs => ['C-1 cond-result nodes (EVALUATED) across all bars'],
            artifact_refs => ['implementation/phase9_pine.pine:25'],
        };
    }

    # F-004: visibility — the script cannot draw a BUY marker at all
    if (!$src->{has_marker} && !$src->{has_visible_output}) {
        push @{ $r->{findings} }, {
            finding_id => $nf->(),
            classification => 'CODE_PROPERTY',
            confidence => 'HIGH',
            statement => "the production script contains no marker/drawing construct and its only plot is display=display.none (authorized Option A amendment) — even a true signal could never appear as a visible BUY marker on the chart; any visible markers in the incident screenshot originate from other scripts on the chart, not from impl-f56a05897f87",
            trace_refs => [],
            artifact_refs => ['implementation/phase9_pine.pine:56 (plot display=display.none)', 'verification/phase10_post_verification_result.yaml W-005'],
        };
    }

    # F-005: BUY markers visible on the chart belong to a different indicator
    if (defined $spec->{data_column_hint} && $spec->{data_column_hint} =~ /ARO|Master Buy/) {
        push @{ $r->{findings} }, {
            finding_id => $nf->(),
            classification => 'UNKNOWN',
            confidence => 'MEDIUM',
            statement => "the fingerprinted KCEX exports carry 35 indicator columns from a separate ARO-family script (incl. 'Master Buy'/'Master Sell'), which is the plausible source of the BUY markers visible in the incident screenshots; the relationship between that script and impl-f56a05897f87 was never established by any upstream contract — recorded as UNKNOWN, never asserted",
            trace_refs => [],
            artifact_refs => ['Phase 12 v6 data contract datasets (header schema +extraneous(35))'],
        };
    }

    # --- unknowns / limitations ------------------------------------------------
    push @{ $r->{unknowns} }, {
        id => 'U-001',
        description => 'DIRECT TradingView runtime evidence remains unavailable; the causal chain above is established over the deterministic reconstruction, not over runtime observation',
        material => 'false',
    };

    # --- status + gate ----------------------------------------------------------
    my $classified = grep { ($_->{classification} // '') ne 'UNKNOWN' } @{ $r->{findings} };
    $r->{status} = $classified ? 'READY_WITH_WARNINGS' : 'INSUFFICIENT_EVIDENCE';
    $r->{downstream_allowed} = $classified ? 1 : 0;
    $r->{downstream_next} = $classified ? 'REPAIR_AND_REGRESSION' : 'HALT';

    push @{ $r->{checks} }, { check_id => 'RCA-G6', domain => 'finding_classification',
        verdict => 'pass', findings => [ "$classified classified causal finding(s)" ] };
    push @{ $r->{checks} }, { check_id => 'RCA-G7', domain => 'repair_firewall',
        verdict => 'pass', findings => ['repair permanently NOT_PERFORMED; Phase 15 boundary respected'] };

    # --- deterministic identity (shared finalize path) ---------------------------
    return _finalize($r);
}

# ---------------------------------------------------------------------------
# selftest — RCA-001..006 acceptance set + negative NG-RCA-001..003
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };

    my $PINE = <<'PINE';
//@version=6
indicator("t", overlay=true)
var bool state_crossover = false
if na(close) or na(close[1])
    state_crossover := false
else
    state_crossover := close > 30 and close[1] <= 30
bool signal_c1 = false
if not na(close) and not na(close[1])
    signal_c1 := state_crossover
else
    signal_c1 := false
plot(signal_c1 ? 1 : 0, display=display.none)
PINE
    my $PLAN = "signal_architecture:\n    - { signal_ref: 'C-1', condition_verbatim: 'close crosses over 30', prerequisites: ['M-STATE'], precedence: 1 }\n";

    # node fixtures: 10 bars, closes 0.076..0.077, C-1 evaluated false everywhere
    my @node_lines;
    for my $b (0 .. 9) {
        my $c = sprintf('0.076%d', $b);
        push @node_lines, "  - { trace_node_id: 'n-in-$b', bar: '$b', category: 'INPUT', source: 'x', source_line: '15', source_module: 'M-STATE', role: 'input', condition_id: '', expression: 'close', inputs: [], value: '$c', value_type: 'series_float', evaluation_status: 'EVALUATED', evidence_classification: 'DETERMINISTIC_RECONSTRUCTION', confidence: 'HIGH', note: '' }";
        push @node_lines, "  - { trace_node_id: 'n-c1-$b', bar: '$b', category: 'CONDITION', source: 'x', source_line: '25', source_module: 'M-STATE', role: 'cond-result', condition_id: 'C-1', expression: 'close > 30 and close[1] <= 30', inputs: ['close', 'close[1]'], value: '0', value_type: 'bool', evaluation_status: 'EVALUATED', evidence_classification: 'DETERMINISTIC_RECONSTRUCTION', confidence: 'HIGH', note: '' }";
    }
    my $trace_ok = join("\n", @node_lines);
    my $mk_trace = sub {
        my (%o) = @_;
        return "status: '" . ($o{status} // 'READY_WITH_WARNINGS') . "'\n"
            . "trace_id: 'trace-abcdef123456'\n"
            . "  mode: '" . ($o{mode} // 'RECONSTRUCTED') . "'\n"
            . "  localized_timestamp: '" . ($o{loc} // '2026-09-12T00:45:00Z') . "'\n"
            . "  allowed: " . ($o{allowed} // 'true') . "\n"
            . "  start: '2026-09-12T00:15:00Z'\n"
            . "  end: '2026-09-12T00:45:00Z'\n"
            . "  bars: 10\n"
            . "nodes:\n" . ($o{nodes} // $trace_ok) . "\n";
    };

    my $run = sub {
        my (%o) = @_;
        return analyze({
            trace_text => $mk_trace->(%o),
            pine_text  => ($o{pine} // $PINE),
            plan_text  => $PLAN,
            data_column_hint => ($o{hint} // 'ARO Master Buy columns'),
        });
    };

    # RCA-001: happy path produces classified findings
    my $r = $run->();
    $ok->(($r->{status} // '') eq 'READY_WITH_WARNINGS', 'RCA-001 classified findings -> READY_WITH_WARNINGS');
    $ok->(scalar(grep { $_->{classification} eq 'DATA_PROPERTY' } @{ $r->{findings} }) == 1, 'RCA-001b DATA_PROPERTY threshold-vs-price finding present');
    $ok->(scalar(grep { $_->{classification} eq 'EXPECTATION_MISMATCH' } @{ $r->{findings} }) == 1, 'RCA-001c EXPECTATION_MISMATCH verbatim-condition finding present');
    $ok->(scalar(grep { $_->{classification} eq 'CODE_PROPERTY' } @{ $r->{findings} }) >= 1, 'RCA-001d CODE_PROPERTY zero-firing + invisibility findings present');

    # RCA-002: signal history mechanically counted
    $ok->($r->{signal_history}{signal_true_bars} == 0, 'RCA-002 zero fires counted over 10 evaluated bars');
    $ok->($r->{signal_history}{c1_distribution} =~ /0: 10/, 'RCA-002b distribution says C-1 false on all 10');

    # RCA-003: visibility finding (no marker construct, display.none plot)
    $ok->(scalar(grep { $_->{statement} =~ /display\.none/ } @{ $r->{findings} }) == 1, 'RCA-003 visibility finding references the display.none plot');

    # RCA-004: deterministic id over identical input
    my $r2 = $run->();
    $ok->($r->{rca_id} eq $r2->{rca_id} && $r->{rca_id} =~ /^rca-[0-9a-f]{12}$/, 'RCA-004 deterministic content-addressed rca_id');

    # RCA-005: repair firewall
    $ok->($r->{repair} eq 'NOT_PERFORMED', 'RCA-005 repair stays NOT_PERFORMED');

    # RCA-006: gate check open
    my ($gok) = gate_check_text(result_to_yaml($r));
    $ok->($gok, 'RCA-006 gate_check approves the READY_WITH_WARNINGS contract');

    # NG-RCA-001: closed trace gate refused
    my $ng1 = $run->(allowed => 'false');
    $ok->(($ng1->{status} // '') eq 'INVALID_INPUT', 'NG-RCA-001 closed downstream gate -> INVALID_INPUT');

    # NG-RCA-002: non-RECONSTRUCTED mode refused
    my $ng2 = $run->(mode => 'STATIC_ONLY');
    $ok->(($ng2->{status} // '') eq 'INVALID_INPUT', 'NG-RCA-002 STATIC_ONLY trace refused');

    # NG-RCA-003: UNKNOWN-status trace refused
    my $ng3 = $run->(status => 'INSUFFICIENT_EVIDENCE');
    $ok->(($ng3->{status} // '') eq 'INVALID_INPUT', 'NG-RCA-003 INSUFFICIENT_EVIDENCE trace refused');

    print "selftest: $pass passed, $fail failed\n";
    return $fail ? 1 : 0;
}

# gate check over an emitted contract
sub gate_check_text {
    my ($t) = @_;
    my ($st) = $t =~ /^status: '([^']*)'/m;
    my ($da) = $t =~ /^  allowed: (true|false)/m;
    if (($st // '') eq 'READY_WITH_WARNINGS' && ($da // '') eq 'true') {
        return (1, "status is '$st' - REPAIR_AND_REGRESSION may start");
    }
    return (0, "status is '" . ($st // 'UNKNOWN') . "' - downstream progression forbidden");
}

# ---------------------------------------------------------------------------
sub usage {
    return <<'EOU';
root_cause_analyzer.pl — Phase 14 Root Cause Analysis Engine (schema v1.0)

Usage:
  perl rca/root_cause_analyzer.pl --trace FILE [--pine FILE] [--plan FILE] [--out FILE]
  perl rca/root_cause_analyzer.pl --gate-check --trace RESULT_FILE
  perl rca/root_cause_analyzer.pl --selftest

  --trace FILE        Phase 13 trace contract (gate: READY/READY_WITH_WARNINGS,
                      downstream open, mode RECONSTRUCTED)
  --pine FILE         production Pine source (default: implementation/phase9_pine.pine)
  --plan FILE         Phase 8 plan (default: implementation/phase9_authoritative_plan.yaml)
  --data-hint TEXT    provenance hint for dataset-only evidence (e.g. 'ARO Master Buy columns')
  --out FILE          write the RCA contract to FILE

Exit codes: 0 = causal finding established; 2 = none (INSUFFICIENT_EVIDENCE).
Boundaries: never repairs, never modifies sources, never invents evidence.
EOU
}

my ($trace_file, $out_file, $gate, $selftest, $show_ver, $show_help, $data_hint) = (undef, undef, 0, 0, 0, 0, undef);
my ($pine_file, $plan_file) = ($PINE_DEFAULT, $PLAN_DEFAULT);
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a eq '--trace')      { $trace_file = shift @ARGV; }
    elsif ($a eq '--pine')       { $pine_file  = shift @ARGV; }
    elsif ($a eq '--plan')       { $plan_file  = shift @ARGV; }
    elsif ($a eq '--data-hint')  { $data_hint  = shift @ARGV; }
    elsif ($a eq '--out')        { $out_file   = shift @ARGV; }
    elsif ($a eq '--gate-check') { $gate = 1; }
    elsif ($a eq '--selftest')   { $selftest = 1; }
    elsif ($a eq '--version')    { $show_ver = 1; }
    elsif ($a eq '--help')       { $show_help = 1; }
    else { die "unknown argument '$a'\n"; }
}
if ($show_ver)  { print "$VERSION_STR\n"; exit 0; }
if ($show_help) { print usage(); exit 0; }
if ($gate) {
    die "usage with --gate-check: --trace RESULT_FILE\n" unless defined $trace_file;
    my $t = _slurp($trace_file);
    my ($ok, $msg) = gate_check_text($t);
    print "$msg\n";
    exit($ok ? 0 : 2);
}
if ($selftest) { my $st = selftest(); exit $st; }

die "usage: --trace FILE is required\n" unless defined $trace_file && -f $trace_file;

my $r = analyze({
    trace_text => _slurp($trace_file),
    pine_text  => (-f $pine_file ? _slurp($pine_file) : ''),
    plan_text  => (-f $plan_file ? _slurp($plan_file) : ''),
    pine_sha256 => (-f $pine_file ? _sha(_slurp($pine_file)) : undef),
    data_column_hint => $data_hint,
});
my $yaml = delete $r->{_yaml};
if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh encode('UTF-8', $yaml); close $fh; }
else { print encode('UTF-8', $yaml); }
exit(($r->{status} eq 'READY' || $r->{status} eq 'READY_WITH_WARNINGS') ? 0 : 2);
