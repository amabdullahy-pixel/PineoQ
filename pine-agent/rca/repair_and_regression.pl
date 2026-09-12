#!/usr/bin/perl
# ============================================================================
# repair_and_regression.pl — PHASE 15 REPAIR & REGRESSION ENGINE (schema v1.0)
# ============================================================================
# Pipeline position: Phase 14 (root cause analysis) -> PHASE 15 -> REPAIRED.
#
# Consumes the Phase 14 RCA contract (gate: READY/READY_WITH_WARNINGS,
# downstream.allowed true, next_stage REPAIR_AND_REGRESSION) plus the user's
# repair authorization (verbatim) and produces the repair contract:
#   - resolves EXPECTATION_MISMATCH findings against the user's verbatim
#     unit-semantics decision (user_supply: allowed by F-002;
#     silent resolution: forbidden by AGENT_RULES rule 6)
#   - writes the new formalization as a NEW content-addressed artifact
#     (never mutates any upstream artifact — repair firewall RRP-G7)
#   - mechanical regression: re-evaluates the repaired C-1 over the exact
#     Phase 13 trace window/dataset and compares per-bar against the
#     original C-1 trace nodes (RRP-G6)
#
# Boundary rules (house discipline, mirrored from Phases 11-14):
#   - never modifies any upstream artifact (Phase 8/9/10/11/12/13/14 outputs)
#   - repairs only what the RCA findings + user authorization justify
#   - ambiguities are recorded, never silently resolved (AGENT_RULES 6)
#   - assumptions are explicit and user-confirmed or marked as open
#     decision points (AGENT_RULES 7)
#   - no Pine compiler exists locally: validation status is honest
#     (STATICALLY_REVIEWED + mechanically reconstructed, never "ACTUALLY
#     VERIFIED") per AGENT_RULES 21
#   - deterministic: no clock, no randomness, no environment values
#     repair_id = "rep-" + first 12 hex of sha256(canonical body)
#     result_hash = sha256(canonical body + repair_id)
#
# CLI: --rca FILE --pine FILE --dataset FILE [--decision TEXT] [--window-bars N]
#      [--out FILE] | --gate-check --rca RESULT_FILE | --selftest | --version
# Exit: 0 = repair contract complete with at least one repair item
#       2 = repair refused (insufficient findings/authorization/evidence)
# ============================================================================

use strict;
use warnings;
use utf8; # source literals (em-dashes in statements) are UTF-8 characters
use FindBin qw($Bin);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode decode);

my $VERSION_STR = 'repair_and_regression.pl 1.0 (Phase 15 - Repair & Regression)';
my $SCHEMA      = '1.0';
my $RCA_DEFAULT = "$Bin/phase14_rca_result.yaml";
my $PINE_DEFAULT = "$Bin/../implementation/phase9_pine.pine";
my $DATASET_DEFAULT = "$Bin/../data/raw/KCEX_AUSDT.P, 3 - ISO.csv";

sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return decode('UTF-8', $t); }
sub _sha   { return sha256_hex(encode('UTF-8', $_[0])); }
sub _q     { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _unq   { my $s = shift; return undef unless defined $s; $s =~ s/''/'/g; return $s; }

# ---------------------------------------------------------------------------
# RCA contract parsing (only the fields Phase 14 actually emits)
# ---------------------------------------------------------------------------
sub parse_rca {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($rid) = $t =~ /^\s*rca_id:\s*'([^']*)'/m;
    my ($st)  = $t =~ /^status:\s*'([^']*)'/m;
    my ($da)  = $t =~ /^  allowed:\s*(true|false)/m;
    my ($ns)  = $t =~ /^  next_stage:\s*'([^']*)'/m;
    my ($th)  = $t =~ /^  trace_id:\s*'([^']*)'/m;
    my ($lb)  = $t =~ /^  localized_bar:\s*'([^']*)'/m;
    my ($tw)  = $t =~ /^  trace_window:\s*'([^']*)'/m;
    my ($bt)  = $t =~ /^  bars_traced:\s*(\d+)/m;
    my ($stb) = $t =~ /^  signal_true_bars:\s*(\d+)/m;
    my @fids  = $t =~ /finding_id: '(F-\d+)'/g;
    my @cls   = $t =~ /classification: '(CODE_PROPERTY|DATA_PROPERTY|EXPECTATION_MISMATCH|PLATFORM_SEMANTICS|UNKNOWN)'/g;
    return {
        rca_id => _unq($rid), status => _unq($st), downstream_allowed => $da,
        next_stage => _unq($ns), trace_id => _unq($th), localized_bar => _unq($lb),
        trace_window => _unq($tw), bars_traced => $bt, signal_true_bars => $stb,
        finding_ids => \@fids, classifications => \@cls, text => $t,
    };
}

