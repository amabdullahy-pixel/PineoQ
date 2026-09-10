#!/usr/bin/perl
# ============================================================================
# feasibility.pl — Feasibility decision engine (pine-agent Phase 7)
# ============================================================================
# Core Perl 5, zero non-core dependencies (Digest::SHA, Encode, File::Temp,
# File::Basename are core). Runtime contract identical to router.pl /
# formalize.pl / pre_verify.pl.
#
# Inputs : the formalization contract (--contract, exactly as formalize.pl
#          emits it) AND the Phase-6 pre-verification result (--pre, exactly
#          as pre_verify.pl emits it).
# Output : feasibility result contract (schema v1.1) + exit code.
#   exit 0  feasibility_status FEASIBLE | FEASIBLE_WITH_WARNINGS
#   exit 2  PARTIALLY_FEASIBLE | NOT_FEASIBLE | BLOCKED | INVALID_INPUT
#
# Hard gate: ONLY FEASIBLE / FEASIBLE_WITH_WARNINGS sets
# implementation_planning_allowed=true and next_stage=IMPLEMENTATION_PLANNING.
# No silent fallback: unavailable capability/data is recorded (unsupported_
# items), never substituted. Unknown platform capabilities stay
# UNKNOWN_REQUIRES_VERIFICATION (critical unknowns block, advisory warn).
#
# Determinism: no clock, no randomness, no environment values.
# feasibility_id = "feas-" + first 12 hex of sha256 over the canonical body
# (see meta/feasibility_procedure.md §7).
#
# NO-PINE RULE: this engine assesses a specification. It never emits Pine.
# ============================================================================
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode);
use File::Basename qw(dirname);

# scratch accumulators shared with run_checks (reset per run in feasibility_text)
my ($UNK, $CAP, $UNS, $PAR, $PLAT, $CONS, $DREQ);
sub r_unknowns     { $UNK  ||= []; return $UNK; }
sub r_capabilities { $CAP  ||= []; return $CAP; }
sub r_unsupported  { $UNS  ||= []; return $UNS; }
sub r_partial      { $PAR  ||= []; return $PAR; }
sub r_platform     { $PLAT ||= []; return $PLAT; }
sub r_constraints  { $CONS ||= []; return $CONS; }
sub r_dreq         { $DREQ ||= []; return $DREQ; }

# ---------------------------------------------------------------------------
# tiny YAML-subset parsers (formalization contract: same format pre_verify.pl
# parses; pre result: emitted by pre_verify.pl; config: this project's file)
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
    # next_stage is emitted UNQUOTED by pre_verify.pl (FEASIBILITY | HALT);
    # quoted form accepted as well for robustness.
    my ($nsq) = $text =~ /^\s{2}next_stage:\s*'([^']*)'/m;
    ($nsq)    = $text =~ /^\s{2}next_stage:\s*(\S+)/m unless defined $nsq;
    $p{next_stage}          = $nsq;
    my ($fa) = $text =~ /^\s{2}feasibility_allowed:\s*(true|false)/m;
    $p{feasibility_allowed} = (defined $fa && $fa eq 'true') ? 1 : 0;
    $p{blockers_empty} = ($text =~ /^  blockers: \[\]/m) ? 1 : 0;
    my @warn_codes;
    if ($text =~ /^  warnings:\s*$/m) {
        my $sec = '';
        my $cap = 0;
        for my $line (split /\r?\n/, $text) {
            if ($line =~ /^  warnings:\s*$/) { $cap = 1; next; }
            next unless $cap;
            last if $line =~ /^\S/ || $line =~ /^  \w/;
            $sec .= "$line\n";
        }
        @warn_codes = ($sec =~ /code:\s*'([^']+)'/g);
    }
    $p{warn_codes} = \@warn_codes;
    die "unparseable: no pre_verification block\n" unless $text =~ /pre_verification/;
    return \%p;
}

sub parse_config {
    my ($text) = @_;
    my (%kb, %dk, %ph);
    my (@kb_l, @dk_l, @ph_l);
    my $cur = '';
    for my $line (split /\r?\n/, $text) {
        if ($line =~ /^(\w+):/) { $cur = $1; }
        if    ($cur eq 'capability_kb')     { push @kb_l, $line; }
        elsif ($cur eq 'data_kinds')        { push @dk_l, $line; }
        elsif ($cur eq 'performance_hints') { push @ph_l, $line; }
    }
    for my $line (@kb_l) {
        next unless $line =~ /^\s*-\s*\{(.*)\}\s*$/;
        my $e = _parse_flow_map($1);
        $kb{ $e->{id} } = $e if $e->{id};
    }
    my $dksub = '';
    for my $line (@dk_l) {
        if ($line =~ /^  (\w+):\s*$/) { $dksub = $1; next; }
        next unless $line =~ /^\s*-\s*\{(.*)\}\s*$/;
        my $e = _parse_flow_map($1);
        push @{ $dk{$dksub} }, $e if $e->{kind};
    }
    for my $line (@ph_l) {
        next unless $line =~ /^\s{2}(\w+):\s*(.+?)\s*$/;
        my ($k, $v) = ($1, $2);
        if ($v =~ /^'((?:[^']|'')*)'/) { $ph{$k} = _unq($1); }            # quoted: stop at closing quote
        else                           { $v =~ s/\s+#.*$//; $ph{$k} = $v; } # unquoted: strip inline comment
    }
    return { kb => \%kb, dk => \%dk, ph => \%ph };
}