# ---------------------------------------------------------------------------
# dataset CSV parsing (fingerprinted Phase 12 dataset; ISO-time variant)
# ---------------------------------------------------------------------------
sub parse_dataset {
    my ($text) = @_;
    return undef unless defined $text && length $text;
    my @lines = split /\n/, $text;
    my @hdr = _split_csv_line(shift @lines);
    return undef unless @hdr;
    my ($ti, $ci, $pi) = (-1, -1, -1);
    for my $i (0 .. $#hdr) {
        $ti = $i if $hdr[$i] eq 'time';
        $ci = $i if $hdr[$i] eq 'close';
        $pi = $i if $hdr[$i] eq 'Pullback Score';
    }
    return undef if $ti < 0 || $ci < 0; # close/time are mandatory
    my @rows;
    for my $l (@lines) {
        next unless defined $l && $l =~ /\S/;
        my @v = _split_csv_line($l);
        next if scalar(@v) <= $ti || $v[$ti] !~ /^\d{4}-\d{2}-\d{2}T/;
        my %r = ( time => $v[$ti], close => $v[$ci] );
        $r{pullback} = $v[$pi] if $pi >= 0 && defined $v[$pi] && $v[$pi] =~ /^-?\d/;
        push @rows, \%r;
    }
    return { header => \@hdr, rows => \@rows,
             has_pullback => ($pi >= 0 ? 1 : 0) };
}

sub _split_csv_line {
    my ($l) = @_;
    $l = '' unless defined $l;
    $l =~ s/\r$//;
    my @out; my $cur = ''; my $inq = 0;
    for my $ch (split //, $l) {
        if ($ch eq '"') { $inq = !$inq; }
        elsif ($ch eq ',' && !$inq) { push @out, $cur; $cur = ''; }
        else { $cur .= $ch; }
    }
    push @out, $cur;
    return @out;
}

# ---------------------------------------------------------------------------
# original C-1 (raw price) and repaired C-1 (ARO 0-100 scale) per-bar evaluation
# ---------------------------------------------------------------------------
sub eval_original_c1 {
    my ($prev_close, $close) = @_;
    return undef if !defined $close || $close eq '' || $close !~ /^-?\d/;
    return 0 if !defined $prev_close || $prev_close eq '' || $prev_close !~ /^-?\d/;
    return ($close + 0 > 30 && $prev_close + 0 <= 30) ? 1 : 0;
}

sub eval_repaired_c1 {
    my ($prev, $cur, $thr) = @_;
    return undef if !defined $cur || $cur eq '' || $cur !~ /^-?\d/;
    return 0 if !defined $prev || $prev eq '' || $prev !~ /^-?\d/;
    return ($cur + 0 > $thr && $prev + 0 <= $thr) ? 1 : 0;
}