# ---------------------------------------------------------------------------
# mechanical helpers
# ---------------------------------------------------------------------------
# spec-level timeframe canonicalization: accepts common spec notations and
# Pine-style TF strings ('15m', '15', '1h', '1D', '1W', '30s', '1T/tick');
# returns { secs => N } for time units or { tick => 1 }; undef = meaningless.
sub tf_canon {
    my ($t) = @_;
    return undef if !defined $t;
    $t = lc $t; $t =~ s/\s+//g;
    return { tick => 1 } if $t eq '1t' || $t eq 't' || $t eq 'tick';
    return undef unless $t =~ /^(\d+)(s|sec|m|min|h|d|w|mo|month)?$/;
    my ($n, $u) = ($1, $2 // 'm');
    my %mult = (s => 1, sec => 1, m => 60, min => 60, h => 3600, d => 86400, w => 604800, mo => 2592000, month => 2592000);
    return { secs => $n * $mult{$u} };
}
sub tf_secs { my $c = shift; return undef if !$c || $c->{tick}; return $c->{secs}; }

# keyword regex: '|' separates ALTERNATIVES (not literal pipes)
sub _kwre {
    my $kw = shift;
    my @alts = map { quotemeta } grep { length } split /\|/, $kw;
    return undef unless @alts;
    return qr/\b(?:@{[ join '|', @alts ]})/i;
}

# ---------------------------------------------------------------------------
# the 12 checks — each appends findings
# finding = { check_id, severity, code, message, refs[], reqs[] }
# ---------------------------------------------------------------------------
my @DOMAINS = (
    ['FB01', 'identity_traceability'],     ['FB02', 'phase6_handoff_gate'],
    ['FB03', 'pine_language_feasibility'], ['FB04', 'runtime_model_feasibility'],
    ['FB05', 'timeframe_mtf_feasibility'], ['FB06', 'data_availability_feasibility'],
    ['FB07', 'repaint_execution_feasibility'], ['FB08', 'drawing_resource_feasibility'],
    ['FB09', 'alert_feasibility'],         ['FB10', 'market_session_feasibility'],
    ['FB11', 'performance_feasibility'],   ['FB12', 'feasibility_classification'],
);

sub run_checks {
    my ($c, $p, $cfg) = @_;
    my @F;
    my $add = sub {
        my ($cid, $sev, $code, $msg, $refs, $reqs) = @_;
        push @F, { check_id => $cid, severity => $sev, code => $code, message => $msg,
                   refs => $refs || [], reqs => $reqs || [] };
    };

    # --- FB01 identity chain --------------------------------------------------
    my $ok_id = sub { return defined $_[0] && $_[0] =~ /^(req|rout|form)-[0-9a-f]{12}$/ };
    {
        my @bad;
        push @bad, 'contract.request_id'          unless $ok_id->($c->{request_id});
        push @bad, 'contract.approved_routing_id' unless $ok_id->($c->{approved_routing_id});
        push @bad, 'contract.formalization_id'    unless $ok_id->($c->{formalization_id});
        push @bad, 'pre.verification_id' unless defined $p->{verification_id} && $p->{verification_id} =~ /^pre-[0-9a-f]{12}$/;
        push @bad, 'pre.request_id'   unless $ok_id->($p->{request_id});
        push @bad, 'pre.approved_routing_id' unless $ok_id->($p->{approved_routing_id});
        push @bad, 'pre.formalization_id' unless $ok_id->($p->{formalization_id});
        if (@bad) { $add->('FB01', 'blocker', 'B-CHAIN', 'identity chain malformed or missing: ' . join(', ', @bad), \@bad); }
    }
    # --- FB02 Phase-6 handoff gate ------------------------------------------------
    {
        my $res = $p->{result} // 'null';
        unless (defined $p->{result} && $p->{result} =~ /^PASS/) {
            $add->('FB02', 'blocker', 'B-HANDOFF-STATUS', "pre-verification result is '$res' — only PASS or PASS_WITH_WARNINGS opens Feasibility", ['pre_verification.result']);
        }
        unless ($p->{blockers_empty}) {
            $add->('FB02', 'blocker', 'B-HANDOFF-BLOCKERS', 'pre-verification result carries blockers — downstream use refused', ['pre_verification.blockers']);
        }
        unless ($p->{feasibility_allowed}) {
            $add->('FB02', 'blocker', 'B-HANDOFF-GATE', 'pre-verification feasibility_allowed is false — downstream use refused', ['pre_verification.feasibility_allowed']);
        }
        if (defined $p->{next_stage} && $p->{next_stage} ne 'FEASIBILITY') {
            $add->('FB02', 'blocker', 'B-HANDOFF-STAGE', "pre-verification next_stage is '" . $p->{next_stage} . "' — FEASIBILITY required", ['pre_verification.next_stage']);
        }
        if (defined $c->{request_id} && defined $p->{request_id} && $c->{request_id} ne $p->{request_id}) {
            $add->('FB02', 'blocker', 'B-HANDOFF-CHAIN', "request_id mismatch between inputs: '" . $c->{request_id} . "' vs '" . $p->{request_id} . "'", ['request_id']);
        }
        if (defined $c->{formalization_id} && defined $p->{formalization_id} && $c->{formalization_id} ne $p->{formalization_id}) {
            $add->('FB02', 'blocker', 'B-HANDOFF-CHAIN', 'formalization_id mismatch between inputs', ['formalization_id']);
        }
    }
    # --- FB03 Pine-language capability scan (F01) -------------------------------
    my @prose_parts = ($c->{request_text} // '');
    for my $v (@{ $c->{variables} || [] }) { push @prose_parts, $v->{description} // ''; }
    my $prose = join(' ', grep { defined } @prose_parts);
    my %cap_hits;   # cap id -> { where => [refs], reqs => [req ids] }
    my $scan = sub {
        my ($text, $ref, $req) = @_;
        return unless defined $text && length $text;
        for my $cid (sort keys %{ $cfg->{kb} }) {
            my $e = $cfg->{kb}{$cid};
            next unless $e->{keywords};
            my $re = _kwre($e->{keywords});
            next unless defined $re && $text =~ $re;
            $cap_hits{$cid}{where} ||= [];
            $cap_hits{$cid}{reqs}  ||= [];
            push @{ $cap_hits{$cid}{where} }, $ref;
            push @{ $cap_hits{$cid}{reqs} }, $req if defined $req;
        }
    };
    $scan->($prose, 'natural_language_request', undef);
    for my $f (@{ $c->{formulas} || [] })    { $scan->(($f->{expression} // '') . ' ' . ($f->{description} // ''), $f->{id} // 'F-?', $f->{id}); }
    for my $cd (@{ $c->{conditions} || [] }) { $scan->(($cd->{condition} // '') . ' ' . ($cd->{meaning} // ''), $cd->{id} // 'C-?', $cd->{id}); }
    for my $cid (sort keys %cap_hits) {
        my $e    = $cfg->{kb}{$cid};
        my $refs = $cap_hits{$cid}{where};
        my $reqs = $cap_hits{$cid}{reqs};
        if (($e->{status} // '') eq 'unavailable') {
            $add->('FB03', 'blocker', 'B-CAP-UNAVAILABLE',
                "capability '" . $cid . "' is documented unavailable — no substitution applied; a change requires an explicit downstream user decision (" . ($e->{basis} // 'no basis recorded') . ")",
                $refs, $reqs);
            push @{ r_unsupported() }, { subject => $cid, basis => ($e->{basis} // ''), refs => $refs };
        } elsif (($e->{status} // '') eq 'requires_verification') {
            my $critical = (($e->{critical} // 'false') eq 'true' && @$reqs) ? 1 : 0;
            if ($critical) {
                $add->('FB03', 'blocker', 'B-UNKNOWN-CRITICAL',
                    "capability '" . $cid . "' is UNKNOWN_REQUIRES_VERIFICATION and is load-bearing for a requirement (" . ($e->{basis} // '') . ")",
                    $refs, $reqs);
            } else {
                $add->('FB03', 'warning', 'W-UNKNOWN-CAP',
                    "capability '" . $cid . "' is UNKNOWN_REQUIRES_VERIFICATION (" . ($e->{basis} // '') . ")",
                    $refs, $reqs);
            }
            push @{ r_unknowns() }, { id => $cid, subject => $cid, critical => $critical, refs => $refs };
        } else {
            push @{ r_capabilities() }, { capability => $cid, status => 'confirmed', basis => ($e->{basis} // '') };
        }
    }
    # --- FB04 runtime model (F02) ------------------------------------------------
    my $ph = $cfg->{ph};
    my $rt = $ph->{realtime_tokens} // 'every tick|intrabar|realtime|tick by tick';
    my $oc = $ph->{onclose_tokens}  // 'on bar close|on close|bar close|confirmed';
    my $realtime_re = qr/\b(?:$rt)/i;
    my $onclose_re  = qr/\b(?:$oc)/i;
    my $reqtext = join(' ', grep { defined } ($c->{request_text} // '', map { $_->{condition} // () } @{ $c->{conditions} || [] }));
    my $is_realtime = ($reqtext =~ $realtime_re) ? 1 : 0;
    my $is_onclose  = ($reqtext =~ $onclose_re)  ? 1 : 0;
    {
        push @{ r_platform() }, { requirement => 'bar-by-bar execution on chart timeframe', status => 'confirmed',
            basis => 'tradingview-execution-model skill (Import Mode): historical bars execute once at close; realtime bars recalculate and rollback per tick' };
        if ($is_onclose) {
            push @{ r_platform() }, { requirement => 'confirmed bar-close evaluation requested', status => 'confirmed',
                basis => 'request wording ("on bar close" family) — matches documented confirmed-bar behavior' };
        }
        if ($is_realtime && @{ $c->{conditions} || [] }) {
            my @reqs = map { $_->{id} // 'C-?' } @{ $c->{conditions} || [] };
            $add->('FB04', 'warning', 'W-SEMANTIC-DIFF',
                'intrabar/realtime evaluation requested: realtime bars recalculate/rollback per tick while historical bars are fixed — the two branches cannot be semantically identical (documented execution model); no silent fallback applied',
                ['boolean_conditions', 'natural_language_request'], \@reqs);
            push @{ r_partial() }, { requirement => join(',', @reqs),
                feasible_part => 'historical confirmed bar-close semantics',
                non_feasible_part => 'identical tick-by-tick semantics across historical and realtime branches',
                semantic_difference => 'realtime bars recalculate and rollback per tick (documented execution model, tradingview-execution skill)' };
        }
    }
    # --- FB05 timeframe / MTF (F03) ------------------------------------------------
    {
        my $chart_c = tf_canon($c->{tf_chart});
        if (($c->{mtf_flag} || @{ $c->{required_data} || [] }) && !defined $chart_c) {
            $add->('FB05', 'blocker', 'B-TF-INVALID', "chart timeframe '" . ($c->{tf_chart} // 'null') . "' is not a recognizable timeframe notation", ['timeframe.chart']);
        }
        my $i = 0;
        for my $d (@{ $c->{required_data} || [] }) {
            $i++;
            my $ref = "required_data[$i]";
            my $dc = tf_canon($d->{timeframe});
            if (!defined $dc) {
                $add->('FB05', 'blocker', 'B-TF-INVALID', "required_data entry $i timeframe '" . ($d->{timeframe} // 'null') . "' is not a recognizable timeframe notation", [$ref]);
                next;
            }
            my $kind = lc($d->{kind} // '');
            my $cs = tf_secs($chart_c);
            my $ds = tf_secs($dc);
            if (defined $cs && defined $ds) {
                if ($kind =~ /htf|higher/ && $ds <= $cs) {
                    $add->('FB05', 'warning', 'W-TF-RELATION', "required_data entry $i is HTF but its timeframe is not higher than the chart timeframe — relation must be resolved explicitly (no substitution)", [$ref, 'timeframe.chart']);
                } elsif ($kind =~ /ltf|lower/ && $ds >= $cs) {
                    $add->('FB05', 'warning', 'W-TF-RELATION', "required_data entry $i is LTF but its timeframe is not lower than the chart timeframe — relation must be resolved explicitly (no substitution)", [$ref, 'timeframe.chart']);
                }
            }
        }
        if ($c->{mtf_flag}) {
            push @{ r_platform() }, { requirement => 'MTF data with explicit offset/lookahead discipline', status => 'confirmed',
                basis => 'AGENT_RULES 3.13 + mtf-engineering skill (Import Mode)' };
        }
    }
    # --- FB06 data availability (F04) ------------------------------------------------
    {
        my $i = 0;
        for my $d (@{ $c->{required_data} || [] }) {
            $i++;
            my $ref  = "required_data[$i]";
            my $kind = lc($d->{kind} // '');
            my ($match, $sect);
            for my $s ('unavailable', 'requires_verification', 'conditional', 'obtainable') {
                for my $e (@{ $cfg->{dk}{$s} || [] }) {
                    my $k = lc($e->{kind} // '');
                    if ($kind eq $k || index($kind, $k) >= 0) { $match = $e; $sect = $s; last; }
                }
                last if $match;
            }
            if (!$match) {
                $add->('FB06', 'blocker', 'B-DATA-UNKNOWN', "required_data entry $i kind '" . ($d->{kind} // 'null') . "' is not in the evidenced data vocabulary — obtainability UNKNOWN_REQUIRES_VERIFICATION", [$ref]);
                push @{ r_unknowns() }, { id => "D-$i", subject => "data kind '" . ($d->{kind} // '') . "'", critical => 1, refs => [$ref] };
                push @{ r_dreq() }, { index => $i, kind => ($d->{kind} // ''), timeframe => ($d->{timeframe} // ''), verdict => 'UNKNOWN_REQUIRES_VERIFICATION' };
            } elsif ($sect eq 'unavailable') {
                $add->('FB06', 'blocker', 'B-DATA-UNAVAILABLE', "required_data entry $i kind '" . ($d->{kind} // '') . "' is documented unavailable — no substitution applied; a change requires an explicit downstream user decision (" . ($match->{basis} // '') . ")", [$ref]);
                push @{ r_unsupported() }, { subject => "data kind '" . ($d->{kind} // '') . "'", basis => ($match->{basis} // ''), refs => [$ref] };
                push @{ r_dreq() }, { index => $i, kind => ($d->{kind} // ''), timeframe => ($d->{timeframe} // ''), verdict => 'NOT_FEASIBLE' };
            } elsif ($sect eq 'requires_verification') {
                $add->('FB06', 'blocker', 'B-DATA-UNKNOWN', "required_data entry $i kind '" . ($d->{kind} // '') . "' is symbol-dependent and could not be confirmed (" . ($match->{basis} // '') . ") — UNKNOWN_REQUIRES_VERIFICATION", [$ref]);
                push @{ r_unknowns() }, { id => "D-$i", subject => "data kind '" . ($d->{kind} // '') . "'", critical => 1, refs => [$ref] };
                push @{ r_dreq() }, { index => $i, kind => ($d->{kind} // ''), timeframe => ($d->{timeframe} // ''), verdict => 'UNKNOWN_REQUIRES_VERIFICATION' };
            } elsif ($sect eq 'conditional') {
                my $dc = tf_canon($d->{timeframe});
                if (!$dc || !$dc->{tick}) {
                    $add->('FB06', 'blocker', 'B-DATA-TF-1T', "required_data entry $i kind '" . ($d->{kind} // '') . "' requires the 1T (tick) timeframe (" . ($match->{basis} // '') . ") — no substitution applied", [$ref]);
                    push @{ r_dreq() }, { index => $i, kind => ($d->{kind} // ''), timeframe => ($d->{timeframe} // ''), verdict => 'NOT_FEASIBLE (1T-only rule)' };
                } else {
                    push @{ r_dreq() }, { index => $i, kind => ($d->{kind} // ''), timeframe => ($d->{timeframe} // ''), verdict => 'FEASIBLE (1T condition satisfied)' };
                }
            } else {
                push @{ r_dreq() }, { index => $i, kind => ($d->{kind} // ''), timeframe => ($d->{timeframe} // ''), verdict => 'FEASIBLE' };
            }
        }
    }
    # --- FB07 repaint / execution classification (F05) ------------------------------
    {
        my $raw = $c->{repaint_raw};
        if (defined $raw && $raw =~ /^(none|low|medium|high)\b/) {
            my $class = $1;
            push @{ r_constraints() }, { constraint => "repaint classification mirrored verbatim: '" . $raw . "' (never reclassified, never altered)", basis => 'formalization contract (mechanical classification, Phase 5)' };
            if ($class eq 'high') {
                $add->('FB07', 'warning', 'W-REPAINT-ACCEPT', 'repaint classification high — explicit user acceptance is required before implementation (surfaced, non-blocking)', ['repaint_risk']);
            }
        }
        if ($c->{mtf_flag}) {
            push @{ r_constraints() }, { constraint => 'HTF dependency present — realtime HTF confirmation discipline is binding downstream', basis => 'AGENT_RULES 3.12/3.13' };
        }
    }
    # --- FB08 drawing / resource limits (F06) ------------------------------------------
    {
        my $dt = $ph->{drawing_tokens} // 'label|line|box|table|plot';
        my $n = 0;
        $n++ while $reqtext =~ /\b(?:$dt)/gi;
        if ($n) {
            $add->('FB08', 'warning', 'W-LIMIT-UNKNOWN', "drawing/output objects referenced ($n mention(s)) — exact per-tier object budgets are not evidenced in this environment; UNKNOWN_REQUIRES_VERIFICATION (advisory)", ['natural_language_request']);
            push @{ r_unknowns() }, { id => 'U-DRAW', subject => 'drawing/object budget headroom', critical => 0, refs => ['natural_language_request'] };
            push @{ r_constraints() }, { constraint => 'drawing objects requested — exact budgets require official-documentation verification downstream', basis => 'documentation-evidence policy (no invented limits)' };
        }
    }
    # --- FB09 alerts (F07) ---------------------------------------------------------------
    {
        if ($cap_hits{'CAP-ALERTS'} || $cap_hits{'CAP-WEBHOOK'}) {
            push @{ r_platform() }, { requirement => 'alert representability (alertcondition()/alert(); webhooks per TradingView alerts)', status => 'confirmed',
                basis => 'alerts-and-webhooks skill (Import Mode); alert timing/frequency configuration is an alert-setting concern, evaluated downstream' };
            if ($is_realtime) {
                push @{ r_constraints() }, { constraint => 'alert timing interacts with realtime evaluation (see W-SEMANTIC-DIFF) — alert settings must be resolved explicitly', basis => 'alerts-and-webhooks skill (Import Mode)' };
            }
        }
    }
    # --- FB10 symbol / session / market data (F08) ------------------------------------------
    {
        if ($cap_hits{'CAP-SESSIONS'}) {
            my $already = grep { ($_->{capability} // '') eq 'CAP-SESSIONS' } @{ r_capabilities() };
            push @{ r_capabilities() }, { capability => 'CAP-SESSIONS', status => 'confirmed', basis => ($cfg->{kb}{'CAP-SESSIONS'}{basis} // '') } unless $already;
        }
        if ($reqtext =~ /\b(24\/7|24-7|always open|weekend trading)\b/i) {
            $add->('FB10', 'warning', 'W-SESSION-SYMBOL', 'round-the-clock session wording — availability depends on the target symbol class; verify on the target symbol (advisory unknown)', ['natural_language_request']);
            push @{ r_unknowns() }, { id => 'U-SESS', subject => 'session availability on target symbol class', critical => 0, refs => ['natural_language_request'] };
        }
    }
    # --- FB11 performance / complexity (F09) ---------------------------------------------------
    {
        my $lk = $ph->{loop_keywords} // 'for every bar|loop over all|iterate over all|every bar in history|all historical bars';
        if ($reqtext =~ /\b(?:$lk)/i) {
            $add->('FB11', 'warning', 'W-PERF-LOOP', 'unbounded-history loop wording — material runtime risk; bound and iteration strategy must be planned explicitly (advisory)', ['natural_language_request']);
        }
        my $nd  = scalar @{ $c->{required_data} || [] };
        my $thr = ($ph->{request_calls_warn} // '4') + 0;
        if ($nd > $thr) {
            $add->('FB11', 'warning', 'W-PERF-REQUESTS', "required_data entries ($nd) exceed the conservative advisory threshold ($thr) — exact request.* budget is tier-dependent (UNKNOWN_REQUIRES_VERIFICATION, advisory)", ['required_data']);
            push @{ r_unknowns() }, { id => 'U-REQBUDGET', subject => 'request.* budget headroom', critical => 0, refs => ['required_data'] };
        }
    }
    # --- FB12 requirement classification (F10) — derived in _finalize -------------------
    return \@F;
}

# ---------------------------------------------------------------------------
# feasibility orchestration
# ---------------------------------------------------------------------------
sub _finalize {
    my ($r, $c, $p) = @_;
    my @findings = @{ $r->{findings} || [] };
    my $i = 0;
    for my $f (@findings) { $i++; $f->{id} = sprintf('G-%03d', $i); }
    my @blockers = grep { ($_->{severity} // '') eq 'blocker' } @findings;
    my @warnings = grep { ($_->{severity} // '') eq 'warning' } @findings;
    my @checks;
    for my $d (@DOMAINS) {
        my ($cid, $dom) = @$d;
        my @mine = grep { ($_->{check_id} // '') eq $cid } @findings;
        my $verdict = (grep { ($_->{severity} // '') eq 'blocker' } @mine) ? 'fail' : (@mine ? 'warn' : 'pass');
        push @checks, { check_id => $cid, domain => $dom, verdict => $verdict, findings => [map { $_->{id} } @mine] };
    }
    # --- FB12 per-requirement classification --------------------------------------
    my %cls;
    my @req_ids;
    if ($c) {
        push @req_ids, map { $_->{id} // () } @{ $c->{conditions} || [] };
        push @req_ids, map { $_->{id} // () } @{ $c->{formulas} || [] };
        push @req_ids, map { $_->{id} // () } @{ $c->{edge_cases} || [] };
        my $nd = scalar @{ $c->{required_data} || [] };
        push @req_ids, map { "required_data[$_]" } 1 .. $nd;
    }
    for my $rid (@req_ids) {
        my ($blk, $par, $unk) = (0, 0, 0);
        for my $f (@findings) {
            my @hits = (@{ $f->{reqs} || [] }, @{ $f->{refs} || [] });
            next unless grep { $_ eq $rid } @hits;
            $blk = 1 if ($f->{severity} // '') eq 'blocker';
            $par = 1 if ($f->{code} // '') eq 'W-SEMANTIC-DIFF';
            $unk = 1 if ($f->{code} // '') =~ /^(B-UNKNOWN-CRITICAL|B-DATA-UNKNOWN)$/;
        }
        # precedence: UNKNOWN (critical unknown) > NOT_FEASIBLE (hard blocker) > PARTIAL > EXACT
        $cls{$rid} = $unk ? 'UNKNOWN_REQUIRES_VERIFICATION' : $blk ? 'NOT_FEASIBLE' : $par ? 'PARTIAL' : 'EXACT';
    }
    my @partials = @{ r_partial() || [] };
    # --- deterministic identity ------------------------------------------------------
    my @body = ($r->{request_id} // '', $r->{approved_routing_id} // '', $r->{formalization_id} // '',
                $r->{verification_id} // '', $r->{contract_sha} // '', $r->{pre_sha} // '');
    push @body, map { $_->{verdict} } @checks;
    for my $f (@findings) { push @body, $f->{id}, $f->{check_id}, $f->{severity}, $f->{code}, $f->{message}, join("\x1E", @{ $f->{refs} || [] }); }
    push @body, map { $_->{code} } @warnings;
    push @body, map { ($_->{id} // '') . '=' . ($_->{critical} ? 'critical' : 'advisory') } @{ r_unknowns() || [] };
    push @body, map { ($_->{subject} // '') } @{ r_unsupported() || [] };
    push @body, map { ($_->{requirement} // '') } @partials;
    push @body, map { $_ . '=' . $cls{$_} } sort keys %cls;
    my $fid = 'feas-' . substr(sha256_hex(encode('UTF-8', join("\x1F", @body))), 0, 12);
    # --- status decision (mandated order) ---------------------------------------------
    my $result = $r->{input_invalid} ? 'INVALID_INPUT'
               : (grep { ($_->{code} // '') =~ /^B-HANDOFF/ } @blockers) ? 'BLOCKED'
               : @blockers ? 'NOT_FEASIBLE'
               : @partials ? 'PARTIALLY_FEASIBLE'
               : @warnings ? 'FEASIBLE_WITH_WARNINGS'
               : 'FEASIBLE';
    my $open = ($result eq 'FEASIBLE' || $result eq 'FEASIBLE_WITH_WARNINGS') ? 1 : 0;
    # --- v1.0 field mapping -------------------------------------------------------------
    my $p_warns = $p ? ($p->{warn_codes} || []) : [];
    my $perf_warns = grep { ($_->{code} // '') =~ /^W-PERF/ } @warnings;
    my $fb_blk = sub { my $cid = shift; return grep { ($_->{check_id} // '') eq $cid } @blockers; };
    $r->{checks}          = \@checks;
    $r->{findings}        = \@findings;
    $r->{blockers}        = \@blockers;
    $r->{warnings}        = \@warnings;
    $r->{unknowns}        = [ map { { id => $_->{id}, subject => $_->{subject}, critical => ($_->{critical} ? 'true' : 'false'), status => 'UNKNOWN_REQUIRES_VERIFICATION', refs => $_->{refs} } } @{ r_unknowns() || [] } ];
    $r->{partial_items}   = \@partials;
    $r->{unsupported}     = [ map { { subject => $_->{subject}, basis => $_->{basis}, refs => $_->{refs} } } @{ r_unsupported() || [] } ];
    $r->{capabilities}    = [ map { { capability => $_->{capability}, status => $_->{status}, basis => $_->{basis} } } @{ r_capabilities() || [] } ];
    $r->{constraints}     = [ map { { constraint => $_->{constraint}, basis => $_->{basis} } } @{ r_constraints() || [] } ];
    $r->{data_requirements}     = r_dreq();
    $r->{platform_requirements} = [ map { { requirement => $_->{requirement}, status => $_->{status}, basis => $_->{basis} } } @{ r_platform() || [] } ];
    $r->{req_class}       = \%cls;
    $r->{feasibility_id}  = $fid;
    $r->{feasibility_status} = $result;
    $r->{status} = ($result eq 'FEASIBLE' || $result eq 'FEASIBLE_WITH_WARNINGS') ? 'passed'
                 : ($result eq 'PARTIALLY_FEASIBLE' || $result eq 'NOT_FEASIBLE') ? 'failed' : 'blocked';
    $r->{implementation_allowed}          = $open;
    $r->{implementation_planning_allowed} = $open;
    $r->{next_stage}                      = $open ? 'IMPLEMENTATION_PLANNING' : 'HALT';
    $r->{recommendation} = $result eq 'FEASIBLE' ? 'proceed'
                         : $result eq 'FEASIBLE_WITH_WARNINGS' ? 'proceed_with_changes'
                         : $result eq 'PARTIALLY_FEASIBLE' ? 'needs_user_input'
                         : $result eq 'NOT_FEASIBLE' ? 'reject' : undef;
    # v1.0 affirmations (mapping documented in schema/procedure)
    my $no_fb_blockers = !@blockers;
    $r->{pine_compatible}          = $fb_blk->('FB03') ? 0 : 1;
    $r->{required_data_available}  = $fb_blk->('FB06') ? 0 : 1;
    $r->{mtf_valid}                = $fb_blk->('FB05') ? 0 : 1;
    $r->{tradingview_compatible}   = ($fb_blk->('FB04') || $fb_blk->('FB08') || $fb_blk->('FB09') || $fb_blk->('FB11')) ? 0 : 1;
    $r->{mathematically_valid}     = ($no_fb_blockers && $r->{pre_pass}) ? 1 : 0;
    $r->{numerical_stability}      = $no_fb_blockers ? 1 : 0;
    $r->{statistically_meaningful} = (grep { $_ eq 'W-IMPLICIT-THR' } @$p_warns) ? 0 : 1;
    $r->{repaint_risk}             = $c ? ($c->{repaint_raw} // undef) : undef;
    $r->{runtime_risk}             = $perf_warns == 0 ? 'low' : $perf_warns == 1 ? 'medium' : 'high';
    return $r;
}

sub feasibility_text {
    my ($contract_text, $pre_text, $cfg) = @_;
    ($UNK, $CAP, $UNS, $PAR, $PLAT, $CONS, $DREQ) = (undef, undef, undef, undef, undef, undef, undef);
    my $bad = sub {
        my ($which, $err) = @_;
        $err = defined $err ? "$err" : 'unknown error';
        $err =~ s/\s+$//; $err =~ s/ at .* line \d+\.*$//;
        return _finalize({ input_invalid => 1, findings => [{ check_id => 'FB01', severity => 'blocker', code => 'B-INPUT', message => "$which could not be parsed: $err", refs => [$which] }] }, undef, undef);
    };
    return $bad->('contract_file', 'missing or empty') if !defined $contract_text || $contract_text !~ /\S/;
    return $bad->('pre_file', 'missing or empty')      if !defined $pre_text || $pre_text !~ /\S/;
    my $c = eval { parse_contract($contract_text) };
    return $bad->('contract_file', $@ // 'unknown error') unless $c;
    my $p = eval { parse_pre($pre_text) };
    return $bad->('pre_file', $@ // 'unknown error') unless $p;
    my $findings = run_checks($c, $p, $cfg);
    return _finalize({
        (map { $_ => $c->{$_} } qw(request_id approved_routing_id formalization_id)),
        verification_id => $p->{verification_id},
        pre_pass     => (defined $p->{result} && $p->{result} =~ /^PASS/) ? 1 : 0,
        upstream_warns => $p->{warn_codes},
        contract_sha => sha256_hex(encode('UTF-8', $contract_text)),
        pre_sha      => sha256_hex(encode('UTF-8', $pre_text)),
        findings     => $findings,
    }, $c, $p);
}

# ---------------------------------------------------------------------------
# result emitter (fixed field order; all scalars single-quoted, '' escaped)
# ---------------------------------------------------------------------------
sub _q  { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _qb { my $b = shift; return ($b) ? 'true' : 'false'; }
sub _ql { my ($l) = @_; return '[]' unless @{ $l || [] }; return '[' . join(', ', map { _q($_) } @$l) . ']'; }

sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# feasibility result — generated by feasibility.pl (schema v1.1; meta/feasibility_procedure.md)';
    push @o, 'schema_version: "1.1"', 'stage: feasibility', 'predecessor: pre_verification', 'successor: implementation_planning', '';
    push @o, 'feasibility:';
    push @o, '  request_id: ' . _q($r->{request_id});
    push @o, '  approved_routing_id: ' . _q($r->{approved_routing_id});
    push @o, '  formalization_id: ' . _q($r->{formalization_id});
    push @o, '  verification_id: ' . _q($r->{verification_id});
    push @o, '  feasibility_id: ' . _q($r->{feasibility_id});
    push @o, '  feasibility_status: ' . _q($r->{feasibility_status});
    push @o, '  status: ' . _q($r->{status});
    push @o, '  implementation_allowed: ' . _qb($r->{implementation_allowed});
    push @o, '  implementation_planning_allowed: ' . _qb($r->{implementation_planning_allowed});
    push @o, '  next_stage: ' . ($r->{next_stage} // 'null');
    push @o, '  mathematically_valid: ' . _qb($r->{mathematically_valid});
    push @o, '  statistically_meaningful: ' . _qb($r->{statistically_meaningful});
    push @o, '  required_data_available: ' . _qb($r->{required_data_available});
    push @o, '  pine_compatible: ' . _qb($r->{pine_compatible});
    push @o, '  tradingview_compatible: ' . _qb($r->{tradingview_compatible});
    push @o, '  mtf_valid: ' . _qb($r->{mtf_valid});
    push @o, '  repaint_risk: ' . _q($r->{repaint_risk});
    push @o, '  runtime_risk: ' . _q($r->{runtime_risk});
    push @o, '  numerical_stability: ' . _qb($r->{numerical_stability});
    push @o, '  recommendation: ' . _q($r->{recommendation});
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
    if (!@{ $r->{unknowns} }) { push @o, '  unknowns: []'; }
    else {
        push @o, '  unknowns:';
        for my $u (@{ $r->{unknowns} }) { push @o, '    - { id: ' . _q($u->{id}) . ', subject: ' . _q($u->{subject}) . ', critical: ' . _q($u->{critical}) . ", status: 'UNKNOWN_REQUIRES_VERIFICATION', refs: " . _ql($u->{refs}) . ' }'; }
    }
    if (!@{ $r->{partial_items} }) { push @o, '  partial_items: []'; }
    else {
        push @o, '  partial_items:';
        for my $pi (@{ $r->{partial_items} }) {
            push @o, '    - { requirement: ' . _q($pi->{requirement}) . ', feasible_part: ' . _q($pi->{feasible_part}) . ', non_feasible_part: ' . _q($pi->{non_feasible_part}) . ', semantic_difference: ' . _q($pi->{semantic_difference}) . ' }';
        }
    }
    if (!@{ $r->{unsupported} }) { push @o, '  unsupported_items: []'; }
    else {
        push @o, '  unsupported_items:';
        for my $u (@{ $r->{unsupported} }) { push @o, '    - { subject: ' . _q($u->{subject}) . ', basis: ' . _q($u->{basis}) . ', refs: ' . _ql($u->{refs}) . ' }'; }
    }
    if (!@{ $r->{capabilities} }) { push @o, '  capabilities: []'; }
    else {
        push @o, '  capabilities:';
        for my $cp (@{ $r->{capabilities} }) { push @o, '    - { capability: ' . _q($cp->{capability}) . ', status: ' . _q($cp->{status}) . ', basis: ' . _q($cp->{basis}) . ' }'; }
    }
    if (!@{ $r->{constraints} }) { push @o, '  constraints: []'; }
    else {
        push @o, '  constraints:';
        for my $cn (@{ $r->{constraints} }) { push @o, '    - { constraint: ' . _q($cn->{constraint}) . ', basis: ' . _q($cn->{basis}) . ' }'; }
    }
    if (!@{ $r->{data_requirements} }) { push @o, '  data_requirements: []'; }
    else {
        push @o, '  data_requirements:';
        for my $dr (@{ $r->{data_requirements} }) { push @o, '    - { index: ' . _q($dr->{index}) . ', kind: ' . _q($dr->{kind}) . ', timeframe: ' . _q($dr->{timeframe}) . ', verdict: ' . _q($dr->{verdict}) . ' }'; }
    }
    if (!@{ $r->{platform_requirements} }) { push @o, '  platform_requirements: []'; }
    else {
        push @o, '  platform_requirements:';
        for my $pr (@{ $r->{platform_requirements} }) { push @o, '    - { requirement: ' . _q($pr->{requirement}) . ', status: ' . _q($pr->{status}) . ', basis: ' . _q($pr->{basis}) . ' }'; }
    }
    push @o, '  traceability:';
    push @o, '    source_skills: ' . _ql($r->{source_skills});
    push @o, '    verification_requirements: ' . _ql($r->{verification_requirements});
    push @o, '    implementation_constraints: ' . _ql($r->{implementation_constraints});
    push @o, '  requirement_classifications:';
    my @rk = sort keys %{ $r->{req_class} || {} };
    if (!@rk) { push @o, '    []'; }
    else { for my $k (@rk) { push @o, '    - { requirement: ' . _q($k) . ', classification: ' . _q($r->{req_class}{$k}) . ' }'; } }
    push @o, '  notes: []';
    push @o, '  next_stage_note: ' . _q((($r->{next_stage} // '') eq 'IMPLEMENTATION_PLANNING') ? 'Implementation Planning may start' : 'pipeline halted — downstream progression forbidden');
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# gate-check on a RESULT file: approved iff feasibility_id well-formed,
# feasibility_status FEASIBLE|FEASIBLE_WITH_WARNINGS, blockers [],
# implementation_planning_allowed true, next_stage IMPLEMENTATION_PLANNING
# ---------------------------------------------------------------------------
sub gate_check_text {
    my ($t) = @_;
    my ($fid) = $t =~ /^\s{2}feasibility_id:\s*'([^']*)'/m;
    my ($res) = $t =~ /^\s{2}feasibility_status:\s*'([^']*)'/m;
    my ($ipa) = $t =~ /^\s{2}implementation_planning_allowed:\s*(true|false)/m;
    my ($ns)  = $t =~ /^\s{2}next_stage:\s*(\S+)/m;
    my $blockers_empty = ($t =~ /^  blockers: \[\]/m) ? 1 : 0;
    return (0, 'feasibility_id missing or malformed') unless defined $fid && $fid =~ /^feas-[0-9a-f]{12}$/;
    return (0, "feasibility_status is '$res' — downstream progression forbidden") unless defined $res && ($res eq 'FEASIBLE' || $res eq 'FEASIBLE_WITH_WARNINGS');
    return (0, 'blockers list is non-empty') unless $blockers_empty;
    return (0, "implementation_planning_allowed is '$ipa'") unless defined $ipa && $ipa eq 'true';
    return (0, "next_stage is '$ns'") unless defined $ns && $ns eq 'IMPLEMENTATION_PLANNING';
    return (1, "approved_feasibility_id = $fid");
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return decode('UTF-8', $t); }

sub default_config_path {
    # normalize separators first: MSYS/Strawberry-perl edge cases where
    # File::Basename does not treat '\' as a separator (dirname returns '.')
    (my $f = __FILE__) =~ s{\\}{/}g;
    my $dir = dirname($f);
    return "$dir/../config/feasibility.yaml";
}

sub main {
    my ($contract_file, $pre_file, $out_file, $gate, $cfg_file, $feas_file) = (undef, undef, undef, 0, undef, undef);
    while (@ARGV) {
        my $a = shift @ARGV;
        if    ($a eq '--contract')   { $contract_file = shift @ARGV; }
        elsif ($a eq '--pre')        { $pre_file = shift @ARGV; }
        elsif ($a eq '--out')        { $out_file = shift @ARGV; }
        elsif ($a eq '--config')     { $cfg_file = shift @ARGV; }
        elsif ($a eq '--feasibility'){ $feas_file = shift @ARGV; }
        elsif ($a eq '--gate-check') { $gate = 1; }
        elsif ($a eq '--selftest')   { my $st = selftest(); exit $st; }
        else { die "unknown argument '$a'\n"; }
    }
    my $cfg = parse_config(_slurp($cfg_file // default_config_path()));
    if ($gate) {
        die "usage with --gate-check: --feasibility FILE\n" unless defined $feas_file && $feas_file ne '';
        my $t = _slurp($feas_file);
        my ($ok, $msg) = gate_check_text($t);
        print "$msg\n";
        exit($ok ? 0 : 2);
    }
    die "usage: feasibility.pl --contract FILE --pre FILE [--out FILE] | --gate-check --feasibility FILE | --selftest\n" if !$contract_file || !$pre_file;
    my $ct = _slurp($contract_file);
    my $pt = _slurp($pre_file);
    my $r = feasibility_text($ct, $pt, $cfg);
    my $yaml = encode('UTF-8', result_to_yaml($r));
    if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh $yaml; close $fh; }
    else { print $yaml; }
    exit(($r->{feasibility_status} eq 'FEASIBLE' || $r->{feasibility_status} eq 'FEASIBLE_WITH_WARNINGS') ? 0 : 2);
}

# ---------------------------------------------------------------------------
# selftest — the 22 mandated acceptance cases (TEST-FEAS-001..022)
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };
    my $cfg = eval { parse_config(_slurp(default_config_path())) } or die "selftest cannot load config: $@\n";

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
    my $feas = sub { return feasibility_text($_[0], $_[1], $cfg); };
    my $code_has = sub { my ($r, $code) = @_; return scalar grep { ($_->{code} // '') eq $code } @{ $r->{blockers} || [] }; };
    my $warn_has = sub { my ($r, $code) = @_; return scalar grep { ($_->{code} // '') eq $code } @{ $r->{warnings} || [] }; };

    # T-FEAS-001 valid PASS pre -> FEASIBLE (mandated #1)
    my $r1 = $feas->($BASE_C, $PRE);
    $ok->(defined $r1 && $r1->{feasibility_status} eq 'FEASIBLE', 'T-FEAS-001 status FEASIBLE');
    $ok->($r1->{implementation_planning_allowed} && $r1->{next_stage} eq 'IMPLEMENTATION_PLANNING' && $r1->{status} eq 'passed', 'T-FEAS-001 gates open');
    $ok->((scalar @{ $r1->{checks} } == 12 && !grep { $_->{verdict} ne 'pass' } @{ $r1->{checks} }), 'T-FEAS-001 12 checks all pass');

    # T-FEAS-002 PASS_WITH_WARNINGS pre -> FEASIBLE_WITH_WARNINGS (mandated #2)
    my $high_c = $fx->("repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "repaint_risk: 'high — mechanism: unconfirmed HTF data'");
    my $pre_w = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-cccccccccccc', vid => 'pre-222222222222', result => 'PASS_WITH_WARNINGS', status => 'passed',
        warn_block => "    - { id: 'G-001', check_id: 'PC10', code: 'W-REPAINT-ACCEPT', message: 'high repaint' }");
    my $r2 = $feas->($high_c, $pre_w);
    $ok->($r2->{feasibility_status} eq 'FEASIBLE_WITH_WARNINGS' && $r2->{implementation_planning_allowed}, 'T-FEAS-002 warnings do not block');
    $ok->($warn_has->($r2, 'W-REPAINT-ACCEPT'), 'T-FEAS-002 repaint acceptance surfaced');

    # T-FEAS-003 blocked pre -> BLOCKED (mandated #3)
    my $pre_b = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-cccccccccccc', vid => 'pre-333333333333', result => 'BLOCKED', status => 'blocked');
    my $r3 = $feas->($BASE_C, $pre_b);
    $ok->($r3->{feasibility_status} eq 'BLOCKED' && $r3->{next_stage} eq 'HALT' && !$r3->{implementation_planning_allowed}, 'T-FEAS-003 BLOCKED');
    $ok->($code_has->($r3, 'B-HANDOFF-STATUS'), 'T-FEAS-003 B-HANDOFF-STATUS');

    # T-FEAS-004 invalid pre handoff variants (mandated #4)
    my $pre_badres = $mk_pre->(request_id => 'req-aaaaaaaaaaaa', approved_routing_id => 'rout-bbbbbbbbbbbb',
        formalization_id => 'form-cccccccccccc', vid => 'pre-444444444444', result => 'INVALID_INPUT', status => 'blocked');
    my $r4a = $feas->($BASE_C, $pre_badres);
    $ok->($r4a->{feasibility_status} eq 'BLOCKED' && $code_has->($r4a, 'B-HANDOFF-STATUS'), 'T-FEAS-004a non-PASS result refused');
    my $pre_badchain = $PRE; $pre_badchain =~ s/formalization_id: 'form-cccccccccccc'/formalization_id: 'form-dddddddddddd'/;
    my $r4b = $feas->($BASE_C, $pre_badchain);
    $ok->($r4b->{feasibility_status} eq 'BLOCKED' && $code_has->($r4b, 'B-HANDOFF-CHAIN'), 'T-FEAS-004b chain mismatch refused');

    # T-FEAS-005 unsupported Pine capability -> NOT_FEASIBLE (mandated #5)
    my $q_c = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on bar close using quandl data'");
    my $r5 = $feas->($q_c, $PRE);
    $ok->($r5->{feasibility_status} eq 'NOT_FEASIBLE' && $r5->{next_stage} eq 'HALT', 'T-FEAS-005 NOT_FEASIBLE');
    $ok->($code_has->($r5, 'B-CAP-UNAVAILABLE') && scalar @{ $r5->{unsupported} } == 1, 'T-FEAS-005 unsupported item recorded');

    # T-FEAS-006 unavailable data (mandated #6)
    my $ob_c = $fx->("  required_data: []" => "  required_data:\n    - { kind: 'order book', symbol_hint: null, timeframe: '15m', notes: 'dom' }", "  mtf: false" => '  mtf: true');
    my $r6 = $feas->($ob_c, $PRE);
    $ok->($r6->{feasibility_status} eq 'NOT_FEASIBLE' && $code_has->($r6, 'B-DATA-UNAVAILABLE'), 'T-FEAS-006 B-DATA-UNAVAILABLE');
    $ok->($r6->{req_class}{'required_data[1]'} eq 'NOT_FEASIBLE', 'T-FEAS-006 data requirement classified NOT_FEASIBLE');
    $ok->((grep { ($_->{verdict} // '') eq 'NOT_FEASIBLE' } @{ $r6->{data_requirements} }), 'T-FEAS-006 data_requirements verdict');

    # T-FEAS-007 MTF incompatibility: meaningless timeframe (mandated #7)
    my $tf_c = $fx->("  required_data: []" => "  required_data:\n    - { kind: 'htf price', symbol_hint: null, timeframe: '7X', notes: 'htf' }", "  mtf: false" => '  mtf: true', "repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "repaint_risk: 'high — mechanism: unconfirmed HTF data'");
    my $r7 = $feas->($tf_c, $PRE);
    $ok->($r7->{feasibility_status} eq 'NOT_FEASIBLE' && $code_has->($r7, 'B-TF-INVALID'), 'T-FEAS-007 B-TF-INVALID');

    # T-FEAS-008 repaint-sensitive requirement (mandated #8)
    $ok->($warn_has->($r7, 'W-REPAINT-ACCEPT'), 'T-FEAS-008 repaint acceptance surfaced');
    $ok->((grep { ($_->{constraint} // '') =~ /mirrored verbatim/ } @{ $r7->{constraints} }), 'T-FEAS-008 classification mirrored, never altered');

    # T-FEAS-009 resource-limit constraint: advisory unknown, no invented limits (mandated #9)
    my $lab_c = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on bar close and plot a table label'");
    my $r9 = $feas->($lab_c, $PRE);
    $ok->($r9->{feasibility_status} eq 'FEASIBLE_WITH_WARNINGS' && $warn_has->($r9, 'W-LIMIT-UNKNOWN'), 'T-FEAS-009 W-LIMIT-UNKNOWN advisory');
    $ok->((grep { ($_->{id} // '') eq 'U-DRAW' && ($_->{critical} // '') eq 'false' } @{ $r9->{unknowns} }), 'T-FEAS-009 advisory unknown recorded');

    # T-FEAS-010 alert limitation -> partial (mandated #10)
    my $al_c = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on every tick with an alert'");
    my $r10 = $feas->($al_c, $PRE);
    $ok->($r10->{feasibility_status} eq 'PARTIALLY_FEASIBLE' && $r10->{next_stage} eq 'HALT' && !$r10->{implementation_planning_allowed}, 'T-FEAS-010 PARTIALLY_FEASIBLE halts');
    $ok->(scalar @{ $r10->{partial_items} } == 1, 'T-FEAS-010 partial item recorded');
    $ok->($r10->{req_class}{'C-1'} eq 'PARTIAL', 'T-FEAS-010 C-1 classified PARTIAL (never upgraded)');
    $ok->($r10->{recommendation} eq 'needs_user_input', 'T-FEAS-010 recommendation needs_user_input');

    # T-FEAS-011 exact feasibility (mandated #11)
    $ok->(($r1->{req_class}{'C-1'} eq 'EXACT' && !grep { $_ ne 'EXACT' } values %{ $r1->{req_class} }), 'T-FEAS-011 all requirements EXACT');

    # T-FEAS-012 partial feasibility explicit portions (mandated #12)
    $ok->((grep { $_->{feasible_part} && $_->{non_feasible_part} && $_->{semantic_difference} } @{ $r10->{partial_items} }), 'T-FEAS-012 partial portions explicit');

    # T-FEAS-013 not feasible (mandated #13) — see also T-FEAS-005/006
    $ok->($r6->{req_class}{'required_data[1]'} eq 'NOT_FEASIBLE' && $r6->{status} eq 'failed', 'T-FEAS-013 NOT_FEASIBLE classification + status failed');

    # T-FEAS-014 unknown capability: advisory (prose) vs critical (load-bearing) (mandated #14)
    my $wv_c = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on bar close using wavelet denoising'");
    my $r14a = $feas->($wv_c, $PRE);
    $ok->($r14a->{feasibility_status} eq 'FEASIBLE_WITH_WARNINGS' && $warn_has->($r14a, 'W-UNKNOWN-CAP'), 'T-FEAS-014a prose unknown is advisory (warns, does not block)');
    $ok->((!grep { ($_->{code} // '') eq 'B-UNKNOWN-CRITICAL' } @{ $r14a->{blockers} }), 'T-FEAS-014a no critical blocker for prose unknown');
    my $wv_f = $fx->("  formulas: []" => "  formulas:\n    - { id: 'F-1', expression: 'close minus wavelet denoised close', description: 'wavelet based filter', depends_on: '' }");
    my $r14b = $feas->($wv_f, $PRE);
    $ok->($code_has->($r14b, 'B-UNKNOWN-CRITICAL') && $r14b->{feasibility_status} eq 'NOT_FEASIBLE', 'T-FEAS-014b load-bearing unknown blocks');
    $ok->($r14b->{req_class}{'F-1'} eq 'UNKNOWN_REQUIRES_VERIFICATION', 'T-FEAS-014b F-1 classified UNKNOWN_REQUIRES_VERIFICATION');

    # T-FEAS-015 traceability: every finding has refs (mandated #15)
    for my $rr ($r1, $r5, $r6, $r7, $r10, $r14b) {
        $ok->((!grep { !@{ $_->{refs} || [] } } @{ $rr->{findings} }), 'T-FEAS-015 findings carry refs');
    }

    # T-FEAS-016 deterministic feasibility_id (mandated #16)
    my ($ra, $rb) = ($feas->($BASE_C, $PRE), $feas->($BASE_C, $PRE));
    $ok->($ra->{feasibility_id} eq $rb->{feasibility_id}, 'T-FEAS-016 id stable');
    my $rc = $feas->($fx->("    chart: '15m'" => "    chart: '1h'"), $PRE);
    $ok->($ra->{feasibility_id} ne $rc->{feasibility_id}, 'T-FEAS-016 id content-sensitive');

    # T-FEAS-017 byte-identical repeated output (mandated #17)
    $ok->(result_to_yaml($ra) eq result_to_yaml($rb), 'T-FEAS-017 byte-identical');
    $ok->(result_to_yaml($ra) ne result_to_yaml($rc), 'T-FEAS-017 distinct inputs differ');

    # T-FEAS-018 malformed input -> INVALID_INPUT (mandated #18)
    my $r18a = $feas->("\tnot a contract }}}", $PRE);
    $ok->(($r18a->{feasibility_status} eq 'INVALID_INPUT' && grep { ($_->{code} // '') eq 'B-INPUT' } @{ $r18a->{blockers} }), 'T-FEAS-018a malformed contract');
    my $r18b = $feas->($BASE_C, "\tnot a result }}}");
    $ok->(($r18b->{feasibility_status} eq 'INVALID_INPUT' && grep { ($_->{code} // '') eq 'B-INPUT' } @{ $r18b->{blockers} }), 'T-FEAS-018b malformed pre');
    my $r18c = $feas->($BASE_C, undef);
    $ok->($r18c->{feasibility_status} eq 'INVALID_INPUT', 'T-FEAS-018c missing pre');
    $ok->($r18c->{next_stage} eq 'HALT' && !$r18c->{implementation_planning_allowed}, 'T-FEAS-018c INVALID_INPUT halts');

    # T-FEAS-019 no-Pine output invariant (mandated #19)
    {
        my $out = result_to_yaml($r1);
        my $pine_free = 1;
        for my $tok ('//@version', 'indicator(', 'strategy(', 'library(', 'ta.sma', 'ta.rsi') { $pine_free = 0 if index($out, $tok) >= 0; }
        $ok->($pine_free, 'T-FEAS-019 no Pine constructs in result');
    }

    # T-FEAS-020 downstream --gate-check (mandated #20)
    require File::Temp;
    my ($fh1, $p1) = File::Temp::tempfile(SUFFIX => '.yaml');
    binmode $fh1, ':raw'; print $fh1 encode('UTF-8', result_to_yaml($ra)); close $fh1;
    my ($okg, $msgg) = gate_check_text(_slurp($p1));
    $ok->($okg && $msgg =~ /approved_feasibility_id = feas-[0-9a-f]{12}/, 'T-FEAS-020a gate approves FEASIBLE');
    my ($fh2, $p2) = File::Temp::tempfile(SUFFIX => '.yaml');
    binmode $fh2, ':raw'; print $fh2 encode('UTF-8', result_to_yaml($r10)); close $fh2;
    my ($okb, $msgb) = gate_check_text(_slurp($p2));
    $ok->(!$okb && $msgb =~ /forbidden|non-empty|malformed/, 'T-FEAS-020b gate refuses PARTIALLY_FEASIBLE');
    my ($fh3, $p3) = File::Temp::tempfile(SUFFIX => '.yaml');
    binmode $fh3, ':raw'; print $fh3 encode('UTF-8', result_to_yaml($r3)); close $fh3;
    my ($okc,) = gate_check_text(_slurp($p3));
    $ok->(!$okc && $r3->{next_stage} eq 'HALT' && !$r3->{implementation_planning_allowed}, 'T-FEAS-020c gate refuses BLOCKED; HALT');
    1 while unlink $p1; 1 while unlink $p2; 1 while unlink $p3;

    # T-FEAS-021 Persian UTF-8 determinism (mandated #21)
    {
        my $fa_c = $fx->("natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'نزدیک شدن قیمت به خط روند و تاییدیه کندل در تایم فریم بالاتر'");
        my $fa1 = $feas->($fa_c, $PRE);
        my $fa2 = $feas->($fa_c, $PRE);
        $ok->(defined $fa1 && $fa1->{feasibility_id} eq $fa2->{feasibility_id}, 'T-FEAS-021 Persian determinism');
        $ok->(result_to_yaml($fa1) eq result_to_yaml($fa2), 'T-FEAS-021 Persian byte-identical');
        $ok->($fa1->{feasibility_status} eq 'FEASIBLE', 'T-FEAS-021 Persian prose produces no false capability claims');
        $ok->(scalar @{ $fa1->{capabilities} } == 0, 'T-FEAS-021 no invented capabilities for non-matching prose');
    }

    # T-FEAS-022 no silent fallback invariant (mandated #22)
    {
        my $out5 = result_to_yaml($r5);
        $ok->($out5 =~ /no substitution applied/, 'T-FEAS-022 unsupported recorded, not substituted');
        $ok->($r5->{feasibility_status} eq 'NOT_FEASIBLE', 'T-FEAS-022 unavailable capability halts (never PARTIAL-with-substitution)');
        $ok->((!grep { ($_->{classification} // '') eq 'PARTIAL' } map { { classification => $_ } } values %{ $r5->{req_class} }), 'T-FEAS-022 no PARTIAL downgrade for unavailable capability');
    }

    print "SELFTEST: $pass passed, $fail failed\n";
    print "All TEST-FEAS-001..022 acceptance cases pass (feasibility contract v1.1).\n" if !$fail;
    return $fail ? 1 : 0;
}

main() unless caller;
1;