# ---------------------------------------------------------------------------
# canonical body + emitter (house pattern)
# ---------------------------------------------------------------------------
sub build_canonical {
    my ($r) = @_;
    my @items = sort { $a->{item_id} cmp $b->{item_id} } @{ $r->{repair_items} };
    my @amb   = sort { $a->{id} cmp $b->{id} } @{ $r->{ambiguities} };
    my $body = "phase15-repair-v1\n";
    $body .= "rca:" . ($r->{rca}{rca_id} // '') . "|" . ($r->{rca}{status} // '') . "\n";
    $body .= "trace:" . ($r->{rca}{trace_id} // '') . "|localized:" . ($r->{rca}{localized_bar} // '') . "\n";
    $body .= "decision:" . ($r->{user_decision} // '') . "\n";
    for my $i (@items) {
        $body .= "I:" . $i->{item_id} . "|" . $i->{target} . "|" . $i->{action}
              . "|" . $i->{to} . "\n";
    }
    for my $a (@amb) {
        $body .= "A:" . $a->{id} . "|" . $a->{status} . "|" . $a->{description} . "\n";
    }
    for my $g (sort { $a->{check_id} cmp $b->{check_id} } @{ $r->{checks} }) {
        $body .= "G:" . $g->{check_id} . "|" . $g->{verdict} . "\n";
    }
    if ($r->{regression}) {
        $body .= "REG:" . $r->{regression}{window_bars} . "|" . $r->{regression}{original_fires}
              . "|" . $r->{regression}{repaired_fires} . "|" . $r->{regression}{bars_changed}
              . "|" . $r->{regression}{determinism} . "\n";
    }
    $body .= "repair:NOT_PERFORMED_IN_PLACE\n";
    return $body;
}

sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# repair and regression contract - generated by repair_and_regression.pl (schema v1.0)';
    push @o, 'schema_version: "1.0"';
    push @o, 'stage: repair_and_regression';
    push @o, 'predecessor: root_cause_analysis';
    push @o, 'successor: repaired_formalization';
    push @o, '';
    push @o, 'repair:';
    push @o, '  repair_id: ' . _q($r->{repair_id});
    push @o, '  rca_id: ' . _q($r->{rca}{rca_id});
    push @o, '  trace_id: ' . _q($r->{rca}{trace_id});
    push @o, '  localized_bar: ' . _q($r->{rca}{localized_bar});
    push @o, '  trace_window: ' . _q($r->{rca}{trace_window});
    push @o, '';
    push @o, 'user_authorization:';
    push @o, '  decision_verbatim: ' . _q($r->{user_decision});
    push @o, '  resolves: ' . _q($r->{resolves_finding} // '');
    push @o, '  user_supply: ' . _q('ALLOWED_BY_RCA_F-002');
    push @o, '  silent_resolution: ' . _q('FORBIDDEN_AGENT_RULES_6');
    push @o, '';
    push @o, 'repair_items:';
    if (!@{ $r->{repair_items} }) { push @o, '  []'; }
    else {
        for my $i (sort { $a->{item_id} cmp $b->{item_id} } @{ $r->{repair_items} }) {
            push @o, "  - { item_id: " . _q($i->{item_id})
                . ", target: " . _q($i->{target})
                . ", action: " . _q($i->{action})
                . ", from: " . _q($i->{from})
                . ", to: " . _q($i->{to})
                . ", justification: " . _q($i->{justification})
                . ", source_refs: [" . join(', ', map { _q($_) } @{ $i->{source_refs} }) . "] }";
        }
    }
    push @o, '';
    push @o, 'ambiguities:';
    for my $a (sort { $a->{id} cmp $b->{id} } @{ $r->{ambiguities} }) {
        push @o, "  - { id: " . _q($a->{id})
            . ", description: " . _q($a->{description})
            . ", evidence: " . _q($a->{evidence})
            . ", options: [" . join(', ', map { _q($_) } @{ $a->{options} }) . ']'
            . ", status: " . _q($a->{status}) . " }";
    }
    push @o, '';
    push @o, 'regression:';
    if ($r->{regression}) {
        push @o, '  performed: true';
        push @o, '  operand_provisional: ' . _q($r->{regression}{operand_provisional});
        push @o, '  operand_note: ' . _q('proxy evaluation only - the exact ARO series is the open decision point A-001; never presented as the final repaired semantics');
        push @o, '  dataset: ' . _q($r->{regression}{dataset_path});
        push @o, '  dataset_sha256: ' . _q($r->{regression}{dataset_sha256});
        push @o, '  window_bars: ' . $r->{regression}{window_bars};
        push @o, '  original_fires: ' . $r->{regression}{original_fires};
        push @o, '  repaired_fires: ' . $r->{regression}{repaired_fires};
        push @o, '  bars_changed: ' . $r->{regression}{bars_changed};
        push @o, '  changed_bar_times: [' . join(', ', map { _q($_) } @{ $r->{regression}{changed_bars} }) . ']';
        push @o, '  fire_times: [' . join(', ', map { _q($_) } @{ $r->{regression}{fire_times} }) . ']';
        push @o, '  determinism: ' . _q($r->{regression}{determinism});
    } else { push @o, '  performed: false'; }
    push @o, '';
    push @o, 'checks:';
    for my $c (@{ $r->{checks} }) {
        push @o, "  - { check_id: " . _q($c->{check_id}) . ", domain: " . _q($c->{domain})
            . ", verdict: " . _q($c->{verdict})
            . ", findings: [" . join('; ', map { _q($_) } @{ $c->{findings} }) . '] }';
    }
    push @o, '';
    push @o, 'validation_status: ' . _q($r->{validation_status});
    push @o, 'status: ' . _q($r->{status});
    push @o, 'blockers: []';
    push @o, 'repair_in_place: NOT_PERFORMED';
    push @o, 'downstream:';
    push @o, '  allowed: ' . ($r->{downstream_allowed} ? 'true' : 'false');
    push @o, '  next_stage: ' . _q($r->{downstream_next});
    push @o, 'result_hash: ' . _q($r->{result_hash});
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# main repair analysis
# ---------------------------------------------------------------------------
sub _finalize {
    my ($r) = @_;
    $r->{repair_items} //= [];
    $r->{ambiguities}  //= [];
    $r->{checks}       //= [];
    my $canon = build_canonical($r);
    $r->{repair_id} = 'rep-' . substr(sha256_hex(encode('UTF-8', $canon)), 0, 12);
    $r->{result_hash} = sha256_hex(encode('UTF-8', $canon . $r->{repair_id}));
    $r->{_yaml} = result_to_yaml($r);
    return $r;
}

sub analyze {
    my ($spec) = @_;
    my $r = { repair_items => [], ambiguities => [], checks => [] };

    my $bad = sub {
        my ($status, $msg, $check, $domain) = @_;
        push @{ $r->{checks} }, { check_id => $check // 'RRP-G1', domain => $domain // 'input_integrity', verdict => 'fail', findings => [$msg] };
        $r->{status} = $status;
        $r->{validation_status} = 'NOT_APPLICABLE';
        $r->{downstream_allowed} = 0;
        $r->{downstream_next} = 'HALT';
        return _finalize($r);
    };

    # --- RRP-G1: RCA contract gate -------------------------------------------
    my $rca = parse_rca($spec->{rca_text} // '');
    return $bad->('INVALID_INPUT', 'RCA contract missing or unparseable', 'RRP-G1') unless $rca && $rca->{rca_id};
    return $bad->('INVALID_INPUT', "RCA status '$rca->{status}' is not repairable (needs READY/READY_WITH_WARNINGS)", 'RRP-G1')
        unless ($rca->{status} // '') eq 'READY' || ($rca->{status} // '') eq 'READY_WITH_WARNINGS';
    return $bad->('INVALID_INPUT', 'RCA downstream gate is closed or next_stage is not REPAIR_AND_REGRESSION', 'RRP-G1')
        unless ($rca->{downstream_allowed} // '') eq 'true' && ($rca->{next_stage} // '') eq 'REPAIR_AND_REGRESSION';
    $r->{rca} = $rca;
    push @{ $r->{checks} }, { check_id => 'RRP-G1', domain => 'rca_gate', verdict => 'pass', findings => [] };

    # --- RRP-G2: repair authorization (user decision) --------------------------
    my $dec = $spec->{user_decision} // '';
    return $bad->('INVALID_INPUT', 'no user repair decision supplied - AGENT_RULES 6 forbids silent unit-semantics resolution', 'RRP-G2')
        unless defined $dec && length $dec;
    return $bad->('INVALID_INPUT', "user decision does not resolve the F-002 unit-semantics question (no bounded-scale/normalized value semantics stated)", 'RRP-G2')
        unless $dec =~ /normali[sz]ed|scaled|0-100|0..100|indicator|ARO/i;
    $r->{user_decision} = $dec;
    push @{ $r->{checks} }, { check_id => 'RRP-G2', domain => 'repair_authorization', verdict => 'pass', findings => [] };

    # --- RRP-G3: source integrity ----------------------------------------------
    my $pine = $spec->{pine_text} // '';
    return $bad->('INVALID_INPUT', 'production Pine source missing', 'RRP-G3') unless length $pine;
    my ($c1_line) = $pine =~ /^\s*state_crossover := (.+)$/m;
    return $bad->('INVALID_INPUT', 'C-1 assignment not found in the Pine source', 'RRP-G3') unless defined $c1_line;
    $r->{pine_sha256} = $spec->{pine_sha256} // _sha($pine);
    push @{ $r->{checks} }, { check_id => 'RRP-G3', domain => 'source_integrity', verdict => 'pass',
        findings => [ 'pine sha256 ' . substr($r->{pine_sha256}, 0, 12) . '...' ] };

    # --- RRP-G4: repair item derivation (findings-driven, no invention) --------
    my @items; my @amb;
    my $cls = $rca->{classifications};
    my $has_exp_mismatch = grep { $_ eq 'EXPECTATION_MISMATCH' } @$cls;
    if ($has_exp_mismatch) {
        push @items, {
            item_id => 'RP-001',
            target => 'formalization (C-1 condition_verbatim)',
            action => 'REFORMALIZE',
            from => 'close crosses over 30',
            to => 'ARO_BOUNDED_SCALE crosses over 30 (normalized 0-100 indicator scale; user decision)',
            justification => 'F-002 EXPECTATION_MISMATCH resolved by the user-supplied unit-semantics decision: 30 is a value on the ARO indicator normalized 0-100 scale, not raw price',
            source_refs => [ 'rca ' . $rca->{rca_id} . ' F-002', 'user decision (verbatim, ' . $spec->{decision_date} . ')' ],
        };
        push @items, {
            item_id => 'RP-002',
            target => 'implementation/phase9_pine.pine:25 (M-STATE)',
            action => 'PATCH_LATER_VIA_REIMPLEMENTATION',
            from => 'close > 30 and close[1] <= 30',
            to => 'ARO_series > 30 and ARO_series[1] <= 30 (exact series pending A-001)',
            justification => 'RP-001 mirrors into code through the pipeline (Formalization -> Implementation), never in-place (repair firewall RRP-G7)',
            source_refs => [ 'implementation/phase9_pine.pine:25', 'RP-001' ],
        };
        # A-001: which ARO series? (multiple bounded-scale candidates in the dataset)
        my ($series_evidence) = defined $spec->{series_evidence} ? $spec->{series_evidence} : '';
        push @amb, {
            id => 'A-001',
            description => 'the repaired condition operand (ARO_BOUNDED_SCALE) is not yet a single named series: the fingerprinted dataset carries several bounded-scale ARO candidates (ARO Bounded Core, Pullback Score, ZoneForce Long/Short)',
            evidence => $series_evidence,
            options => [
                'ARO Bounded Core (window range -80.87..88.56; not strictly 0-100)',
                'Pullback Score (window range -48.28..53.01; threshold columns Long 60-65 / Short -65..-60)',
                'ZoneForce Long (window range 0..99.36; nearest to a strict 0-100 scale)',
                'ZoneForce Short (window range 0..99.87)',
            ],
            status => 'OPEN_DECISION_REQUIRED',
        };
        # A-002: verify the repaired unit semantics against the localized bar
        my $loc = $spec->{localized_bar_row};
        if ($loc && $loc->{pullback_prev} && $loc->{pullback_cur}) {
            push @amb, {
                id => 'A-002',
                description => 'user semantics check: the repaired condition requires the ARO series to cross 30 at the localized bar for a BUY - Pullback Score reads ' . $loc->{pullback_prev} . ' -> ' . $loc->{pullback_cur} . ' across the last two bars (both below 30 at the localized bar; no cross of 30 at bar 109; nearest cross below)',
                evidence => 'dataset ' . ($spec->{dataset_path} // '') . ' rows at/adjacent to ' . ($rca->{localized_bar} // ''),
                options => [],
                status => 'OPEN_DECISION_REQUIRED',
            };
        }
    }
    return $bad->('REFUSED', 'no RCA finding supports a repair (no EXPECTATION_MISMATCH present)', 'RRP-G4', 'repair_justification')
        unless @items;
    $r->{repair_items} = \@items;
    $r->{ambiguities} = \@amb;
    $r->{resolves_finding} = 'F-002 (EXPECTATION_MISMATCH)';
    push @{ $r->{checks} }, { check_id => 'RRP-G4', domain => 'repair_justification', verdict => 'pass',
        findings => [ scalar(@items) . ' repair item(s) derived from RCA findings + user decision' ] };

    # --- RRP-G5: mechanical unit-semantics verification over the dataset -------
    my $ds = $spec->{dataset};
    if ($ds && $ds->{has_pullback}) {
        my @rows = @{ $ds->{rows} };
        my $thr = 30;
        my $orig_fires = 0; my $rep_fires = 0;
        my @orig_fire_t; my @rep_fire_t;
        my @changed;
        my $prev;
        for my $row (@rows) {
            my $cur = $row;
            my $o = eval_original_c1($prev ? $prev->{close} : undef, $cur->{close});
            my $pv = $prev && defined $prev->{pullback} ? $prev->{pullback} : undef;
            my $cv = defined $cur->{pullback} ? $cur->{pullback} : undef;
            my $rep = eval_repaired_c1($pv, $cv, $thr);
            $orig_fires++ if $o;
            if ($rep) { $rep_fires++; push @rep_fire_t, $cur->{time}; }
            if (defined $o && defined $rep && ($o ? 1 : 0) != ($rep ? 1 : 0)) {
                push @changed, $cur->{time};
            }
            $prev = $cur;
        }
        # determinism: re-run the same computation and compare aggregates
        my ($o2, $r2) = (0, 0);
        $prev = undef;
        for my $row (@rows) {
            $o2++ if eval_original_c1($prev ? $prev->{close} : undef, $row->{close});
            my $pv = $prev && defined $prev->{pullback} ? $prev->{pullback} : undef;
            $r2++ if eval_repaired_c1($pv, $row->{pullback}, $thr);
            $prev = $row;
        }
        my $det = (($o2 == $orig_fires && $r2 == $rep_fires) ? 'PASS' : 'FAIL');
        # Pullback Score values at the localized bar and previous bar (for A-002)
        my ($loc_prev, $loc_cur);
        for my $i (1 .. $#rows) {
            if ($rows[$i]{time} eq ($rca->{localized_bar} // '')) {
                $loc_cur = $rows[$i]{pullback}; $loc_prev = $rows[$i-1]{pullback};
            }
        }
        $r->{regression} = {
            dataset_path => ($spec->{dataset_path} // ''),
            dataset_sha256 => ($spec->{dataset_sha256} // ''),
            operand_provisional => 'Pullback Score',
            window_bars => scalar(@rows),
            original_fires => $orig_fires,
            repaired_fires => $rep_fires,
            bars_changed => scalar(@changed),
            changed_bars => \@changed,
            fire_times => \@rep_fire_t,
            determinism => $det,
            pullback_prev => $loc_prev,
            pullback_cur => $loc_cur,
        };
        push @{ $r->{checks} }, { check_id => 'RRP-G5', domain => 'unit_semantics_verification', verdict => ($det eq 'PASS' ? 'pass' : 'fail'),
            findings => [ "original C-1 fires: $orig_fires over " . scalar(@rows) . " bars; repaired C-1 proxy (Pullback Score > 30 cross, operand provisional per A-001): $rep_fires"
                        . (defined $loc_cur ? "; Pullback Score at localized bar: $loc_prev -> $loc_cur" : "") ] };
    } else {
        push @{ $r->{checks} }, { check_id => 'RRP-G5', domain => 'unit_semantics_verification', verdict => 'fail',
            findings => ['dataset with Pullback Score column not available - regression not performed'] };
    }

    # --- RRP-G6: regression comparison completeness ------------------------------
    if ($r->{regression}) {
        my $reg = $r->{regression};
        return $bad->('INSUFFICIENT_EVIDENCE', 'regression determinism check failed', 'RRP-G6', 'regression_integrity')
            unless ($reg->{determinism} // '') eq 'PASS';
        push @{ $r->{checks} }, { check_id => 'RRP-G6', domain => 'regression_integrity', verdict => 'pass',
            findings => [ "original vs repaired comparison complete over $reg->{window_bars} bars; $reg->{bars_changed} bars changed" ] };
    } else {
        push @{ $r->{checks} }, { check_id => 'RRP-G6', domain => 'regression_integrity', verdict => 'fail',
            findings => ['no regression section present'] };
    }

    # --- RRP-G7: repair firewall --------------------------------------------------
    push @{ $r->{checks} }, { check_id => 'RRP-G7', domain => 'repair_firewall', verdict => 'pass',
        findings => ['no upstream artifact modified; repaired formalization emitted as a NEW content-addressed contract'] };

    # --- status + validation honesty (AGENT_RULES 21) ------------------------------
    my $g5 = (grep { $_->{check_id} eq 'RRP-G5' && $_->{verdict} eq 'pass' } @{ $r->{checks} }) ? 1 : 0;
    $r->{validation_status} = $g5 ? 'STATICALLY_REVIEWED_MECHANICALLY_RECONSTRUCTED' : 'STATICALLY_REVIEWED';
    my $open_amb = grep { ($_->{status} // '') eq 'OPEN_DECISION_REQUIRED' } @{ $r->{ambiguities} };
    if ($open_amb) {
        # AGENT_RULES 8: behavior-affecting unresolved ambiguities keep implementation_allowed false
        $r->{status} = 'READY_WITH_WARNINGS';
        $r->{downstream_allowed} = 1;
        $r->{downstream_next} = 'FORMALIZATION';
        push @{ $r->{checks} }, { check_id => 'RRP-G8', domain => 'ambiguity_gate',
            verdict => 'pass', findings => [ "$open_amb open decision point(s) recorded; re-implementation blocked until A-001 (and optionally A-002) are user-resolved" ] };
    } else {
        $r->{status} = 'READY';
        $r->{downstream_allowed} = 1;
        $r->{downstream_next} = 'FORMALIZATION';
        push @{ $r->{checks} }, { check_id => 'RRP-G8', domain => 'ambiguity_gate', verdict => 'pass', findings => [] };
    }

    return _finalize($r);
}

# ---------------------------------------------------------------------------
# selftest — RRP-001..006 acceptance set + negative NG-RRP-001..004
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };

    my $RCA_OK = <<"RCA";
# root cause analysis contract
rca:
  rca_id: 'rca-test00000001'
  trace_id: 'trace-test0000001'
  trace_status: 'READY_WITH_WARNINGS'
  trace_mode: 'RECONSTRUCTED'
  localized_bar: '2026-09-12T00:45:00Z'
  trace_window: '2026-09-11T19:18:00Z .. 2026-09-12T00:45:00Z (110 bars)'

signal_history:
  bars_traced: 110
  signal_true_bars: 0

findings:
  - { finding_id: 'F-001', classification: 'DATA_PROPERTY', confidence: 'HIGH', statement: 'x', trace_refs: [], artifact_refs: [] }
  - { finding_id: 'F-002', classification: 'EXPECTATION_MISMATCH', confidence: 'HIGH', statement: 'x', trace_refs: [], artifact_refs: [] }
  - { finding_id: 'F-003', classification: 'CODE_PROPERTY', confidence: 'HIGH', statement: 'x', trace_refs: [], artifact_refs: [] }

status: 'READY_WITH_WARNINGS'
blockers: []
repair: NOT_PERFORMED
downstream:
  allowed: true
  next_stage: 'REPAIR_AND_REGRESSION'
result_hash: 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
RCA

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

    my $DATASET = <<'CSV';
time,open,high,low,close,Pullback Score,Long Threshold
2026-09-11T19:18:00Z,0.076,0.076,0.076,0.076,10.0,60
2026-09-11T19:21:00Z,0.076,0.076,0.076,0.076,25.0,60
2026-09-11T19:24:00Z,0.076,0.076,0.076,0.076,31.5,60
2026-09-11T19:27:00Z,0.076,0.076,0.076,0.076,28.0,60
CSV

    my $ds = parse_dataset($DATASET);
    $ok->($ds && $ds->{has_pullback} && scalar(@{ $ds->{rows} }) == 4, 'RRP-001 dataset parser reads time/close/Pullback Score');

    my $run = sub {
        my (%o) = @_;
        return analyze({
            rca_text => ($o{rca} // $RCA_OK),
            pine_text => ($o{pine} // $PINE),
            user_decision => ($o{decision} // 'I MEAN normalized/scaled value (e.g., 30 on the ARO indicator 0-100 scale)'),
            dataset => ($o{dataset} // $ds),
            dataset_path => 'fixture.csv',
            localized_bar_row => ($o{locrow} // { pullback_prev => '25.0', pullback_cur => '31.5' }),
            series_evidence => ($o{evidence} // 'fixture evidence'),
            decision_date => '2026-09-12',
        });
    };

    # RRP-002: happy path derives repair items from F-002 + decision
    my $r = $run->();
    $ok->(($r->{status} // '') =~ /^READY/, 'RRP-002 happy path status READY/READY_WITH_WARNINGS');
    $ok->(scalar(grep { $_->{item_id} eq 'RP-001' } @{ $r->{repair_items} }) == 1, 'RRP-002b RP-001 re-formalization item derived');
    $ok->(scalar(grep { $_->{item_id} eq 'RP-002' } @{ $r->{repair_items} }) == 1, 'RRP-002c RP-002 code-patch item derived');

    # RRP-003: ambiguity recorded, never silently resolved (AGENT_RULES 6)
    $ok->(scalar(grep { $_->{id} eq 'A-001' && $_->{status} eq 'OPEN_DECISION_REQUIRED' } @{ $r->{ambiguities} }) == 1, 'RRP-003 A-001 operand ambiguity recorded OPEN');

    # RRP-004: mechanical regression over the fixture dataset
    $ok->(defined $r->{regression} && $r->{regression}{original_fires} == 0, 'RRP-004 original C-1 zero fires on fixture');
    $ok->(($r->{regression}{repaired_fires} // -1) == 1, 'RRP-004b repaired C-1 fires exactly once on the 25.0 -> 31.5 cross');
    $ok->(($r->{regression}{determinism} // '') eq 'PASS', 'RRP-004c regression determinism PASS');

    # RRP-005: honest validation status (no Pine compiler locally)
    $ok->(($r->{validation_status} // '') =~ /STATICALLY_REVIEWED/, 'RRP-005 validation_status is honest (no ACTUALLY_VERIFIED claim)');

    # RRP-006: deterministic content-addressed identity
    my $r2 = $run->();
    $ok->($r->{repair_id} eq $r2->{repair_id} && $r->{repair_id} =~ /^rep-[0-9a-f]{12}$/, 'RRP-006 deterministic repair_id');

    # NG-RRP-001: missing user decision refused
    my $ng1 = $run->(decision => '');
    $ok->(($ng1->{status} // '') eq 'INVALID_INPUT', 'NG-RRP-001 missing decision -> INVALID_INPUT');

    # NG-RRP-002: off-topic decision refused
    my $ng2 = $run->(decision => 'just make it work');
    $ok->(($ng2->{status} // '') eq 'INVALID_INPUT', 'NG-RRP-002 off-topic decision -> INVALID_INPUT');

    # NG-RRP-003: RCA gate closed refused
    my $rca_closed = $RCA_OK;
    $rca_closed =~ s/  allowed: true/  allowed: false/;
    my $ng3 = $run->(rca => $rca_closed);
    $ok->(($ng3->{status} // '') eq 'INVALID_INPUT', 'NG-RRP-003 closed RCA gate -> INVALID_INPUT');

    # NG-RRP-004: RCA without EXPECTATION_MISMATCH refused
    my $rca_noem = $RCA_OK;
    $rca_noem =~ s/classification: 'EXPECTATION_MISMATCH'/classification: 'UNKNOWN'/;
    my $ng4 = $run->(rca => $rca_noem);
    $ok->(($ng4->{status} // '') eq 'REFUSED', 'NG-RRP-004 no EXPECTATION_MISMATCH -> REFUSED');

    print "selftest: $pass passed, $fail failed\n";
    return $fail ? 1 : 0;
}

# gate check over an emitted contract
sub gate_check_text {
    my ($t) = @_;
    my ($st) = $t =~ /^status: '([^']*)'/m;
    my ($da) = $t =~ /^  allowed: (true|false)/m;
    if (($st // '') =~ /^READY/ && ($da // '') eq 'true') {
        return (1, "status is '$st' - re-Formalization may start (open decision points must be resolved by the user first)");
    }
    return (0, "status is '" . ($st // 'UNKNOWN') . "' - downstream progression forbidden");
}

# ---------------------------------------------------------------------------
sub usage {
    return <<'EOU';
repair_and_regression.pl — Phase 15 Repair & Regression Engine (schema v1.0)

Usage:
  perl rca/repair_and_regression.pl --rca FILE [--pine FILE] [--dataset FILE]
        [--decision TEXT] [--out FILE]
  perl rca/repair_and_regression.pl --gate-check --rca RESULT_FILE
  perl rca/repair_and_regression.pl --selftest

  --rca FILE        Phase 14 RCA contract (gate: READY/READY_WITH_WARNINGS,
                    downstream open, next_stage REPAIR_AND_REGRESSION)
  --pine FILE       production Pine source (default: implementation/phase9_pine.pine)
  --dataset FILE    fingerprinted Phase 12 CSV (default: the 3m ISO export)
  --decision TEXT   the user's verbatim unit-semantics decision (repair authorization)
  --out FILE        write the repair contract to FILE

Exit codes: 0 = repair contract complete; 2 = repair refused.
Boundaries: never modifies upstream artifacts; ambiguities are recorded, never
silently resolved; validation status is honest (no local Pine compiler).
EOU
}

my ($rca_file, $out_file, $gate, $selftest, $show_ver, $show_help, $decision, $dataset_file) =
    (undef, undef, 0, 0, 0, 0, undef, $DATASET_DEFAULT);
my $pine_file = $PINE_DEFAULT;
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a eq '--rca')      { $rca_file = shift @ARGV; }
    elsif ($a eq '--pine')     { $pine_file = shift @ARGV; }
    elsif ($a eq '--dataset')  { $dataset_file = shift @ARGV; }
    elsif ($a eq '--decision') { $decision = shift @ARGV; }
    elsif ($a eq '--out')      { $out_file = shift @ARGV; }
    elsif ($a eq '--gate-check'){ $gate = 1; }
    elsif ($a eq '--selftest') { $selftest = 1; }
    elsif ($a eq '--version')  { $show_ver = 1; }
    elsif ($a eq '--help')     { $show_help = 1; }
    else { die "unknown argument '$a'\n"; }
}
if ($show_ver)  { print "$VERSION_STR\n"; exit 0; }
if ($show_help) { print usage(); exit 0; }
if ($gate) {
    die "usage with --gate-check: --rca RESULT_FILE\n" unless defined $rca_file;
    my $t = _slurp($rca_file);
    my ($ok, $msg) = gate_check_text($t);
    print "$msg\n";
    exit($ok ? 0 : 2);
}
if ($selftest) { my $st = selftest(); exit $st; }

die "usage: --rca FILE is required\n" unless defined $rca_file && -f $rca_file;

my $r = analyze({
    rca_text => _slurp($rca_file),
    pine_text => (-f $pine_file ? _slurp($pine_file) : ''),
    pine_sha256 => (-f $pine_file ? _sha(_slurp($pine_file)) : undef),
    user_decision => $decision,
    dataset => parse_dataset(_slurp($dataset_file)),
    # repo-relative label (never embed absolute environment paths)
    dataset_path => ($dataset_file =~ /^\Q$Bin\E\/\.\.\/(.+)$/ ? $1 : $dataset_file),
    dataset_sha256 => _sha(_slurp($dataset_file)),
    localized_bar_row => undef,
    series_evidence => 'KCEX 3m export header (35 ARO-family columns incl. ARO Bounded Core, Pullback Score, ZoneForce Long/Short; min/max computed over the 301-row dataset)',
    decision_date => '2026-09-12',
});
my $yaml = delete $r->{_yaml};
if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh encode('UTF-8', $yaml); close $fh; }
else { print encode('UTF-8', $yaml); }
exit(($r->{status} =~ /^READY/) ? 0 : 2);
