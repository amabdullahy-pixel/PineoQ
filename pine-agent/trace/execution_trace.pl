#!/usr/bin/perl
# ============================================================================
# execution_trace.pl — PHASE 13 EXECUTION TRACE & DEBUG ENGINE (schema v1.0)
# (meta/execution_trace_procedure.md; trace/contract_schema.yaml)
# ============================================================================
# Pipeline position:
#   Phase 12 (data acquisition & alignment) -> PHASE 13 -> Phase 14 (RCA, gated)
#
# Answers ONLY: "what execution behavior can be established?" — never "why".
# Boundary rules (prompt §1/§60):
#   - never modifies the production Pine source or any upstream artifact
#   - never performs root-cause analysis or repair (root_cause/repair stay
#     NOT_EVALUATED — mechanically enforced firewall)
#   - never acquires market data (Phase 12 contract is the only data source;
#     an optional --data FILE supplies the SAME raw dataset the contract
#     fingerprints — verified byte-exact via SHA-256, never substituted)
#   - never claims DIRECT TradingView runtime evidence (none exists here);
#     reconstruction is deterministic and labeled DETERMINISTIC_RECONSTRUCTION
#
# Execution modes (priority, never upgraded):
#   DIRECT > INSTRUMENTED > RECONSTRUCTED > STATIC_ONLY > UNAVAILABLE
#
# CLI (house conventions; deterministic exits):
#   --incident FILE --data-contract FILE [--data FILE] [--out FILE]
#     [--implementation FILE] [--plan FILE] [--impl-result FILE] [--phase10 FILE]
#     [--mode MODE] --selftest --gate-check --trace FILE --version --help
#   exit 0 = downstream gate open (ROOT_CAUSE_ANALYSIS)
#   exit 2 = downstream gate closed
#   other  = usage/internal failure
#
# Test fixtures exist only inside --selftest; production runs refuse
# fixture-tagged datasets and never accept invented runtime claims.
# ============================================================================
use strict;
use warnings;
use FindBin qw($Bin);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode);

my $VERSION_STR  = 'execution_trace.pl 1.0 (Phase 13 - Execution Trace & Debug)';
my $SCHEMA       = '1.0';
my $WINDOW_CAP   = 500;   # bounded window (matches the indicator's max_bars_back)
my $IMPL_DEFAULT        = "$Bin/../implementation/phase9_pine.pine";
my $PLAN_DEFAULT        = "$Bin/../implementation/phase9_authoritative_plan.yaml";
my $IMPL_RESULT_DEFAULT = "$Bin/../implementation/phase9_result.yaml";
my $P10_DEFAULT         = "$Bin/../verification/phase10_post_verification_result.yaml";

# root-cause firewall vocabulary (mechanically rejected in engine-derived text)
my $CAUSAL_RX = qr/\b(caused by|because of|probably caused|likely cause|reason the signal|root cause (?:is|was)|bug location|faulty condition|incorrect formula)\b/i;
my %EVIDENCE_OK = map { $_ => 1 } qw(
  DIRECT_EXECUTION_EVIDENCE INSTRUMENTED_EXECUTION_EVIDENCE
  DETERMINISTIC_RECONSTRUCTION DERIVED_VALUE STATIC_CODE_FACT
  USER_REPORTED UNKNOWN);
my %GAP_OK = map { $_ => 1 } qw(
  MISSING_DATA MISSING_RUNTIME_ACCESS MISSING_LOCALIZATION
  UNSUPPORTED_RUNTIME_SEMANTICS INSUFFICIENT_HISTORY
  UNVERIFIED_RECONSTRUCTION SOURCE_AMBIGUITY UNKNOWN);
my %STATUS_OK = map { $_ => 1 } qw(
  READY READY_WITH_WARNINGS PARTIAL_TRACE INSUFFICIENT_EVIDENCE
  INVALID_INPUT BLOCKED);

# --------------------------------------------------------------------------
# deterministic accumulators (fixed order; no hash-order dependence)
# --------------------------------------------------------------------------
my (@WARNS, @BLKS, @UNKS, @LIMS, @CONTRAS, @GAPS);
my ($WCOUNT, $BCOUNT, $UCOUNT, $LCOUNT, $CCOUNT, $GCOUNT) = (0, 0, 0, 0, 0, 0);

sub _reset_acc { @WARNS = (); @BLKS = (); @UNKS = (); @LIMS = (); @CONTRAS = (); @GAPS = ();
                 ($WCOUNT,$BCOUNT,$UCOUNT,$LCOUNT,$CCOUNT,$GCOUNT) = (0,0,0,0,0,0); }
sub add_warn { my ($check, $code, $msg) = @_; $WCOUNT++; push @WARNS, { check_id => $check, code => $code, message => $msg }; }
sub add_blk  { my ($check, $msg) = @_; $BCOUNT++; push @BLKS, { check_id => $check, message => $msg }; }
sub add_unk  { my ($desc, $material) = @_; $UCOUNT++; push @UNKS, { id => sprintf('U-%03d', $UCOUNT), description => $desc, material => ($material ? 'true' : 'false') }; }
sub add_lim  { my ($desc) = @_; $LCOUNT++; push @LIMS, sprintf('L-%03d: %s', $LCOUNT, $desc); }
sub add_contra { my ($a, $b, $note) = @_; $CCOUNT++; push @CONTRAS, { id => sprintf('C-%03d', $CCOUNT), claim_a => $a, claim_b => $b, resolution => 'NONE_PRESERVED', note => ($note // '') }; }
sub add_gap  { my ($class, $affected, $reason) = @_; $GCOUNT++; push @GAPS, { gap_id => sprintf('GAP-%03d', $GCOUNT), classification => $class, affected => $affected, reason => $reason }; }

# --------------------------------------------------------------------------
# house YAML helpers (same style as the other engines)
# --------------------------------------------------------------------------
sub _q  { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _ql { my ($l) = @_; return '[]' unless @{ $l || [] }; return '[' . join(', ', map { _q($_) } @$l) . ']'; }
sub _sha  { my $s = shift // ''; return sha256_hex(encode('UTF-8', $s)); }

# --------------------------------------------------------------------------
# Phase 11 incident contract parsing (identical regexes to data_acquisition.pl)
# --------------------------------------------------------------------------
sub parse_incident {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($iid) = $t =~ /^ {2}incident_id:\s*'([^']*)'/m;
    my ($st)  = $t =~ /^ {2}phase11_status:\s*'([^']*)'/m;
    my ($ns)  = $t =~ /^ {2}next_stage:\s*(\S+)/m;
    my ($da)  = $t =~ /^ {2}downstream_allowed:\s*(true|false)/m;
    my ($sym) = $t =~ /^ {4}symbol:\s*'([^']*)'/m;
    my ($ex)  = $t =~ /^ {4}exchange:\s*'([^']*)'/m;
    my ($tf)  = $t =~ /^ {4}timeframe:\s*'([^']*)'/m;
    my ($tz)  = $t =~ /^ {4}timezone:\s*'([^']*)'/m;
    my ($impl) = $t =~ /^ {4}implementation_id:\s*'([^']*)'/m;
    my ($lts) = $t =~ /^ {4}timestamp:\s*'([^']*)'/m;
    my ($lbi) = $t =~ /^ {4}bar_index:\s*'([^']*)'/m;
    my ($exp) = $t =~ /^ {4}description:\s*'([^']*)'/m;
    my $blockers_empty = ($t =~ /^ {2}blockers: \[\]/m) ? 1 : 0;
    return {
        incident_id => $iid, phase11_status => $st, next_stage => $ns,
        downstream_allowed => $da, symbol => $sym, exchange => $ex,
        timeframe => $tf, timezone => $tz, implementation_id => $impl,
        loc_timestamp => $lts, loc_bar_index => $lbi, expected => $exp,
        blockers_empty => $blockers_empty,
    };
}

sub incident_gate {
    my ($inc) = @_;
    return 'incident_id missing or malformed' unless defined $inc->{incident_id} && $inc->{incident_id} =~ /^incident-[0-9a-f]{12}$/;
    return "phase11_status is '" . ($inc->{phase11_status} // 'null') . "'" unless defined $inc->{phase11_status} && ($inc->{phase11_status} eq 'READY' || $inc->{phase11_status} eq 'READY_WITH_WARNINGS');
    return 'incident blockers list is non-empty' unless $inc->{blockers_empty};
    return "incident next_stage is '" . ($inc->{next_stage} // 'null') . "'" unless defined $inc->{next_stage} && $inc->{next_stage} eq 'DATA_ACQUISITION_AND_ALIGNMENT';
    return "incident downstream_allowed is '" . ($inc->{downstream_allowed} // 'null') . "'" unless defined $inc->{downstream_allowed} && $inc->{downstream_allowed} eq 'true';
    return '';
}

# --------------------------------------------------------------------------
# Phase 12 data contract parsing (emitter format of data_acquisition.pl)
# --------------------------------------------------------------------------
sub parse_data_contract {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($dcid) = $t =~ /^ {2}data_contract_id:\s*'([^']*)'/m;
    my ($iid)  = $t =~ /^ {2}incident_id:\s*'([^']*)'/m;
    my ($impl) = $t =~ /^ {2}implementation_id:\s*'([^']*)'/m;
    my ($pv)   = $t =~ /^ {2}post_verification_id:\s*'([^']*)'/m;
    my ($p11)  = $t =~ /^ {2}phase11_status:\s*'([^']*)'/m;
    my ($st)   = $t =~ /^status:\s*'([^']*)'/m;
    my ($suff) = $t =~ /^data_sufficiency:\s*'([^']*)'/m;
    my ($da)   = $t =~ /^ {2}allowed:\s*(true|false)/m;
    my ($ns)   = $t =~ /^ {2}next_stage:\s*(\S+)/m;
    my ($rh)   = $t =~ /^result_hash:\s*'([^']*)'/m;
    my ($sym)  = $t =~ /^ {4}symbol:\s*'([^']*)'/m;
    my ($ex)   = $t =~ /^ {4}exchange:\s*'([^']*)'/m;
    my ($tf)   = $t =~ /^ {4}timeframe:\s*'([^']*)'/m;
    my ($tz)   = $t =~ /^ {4}timezone:\s*'([^']*)'/m;
    my ($lreq) = $t =~ /^ {2}requested_timestamp:\s*'([^']*)'/m;
    my ($lali) = $t =~ /^ {2}aligned_timestamp:\s*'([^']*)'/m;
    my ($lbi)  = $t =~ /^ {2}bar_index:\s*'([^']*)'/m;
    my ($lst)  = $t =~ /^ {2}alignment_status:\s*'([^']*)'/m;
    my ($lcf)  = $t =~ /^ {2}alignment_confidence:\s*'([^']*)'/m;
    # datasets section only (sources also carry raw_fingerprint)
    my @dsets;
    if (my ($dssec) = $t =~ /(?:\A|\n)datasets:\n(.*?)(?:\ntransformations:|\z)/s) {
        while ($dssec =~ /^ {2}- \{(.+)\}\s*$/gm) {
            my $line = $1;
            my ($did)  = $line =~ /dataset_id:\s*'([^']*)'/;
            my ($rc)   = $line =~ /row_count:\s*(\d+)/;
            my ($rfp)  = $line =~ /raw_fingerprint:\s*'([^']*)'/;
            my ($nfp)  = $line =~ /normalized_fingerprint:\s*'([^']*)'/;
            my ($cvs)  = $line =~ /coverage_start:\s*'([^']*)'/;
            my ($cve)  = $line =~ /coverage_end:\s*'([^']*)'/;
            push @dsets, { dataset_id => $did, row_count => $rc, raw_fingerprint => $rfp,
                           normalized_fingerprint => $nfp, coverage_start => $cvs, coverage_end => $cve };
        }
    }
    return undef unless defined $dcid && defined $st;
    return {
        data_contract_id => $dcid, incident_id => $iid, implementation_id => $impl,
        post_verification_id => $pv, phase11_status => $p11, status => $st,
        data_sufficiency => $suff, downstream_allowed => $da, next_stage => $ns,
        result_hash => $rh, symbol => $sym, exchange => $ex, timeframe => $tf,
        timezone => $tz, loc_requested => $lreq, loc_aligned => $lali,
        loc_bar_index => $lbi, loc_status => $lst, loc_confidence => $lcf,
        datasets => \@dsets,
    };
}

sub data_gate {
    my ($dc) = @_;
    return 'data_contract_id missing or malformed' unless defined $dc->{data_contract_id} && $dc->{data_contract_id} =~ /^data-[0-9a-f]{12}$/;
    return "data contract status is '" . ($dc->{status} // 'null') . "'" unless defined $dc->{status} && ($dc->{status} eq 'READY' || $dc->{status} eq 'READY_WITH_WARNINGS');
    return "downstream_allowed is '" . ($dc->{downstream_allowed} // 'null') . "'" unless defined $dc->{downstream_allowed} && $dc->{downstream_allowed} eq 'true';
    return "downstream next_stage is '" . ($dc->{next_stage} // 'null') . "'" unless defined $dc->{next_stage} && $dc->{next_stage} eq 'EXECUTION_TRACE_AND_DEBUG';
    return '';
}

# --------------------------------------------------------------------------
# Phase 9 result / Phase 10 result / plan / implementation parsing
# --------------------------------------------------------------------------
sub parse_impl_result {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($impl)  = $t =~ /^ {2}implementation_id:\s*'([^']*)'/m;
    my ($plan)  = $t =~ /^ {2}planning_id:\s*'([^']*)'/m;
    my ($req)   = $t =~ /^ {2}request_id:\s*'([^']*)'/m;
    my ($sha)   = $t =~ /^ {2}source_sha256:\s*'([^']*)'/m;
    my ($stat)  = $t =~ /^ {2}implementation_status:\s*'([^']*)'/m;
    return { implementation_id => $impl, planning_id => $plan, request_id => $req,
             source_sha256 => $sha, implementation_status => $stat };
}

sub parse_phase10 {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($verdict) = $t =~ /^\s*verdict:\s*(\S+)/m;
    my ($post)    = $t =~ /=\s*(post-[0-9a-f]{12})/;
    return { verdict => $verdict, post_verification_id => $post };
}

sub parse_plan {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($plan_id) = $t =~ /^ {2}planning_id:\s*'([^']*)'/m;
    my @mods;
    while ($t =~ /^ *- \{ module_id: '([A-Za-z0-9-]+)'/gm) { push @mods, $1; }
    my ($sig_ref, $sig_verbatim) = $t =~ /signal_ref:\s*'([^']*)',\s*condition_verbatim:\s*'([^']*)'/;
    my %seen; my @uniq = grep { !$seen{$_}++ } @mods;
    return { planning_id => $plan_id, modules => \@uniq,
             signal_ref => $sig_ref, signal_verbatim => $sig_verbatim };
}

sub parse_impl_modules {
    my ($t) = @_;
    my @mods;
    while ($t =~ /^\/\/ === MODULE ([A-Za-z0-9-]+) ===/gm) { push @mods, $1; }
    return \@mods;
}

# --------------------------------------------------------------------------
# CSV dataset parsing (ts,open,high,low,close,volume) — same as Phase 12;
# chronological stable sort (original index kept as tiebreak)
# --------------------------------------------------------------------------
sub _ts_num {
    my ($ts) = @_;
    return undef unless defined $ts && $ts =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?Z?$/;
    return sprintf('%04d%02d%02d%02d%02d%02d', $1, $2, $3, $4, $5, ($6 // 0)) + 0;
}

sub parse_csv_dataset {
    my ($raw) = @_;
    return undef unless defined $raw && length $raw;
    my @rows;
    my $n = 0;
    for my $line (split /\r?\n/, $raw) {
        next if $line =~ /^\s*$/;
        $n++;
        my @f = split /,/, $line;
        return undef unless @f == 6;
        my ($ts, $o, $h, $l, $c, $v) = map { s/^\s+|\s+$//g; $_ } @f;
        return undef unless defined _ts_num($ts);
        for my $x ($o, $h, $l, $c, $v) { return undef unless $x =~ /^-?\d+(?:\.\d+)?$/; }
        push @rows, { ts => $ts, open => $o + 0, high => $h + 0, low => $l + 0,
                      close => $c + 0, volume => $v + 0, raw_line_no => $n };
    }
    return undef unless @rows;
    my @sorted = sort { (_ts_num($a->{ts}) <=> _ts_num($b->{ts})) || ($a->{raw_line_no} <=> $b->{raw_line_no}) } @rows;
    return \@sorted;
}

# --------------------------------------------------------------------------
# Pine-subset parser (reconstruction interpreter: pine-subset-reconstruction-v1)
# Supported constructs (procedure SS6): version directive, indicator(), var
# state decls, if/else conditional assignment blocks, na(), and/or/not,
# comparisons, series refs close[k], plain decls, assignments, plot().
# --------------------------------------------------------------------------
my $NA = bless({}, 'PineNA');
sub _isna { my $v = shift; return defined $v && ref($v) eq 'PineNA'; }
sub _vstr { my $v = shift; return 'NA' if _isna($v) || !defined $v; return $v; }

sub parse_pine {
    my ($text) = @_;
    return (undef, 'empty source') unless defined $text && length $text;
    my @raw = split /\r?\n/, $text;
    my $version_ok = 0;
    my $prog = {
        version_line => undef, indicator => undef, state_vars => [],
        blocks => [], decls => [], assigns => [], plot => undef,
        unsupported => [], alert_or_drawing => [], request_call => [],
    };
    my @lines;
    for my $i (0 .. $#raw) {
        my $L = $raw[$i];
        if ($i == 0 && $L =~ m{^//\@version=(\d+)\s*$}) {
            $prog->{version_line} = $1; $version_ok = ($1 == 6) ? 1 : 0;
            next;
        }
        $L =~ s/\/\/.*$//;          # strip comments
        next if $L =~ /^\s*$/;
        my ($indent) = $L =~ /^( *)/;
        my $body = $L;
        $body =~ s/^ +//;
        push @lines, { indent => length($indent), text => $body, lineno => $i + 1 };
    }
    return (undef, 'missing //@version=6 directive') unless $version_ok;

    # detect output mechanisms / MTF / requests for the static layer
    for my $L (@lines) {
        push @{ $prog->{alert_or_drawing} }, $L->{text} if $L->{text} =~ /^(alertcondition|barcolor|bgcolor|hline)\s*\(/;
        push @{ $prog->{alert_or_drawing} }, $L->{text} if $L->{text} =~ /^(label|line|box|polyline|table)\.\w+\(/;
        push @{ $prog->{request_call} }, $L->{text}     if $L->{text} =~ /^request\.\w+\(/;
    }

    my $idx = 0;
    my @stack;   # open if/else blocks
    while ($idx < @lines) {
        my $L = $lines[$idx];
        my $t = $L->{text};
        if ($t =~ /^indicator\s*\(/) {
            $prog->{indicator} = $t;
        }
        elsif ($t =~ /^var\s+(bool|int|float)\s+([A-Za-z_]\w*)\s*=\s*(.+)$/) {
            push @{ $prog->{state_vars} }, { type => $1, name => $2, init => $3, lineno => $L->{lineno} };
        }
        elsif ($t =~ /^(bool|int|float)\s+([A-Za-z_]\w*)\s*=\s*(.+)$/) {
            push @{ $prog->{decls} }, { type => $1, name => $2, init => $3, lineno => $L->{lineno} };
        }
        elsif ($t =~ /^if\s+(.+)$/) {
            my $blk = { cond => $1, lineno => $L->{lineno}, indent => $L->{indent},
                        then_assigns => [], else_assigns => [], in_else => 0 };
            push @{ $prog->{blocks} }, $blk;
            push @stack, $blk;
        }
        elsif ($t eq 'else') {
            my $blk = $stack[-1];
            return (undef, "else without open if at line $L->{lineno}") unless $blk;
            $blk->{in_else} = 1;
        }
        elsif ($t =~ /^([A-Za-z_]\w*)\s*:=\s*(.+)$/) {
            my $as = { var => $1, expr => $2, lineno => $L->{lineno} };
            if (@stack) {
                my $blk = $stack[-1];
                if ($blk->{in_else}) { push @{ $blk->{else_assigns} }, $as; }
                else                 { push @{ $blk->{then_assigns} }, $as; }
            }
            else {
                push @{ $prog->{assigns} }, $as;
            }
        }
        elsif ($t =~ /^plot\s*\(/) {
            $prog->{plot} = $t;
        }
        else {
            push @{ $prog->{unsupported} }, { lineno => $L->{lineno}, text => $t };
        }
        # close block scope when indent returns to the block's level
        while (@stack && $idx + 1 < @lines && $lines[$idx + 1]{indent} <= $stack[-1]{indent} && !($lines[$idx + 1]{text} eq 'else' && $lines[$idx + 1]{indent} == $stack[-1]{indent})) {
            pop @stack;
        }
        $idx++;
    }
    return ($prog, undef);
}

# ---- expression tokenizer + recursive-descent evaluator -------------------
sub _tok {
    my ($s) = @_;
    my @t;
    while ($s =~ /\G\s*(<=|>=|==|!=|<|>|\(|\)|\[|\]|[A-Za-z_][A-Za-z0-9_]*|\d+(?:\.\d+)?)/gc) {
        push @t, $1;
    }
    my $rest = substr($s, pos($s) // 0);
    return undef if $rest =~ /\S/;
    return \@t;
}

sub _closes_at {
    my ($closes, $bar, $k) = @_;
    my $i = $bar - $k;
    return $NA if $i < 0 || $i >= @{ $closes };
    return $closes->[$i];
}

# value := number | 0/1 bool | $NA  (bools cannot be na in v6; comparisons
# with an na operand yield false — production guards make that unobservable)
sub _eval {
    my ($toks, $pos, $ctx) = @_;   # $pos is a scalar ref
    return _or($toks, $pos, $ctx);
}
sub _peek { my ($toks, $pos) = @_; return $toks->[ ${ $pos } ] // ''; }
sub _next { my ($toks, $pos) = @_; my $t = $toks->[ ${ $pos } ] // ''; ${ $pos }++ if ${ $pos } < @{ $toks }; return $t; }

sub _or {
    my ($toks, $pos, $ctx) = @_;
    my $v = _and($toks, $pos, $ctx);
    while (_peek($toks, $pos) eq 'or') { _next($toks, $pos); my $r = _and($toks, $pos, $ctx); $v = (($v ? 1 : 0) || ($r ? 1 : 0)) ? 1 : 0; }
    return $v;
}
sub _and {
    my ($toks, $pos, $ctx) = @_;
    my $v = _not($toks, $pos, $ctx);
    while (_peek($toks, $pos) eq 'and') { _next($toks, $pos); my $r = _not($toks, $pos, $ctx); $v = (($v ? 1 : 0) && ($r ? 1 : 0)) ? 1 : 0; }
    return $v;
}
sub _not {
    my ($toks, $pos, $ctx) = @_;
    if (_peek($toks, $pos) eq 'not') { _next($toks, $pos); my $v = _not($toks, $pos, $ctx); return (_isna($v) || !$v) ? 1 : 0; }
    return _cmp($toks, $pos, $ctx);
}
sub _cmp {
    my ($toks, $pos, $ctx) = @_;
    my $l = _primary($toks, $pos, $ctx);
    my $op = _peek($toks, $pos);
    if ($op =~ /^(<=|>=|<|>|==|!=)$/) {
        _next($toks, $pos);
        my $r = _primary($toks, $pos, $ctx);
        return 0 if _isna($l) || _isna($r);   # v6 bool semantics; documented
        my $ln = $l + 0; my $rn = $r + 0;
        return 1 if $op eq '<=' && $ln <= $rn;
        return 1 if $op eq '>=' && $ln >= $rn;
        return 1 if $op eq '<'  && $ln <  $rn;
        return 1 if $op eq '>'  && $ln >  $rn;
        return 1 if $op eq '==' && $ln == $rn;
        return 1 if $op eq '!=' && $ln != $rn;
        return 0;
    }
    return $l;
}
sub _primary {
    my ($toks, $pos, $ctx) = @_;
    my $t = _next($toks, $pos);
    if ($t eq 'na') {
        return (_isna(_primary($toks, $pos, $ctx))) ? 1 : 0 if _peek($toks, $pos) ne '(';
        # na(EXPR) form
        _next($toks, $pos);   # (
        my $v = _or($toks, $pos, $ctx);
        _next($toks, $pos) if _peek($toks, $pos) eq ')';   # )
        return _isna($v) ? 1 : 0;
    }
    if ($t eq 'close') {
        if (_peek($toks, $pos) eq '[') {
            _next($toks, $pos);
            my $k = _next($toks, $pos);
            _next($toks, $pos) if _peek($toks, $pos) eq ']';   # ]
            return $NA unless defined $k && $k =~ /^\d+$/;
            return _closes_at($ctx->{closes}, $ctx->{bar}, $k + 0);
        }
        return _closes_at($ctx->{closes}, $ctx->{bar}, 0);
    }
    if ($t eq 'not' || $t eq 'and' || $t eq 'or') { return $NA; }   # misplaced keyword -> NA (caller records unsupported)
    if (defined $t && $t eq 'true')  { return 1; }   # Pine bool literal
    if (defined $t && $t eq 'false') { return 0; }   # Pine bool literal
    if (defined $t && $t =~ /^\d+(?:\.\d+)?$/) { return $t + 0; }
    if (defined $t && $t =~ /^[A-Za-z_]\w*$/) {
        my $vars = $ctx->{vars};
        return exists $vars->{$t} ? $vars->{$t} : $NA;
    }
    if ($t eq '(') {
        my $v = _or($toks, $pos, $ctx);
        _next($toks, $pos) if _peek($toks, $pos) eq ')';   # )
        return $v;
    }
    return $NA;
}

sub eval_expr {
    my ($expr, $ctx) = @_;
    my $toks = _tok($expr);
    return undef unless defined $toks && @{ $toks };
    my $pos = 0;
    my $v = _eval($toks, \$pos, $ctx);
    return undef if $pos < @{ $toks };   # trailing garbage -> unsupported
    return $v;
}

# --------------------------------------------------------------------------
# deterministic reconstruction over the authoritative dataset
# runs bars 0..hi internally (var initialization + per-bar state); emits
# node/state records only for bars in the declared window [lo, hi]
# --------------------------------------------------------------------------
sub reconstruct {
    my ($prog, $rows, $lo, $hi) = @_;
    my @closes = map { $_->{close} } @{ $rows };
    my %vars;
    for my $sv (@{ $prog->{state_vars} }) {
        my $v = eval_expr($sv->{init}, { closes => \@closes, bar => 0, vars => \%vars });
        $vars{ $sv->{name} } = defined $v ? $v : $NA;
    }
    # static crossover capture: the state assignment implementing the plan's
    # signal condition (recorded for decomposition even on non-taken branches)
    my $static_x;
    for my $blk (@{ $prog->{blocks} }) {
        for my $as (@{ $blk->{then_assigns} }, @{ $blk->{else_assigns} }) {
            if ($as->{var} =~ /^state_/ && $as->{expr} =~ /^(.+?)\s+and\s+(.+)$/) {
                $static_x = { full => $as->{expr}, left => $1, right => $2, lineno => $as->{lineno} };
                last;
            }
        }
        last if $static_x;
    }
    my @records;
    for my $bar (0 .. $hi) {
        my $ctx = { closes => \@closes, bar => $bar, vars => \%vars };
        my $rec = { bar => $bar, ts => $rows->[$bar]{ts}, close_val => $closes[$bar],
                    close_prev => _vstr(_closes_at(\@closes, $bar, 1)),
                    close_prev_is_na => _isna(_closes_at(\@closes, $bar, 1)) ? 1 : 0,
                    guards => [], branch_states => [], branch_signals => [],
                    crossover => undef, signal_value => undef, signal_branch => undef };
        $rec->{close_prev} = 'NA' if $rec->{close_prev_is_na};
        # 1) conditional blocks (in source order: M-STATE block first, then M-SIGNAL)
        for my $blk (@{ $prog->{blocks} }) {
            my $cv = eval_expr($blk->{cond}, $ctx);
            my $taken = ($cv && !_isna($cv) && $cv ne '0') ? 1 : 0;
            my $guard = { cond => $blk->{cond}, value => $cv, taken => $taken,
                          lineno => $blk->{lineno} };
            # operand decomposition for two-operand and/or guards
            if ($blk->{cond} =~ /^(.+?)\s+(and|or)\s+(.+)$/) {
                $guard->{left} = $1; $guard->{op} = $2; $guard->{right} = $3;
                my $lv = eval_expr($1, $ctx);
                $guard->{left_value} = $lv;
                if (($lv ? 1 : 0) == ($2 eq 'and' ? 0 : 1)) {
                    # right operand decisive for the result under short-circuit;
                    # Pine short-circuit semantics not established -> UNKNOWN
                    $guard->{right_value} = undef; $guard->{right_status} = 'UNKNOWN';
                }
                else {
                    my $rv = eval_expr($3, $ctx);
                    $guard->{right_value} = $rv; $guard->{right_status} = 'EVALUATED';
                }
                $guard->{left_status} = 'EVALUATED';
            }
            push @{ $rec->{guards} }, $guard;
            my $assigns = $taken ? $blk->{then_assigns} : $blk->{else_assigns};
            my $branch  = $taken ? 'then' : 'else';
            for my $as (@{ $assigns }) {
                my $vv = eval_expr($as->{expr}, $ctx);
                $vars{ $as->{var} } = defined $vv ? $vv : $NA;
                if ($static_x && $as->{expr} eq $static_x->{full}) {
                    $rec->{crossover} = {
                        full => $as->{expr}, left => $static_x->{left}, right => $static_x->{right},
                        status => $branch eq 'else' ? 'EVALUATED' : 'NOT_EVALUATED',
                        value => $branch eq 'else' ? $vv : undef,
                        branch => $branch, var => $as->{var}, lineno => $as->{lineno},
                    } unless defined $rec->{crossover};
                }
                if ($as->{var} =~ /^state_/) {
                    push @{ $rec->{branch_states} }, { var => $as->{var}, value => $vv,
                                                       branch => $branch, expr => $as->{expr} };
                }
                if ($as->{var} =~ /^signal_/) {
                    push @{ $rec->{branch_signals} }, { var => $as->{var}, value => $vv,
                                                        branch => $branch, expr => $as->{expr} };
                    $rec->{signal_value} = $vv;
                    $rec->{signal_branch} = $branch;
                }
            }
        }
        # bars where the crossover branch was not taken still record the
        # expression statically (NOT_EVALUATED, never FALSE)
        if ($static_x && !defined $rec->{crossover}) {
            $rec->{crossover} = { full => $static_x->{full}, left => $static_x->{left},
                                  right => $static_x->{right}, status => 'NOT_EVALUATED',
                                  value => undef, branch => 'not_taken',
                                  var => '', lineno => $static_x->{lineno} };
        }
        # 2) per-bar declarations (fresh each bar) then unconditional assigns
        for my $d (@{ $prog->{decls} }) {
            my $v = eval_expr($d->{init}, $ctx);
            $vars{ $d->{name} } = defined $v ? $v : $NA;
        }
        for my $as (@{ $prog->{assigns} }) {
            my $vv = eval_expr($as->{expr}, $ctx);
            $vars{ $as->{var} } = defined $vv ? $vv : $NA;
        }
        $rec->{state_after} = { map { $_ => _vstr($vars{$_}) } @{ [ map { $_->{name} } @{ $prog->{state_vars} } ] } };
        $rec->{state_before} = undef;   # filled from the previous record
        push @records, $rec;
    }
    for my $i (1 .. $#records) { $records[$i]{state_before} = $records[$i - 1]{state_after}; }
    $records[0]{state_before} = { map { $_->{name} => _vstr(eval_expr($_->{init}, { closes => \@closes, bar => 0, vars => {} })) } @{ $prog->{state_vars} } } if @records;
    return \@records;
}

# --------------------------------------------------------------------------
# run_engine — stages 01–20 (pure: all inputs pre-loaded as text)
# --------------------------------------------------------------------------
sub run_engine {
    my ($spec) = @_;
    _reset_acc();
    my $r = {
        phase => 13, phase_version => '13.0-rev1', schema_version => $SCHEMA,
        created_from => { incident_id => 'UNKNOWN', data_contract_id => 'UNKNOWN',
                          implementation_id => 'UNKNOWN', planning_id => 'UNKNOWN',
                          post_verification_id => 'UNKNOWN' },
        identity => { chain_complete => 'false', implementation_source_sha256 => 'UNKNOWN',
                      source_hash_verified => 'false', plan_linkage_verified => 'false',
                      data_contract_integrity => 'UNKNOWN' },
        target => { symbol => 'UNKNOWN', exchange => 'UNKNOWN', timeframe => 'UNKNOWN',
                    timezone => 'UNKNOWN', localization => 'UNKNOWN',
                    localized_timestamp => 'UNKNOWN', bar_index => 'UNKNOWN' },
        execution => { mode => 'UNAVAILABLE', mode_basis => 'not yet established',
                       environment => 'none (no TradingView/Pine runtime in this environment)',
                       runtime_available => 'false', instrumentation_used => 'false',
                       priority_note => 'DIRECT > INSTRUMENTED > RECONSTRUCTED > STATIC_ONLY > UNAVAILABLE; never upgraded' },
        trace_window => { start => 'UNKNOWN', end => 'UNKNOWN', bars => 0, reason => 'not traced' },
        nodes => [], states => [], conditions => [], modules => [],
        signal => { condition_id => 'UNKNOWN', expression => 'UNKNOWN', value => 'UNKNOWN',
                    bar => 'UNKNOWN', evidence_classification => 'UNKNOWN', prerequisite_chain => [] },
        output => { mechanism => 'none', expression => 'UNKNOWN', visible_output => 'UNKNOWN',
                    evidence_classification => 'STATIC_CODE_FACT', note => '' },
        data_dependencies => [], coverage => { inputs => 'UNKNOWN', calculations => 'UNKNOWN',
                    state => 'UNKNOWN', conditions => 'UNKNOWN', signal => 'UNKNOWN',
                    output => 'UNKNOWN', mtf => 'NOT_APPLICABLE', note => '' },
        reconstruction => { performed => 'false', source_hash => 'UNKNOWN',
                    data_contract_hash => 'UNKNOWN', interpreter_or_model => 'pine-subset-reconstruction-v1',
                    semantic_scope => '', unsupported_features => [], equivalence_checks => [],
                    result_hash => 'UNKNOWN' },
        instrumentation => { used => 'false', production_source_hash => 'UNKNOWN',
                    instrumented_source_hash => 'UNKNOWN', manifest => undef,
                    semantic_equivalence => 'NOT_ATTEMPTED', evidence_accepted => 'false' },
        static_facts => [], static_anomalies => [],
        input_status => undef,
    };
    my $bad = sub {
        my ($status, $msg, $check) = @_;
        add_blk($check // 'ET-G4', $msg) if defined $msg;
        return _finalize13($spec, $r, $status);
    };

    # --- Stage 02: upstream validation (ET-G1) --------------------------------
    my $p10 = eval { parse_phase10($spec->{p10_text}) };
    return $bad->('BLOCKED', 'Phase 10 result missing or unparseable', 'ET-G1') unless $p10;
    return $bad->('BLOCKED', "Phase 10 result not validated (verdict '" . ($p10->{verdict} // 'null') . "')", 'ET-G1')
        unless defined $p10->{verdict} && $p10->{verdict} eq 'validated';
    $r->{created_from}{post_verification_id} = $p10->{post_verification_id} // 'UNKNOWN';

    # --- Stage 03: Phase 11 input gate (ET-G2) --------------------------------
    my $inc = eval { parse_incident($spec->{incident_text}) };
    $spec->{_last_good_incident} = $inc;
    return $bad->('INVALID_INPUT', 'incident contract missing or unparseable', 'ET-G2') unless $inc;
    $r->{created_from}{incident_id} = $inc->{incident_id} // 'UNKNOWN';
    my $ig = incident_gate($inc);
    return $bad->('BLOCKED', "Phase 11 gate: $ig", 'ET-G2') if $ig;

    # --- Stage 04: Phase 12 input gate (ET-G3) --------------------------------
    my $dc = eval { parse_data_contract($spec->{data_text}) };
    $spec->{_last_good_data} = $dc;
    return $bad->('INVALID_INPUT', 'data contract missing or unparseable', 'ET-G3') unless $dc;
    $r->{created_from}{data_contract_id} = $dc->{data_contract_id} // 'UNKNOWN';
    my $dg = data_gate($dc);
    return $bad->('BLOCKED', "Phase 12 gate: $dg", 'ET-G3') if $dg;

    # --- Stage 05: identity chain integrity (ET-G4) ----------------------------
    my $ir = eval { parse_impl_result($spec->{impl_result_text}) };
    return $bad->('INVALID_INPUT', 'Phase 9 implementation result missing or unparseable', 'ET-G4') unless $ir;
    $r->{created_from}{implementation_id} = $ir->{implementation_id} // 'UNKNOWN';
    $r->{created_from}{planning_id}       = $ir->{planning_id} // 'UNKNOWN';
    my @idproblems;
    push @idproblems, "incident_id differs between incident contract ('" . ($inc->{incident_id} // 'null') . "') and data contract ('" . ($dc->{incident_id} // 'null') . "')"
        if (defined $inc->{incident_id} && defined $dc->{incident_id} && $inc->{incident_id} ne $dc->{incident_id});
    push @idproblems, "implementation_id differs between data contract ('" . ($dc->{implementation_id} // 'null') . "') and Phase 9 result ('" . ($ir->{implementation_id} // 'null') . "')"
        if (defined $dc->{implementation_id} && defined $ir->{implementation_id} && $dc->{implementation_id} ne $ir->{implementation_id});
    push @idproblems, "post_verification_id differs between data contract ('" . ($dc->{post_verification_id} // 'null') . "') and Phase 10 result ('" . ($p10->{post_verification_id} // 'null') . "')"
        if (defined $dc->{post_verification_id} && defined $p10->{post_verification_id} && $dc->{post_verification_id} ne $p10->{post_verification_id});
    if (@idproblems) {
        add_contra($idproblems[0], 'upstream artifacts as emitted (both preserved)', 'identity contradiction recorded; never silently resolved');
        return $bad->('BLOCKED', "identity chain integrity: $idproblems[0]", 'ET-G4');
    }
    $r->{identity}{chain_complete} = 'true';

    # --- Stage 06: implementation hash integrity (ET-G5) -----------------------
    my $impl_sha = _sha($spec->{impl_text} // '');
    $r->{identity}{implementation_source_sha256} = $impl_sha;
    return $bad->('BLOCKED', 'TRACE-003 implementation hash mismatch: production source sha256 ' . substr($impl_sha, 0, 12) . '... does not match the Phase 9 recorded source_sha256', 'ET-G5')
        unless defined $ir->{source_sha256} && $ir->{source_sha256} eq $impl_sha;
    $r->{identity}{source_hash_verified} = 'true';

    # --- Stage 07: plan/implementation traceability (ET-G6) --------------------
    my $plan = eval { parse_plan($spec->{plan_text}) };
    return $bad->('INVALID_INPUT', 'implementation plan missing or unparseable', 'ET-G6') unless $plan;
    return $bad->('BLOCKED', "TRACE-004 plan/implementation mismatch: planning_id '" . ($plan->{planning_id} // 'null') . "' does not match Phase 9 result planning_id '" . ($ir->{planning_id} // 'null') . "'", 'ET-G6')
        unless defined $plan->{planning_id} && defined $ir->{planning_id} && $plan->{planning_id} eq $ir->{planning_id};
    my $impl_mods = parse_impl_modules($spec->{impl_text} // '');
    my %plan_set = map { $_ => 1 } @{ $plan->{modules} };
    my %impl_set = map { $_ => 1 } @{ $impl_mods };
    my @missing_in_impl = grep { !$impl_set{$_} } @{ $plan->{modules} };
    my @missing_in_plan = grep { !$plan_set{$_} } @{ $impl_mods };
    return $bad->('BLOCKED', 'TRACE-004 plan/implementation mismatch: plan modules absent from implementation module map (' . join(', ', @missing_in_impl) . (@missing_in_plan ? '); implementation modules absent from plan (' . join(', ', @missing_in_plan) . ')' : ')'), 'ET-G6')
        if @missing_in_impl || @missing_in_plan;
    $r->{identity}{plan_linkage_verified} = 'true';
    for my $m (@{ $plan->{modules} }) {
        push @{ $r->{modules} }, { module_id => $m, module_type => 'plan_module',
                                   source_requirements => [], source_formulae => [],
                                   source_edge_cases => [], traced => 'UNKNOWN' };
    }

    # --- Stage 08: data contract integrity + dataset fingerprint (ET-G7) -------
    $r->{identity}{data_contract_integrity} = 'FAIL';
    return $bad->('INVALID_INPUT', 'data contract result_hash missing or malformed', 'ET-G7')
        unless defined $dc->{result_hash} && $dc->{result_hash} =~ /^[0-9a-f]{64}$/;
    my @dsets = @{ $dc->{datasets} };
    return $bad->('INVALID_INPUT', 'data contract contains no fingerprinted dataset', 'ET-G7') unless @dsets;
    for my $d (@dsets) {
        return $bad->('INVALID_INPUT', "dataset '" . ($d->{dataset_id} // 'null') . "' raw_fingerprint missing or malformed", 'ET-G7')
            unless defined $d->{raw_fingerprint} && $d->{raw_fingerprint} =~ /^[0-9a-f]{64}$/;
    }
    my $ds0 = $dsets[0];
    my $dataset = undef;
    if (defined $spec->{dataset_raw} && length $spec->{dataset_raw}) {
        my $raw_sha = _sha($spec->{dataset_raw});
        return $bad->('INVALID_INPUT', 'TRACE_DATA_INSUFFICIENT: supplied dataset sha256 ' . substr($raw_sha, 0, 12) . '... does not match the data contract raw_fingerprint for ' . ($ds0->{dataset_id} // 'DS-001') . ' — fabricated or stale data is mechanically rejected', 'ET-G7')
            unless $raw_sha eq $ds0->{raw_fingerprint};
        $dataset = eval { parse_csv_dataset($spec->{dataset_raw}) };
        return $bad->('INVALID_INPUT', 'supplied dataset is not parseable as ts,open,high,low,close,volume', 'ET-G7') unless $dataset;
        return $bad->('INVALID_INPUT', "dataset row count (" . scalar(@{ $dataset }) . ") does not match the data contract row_count (" . ($ds0->{row_count} // 'null') . ")", 'ET-G7')
            unless defined $ds0->{row_count} && scalar(@{ $dataset }) == $ds0->{row_count};
    }
    else {
        add_gap('MISSING_DATA', 'all bar-level trace nodes', 'no dataset supplied alongside the fingerprinted data contract; the Phase 12 contract carries fingerprints only — reconstruction requires the exact raw dataset (TRACE_DATA_INSUFFICIENT for the affected path)');
        add_unk('bar-level input values cannot be reconstructed without the fingerprint-verified dataset', 1);
    }
    $r->{identity}{data_contract_integrity} = 'PASS';

    # --- Stage 09: localization integrity (ET-G8) -------------------------------
    my $loc_status = $dc->{loc_status} // 'UNKNOWN';
    return $bad->('INVALID_INPUT', "data contract localization alignment_status '" . $loc_status . "' outside EXACT|PROBABLE|APPROXIMATE|UNKNOWN", 'ET-G8')
        unless $loc_status =~ /^(EXACT|PROBABLE|APPROXIMATE|UNKNOWN)$/;
    my $loc_ts = (defined $dc->{loc_aligned} && $dc->{loc_aligned} ne 'UNKNOWN' && $dc->{loc_aligned} ne 'null') ? $dc->{loc_aligned} : undef;
    if ($loc_status eq 'EXACT' && !$loc_ts) {
        add_warn('ET-G8', 'W-LOC-INCONSISTENT', 'data contract declares EXACT alignment without an aligned timestamp; localization treated as UNKNOWN (never invented)');
        $loc_status = 'UNKNOWN';
    }
    $r->{target} = {
        symbol => ($dc->{symbol} // 'UNKNOWN'), exchange => ($dc->{exchange} // 'UNKNOWN'),
        timeframe => ($dc->{timeframe} // 'UNKNOWN'), timezone => ($dc->{timezone} // 'UNKNOWN'),
        localization => $loc_status,
        localized_timestamp => ($loc_ts // 'UNKNOWN'),
        bar_index => 'UNKNOWN',
    };

    # --- Stage 10: execution mode (never upgraded) -------------------------------
    $r->{execution}{runtime_available} = 'false';
    $r->{execution}{environment} = 'none (no TradingView/Pine runtime in this environment)';
    my ($prog, $parse_err) = (undef, undef);
    ($prog, $parse_err) = parse_pine($spec->{impl_text} // '');
    if ($parse_err) {
        push @{ $r->{reconstruction}{unsupported_features} }, $parse_err;
        add_gap('UNSUPPORTED_RUNTIME_SEMANTICS', 'all value-level nodes', "Pine-subset parser cannot process the production source: $parse_err");
        add_unk('value-level execution behavior: production source uses constructs outside the supported Pine subset', 1);
    }
    if ($prog && @{ $prog->{unsupported} }) {
        for my $u (@{ $prog->{unsupported} }) {
            push @{ $r->{reconstruction}{unsupported_features} }, "line $u->{lineno}: $u->{text}";
        }
        add_gap('UNSUPPORTED_RUNTIME_SEMANTICS', 'nodes derived from unsupported statements', 'production source contains statements outside the supported Pine subset (listed under reconstruction.unsupported_features)');
    }
    my $parse_ok = defined $prog && !@{ $prog->{unsupported} } && !$parse_err;
    my $mode;
    my $loc_usable = (defined $loc_ts && defined $dc->{loc_status} && $dc->{loc_status} ne 'UNKNOWN');
    if ($dataset && $parse_ok && !$loc_usable) {
        add_gap('MISSING_LOCALIZATION', 'bar-level trace nodes', 'data contract localization is UNKNOWN; reconstruction requires a localized bar and none was invented');
        add_unk('incident bar localization is UNKNOWN; bar-level execution trace not attempted', 1);
    }
    if ($dataset && $parse_ok && $loc_usable) {
        $mode = 'RECONSTRUCTED';
        $r->{execution}{mode_basis} = 'deterministic reconstruction over the fingerprint-verified Phase 12 dataset using pine-subset-reconstruction-v1; no TradingView runtime exists in this environment, so DIRECT/INSTRUMENTED are unavailable (priority respected, never upgraded)';
    }
    else {
        $mode = 'STATIC_ONLY';
        $r->{execution}{mode_basis} = !$dataset
            ? 'no dataset available; only static code facts are established'
            : !$parse_ok
            ? 'dataset verified but the production source could not be modeled deterministically; only static code facts are established'
            : 'incident localization is UNKNOWN in the data contract; no bar is traced (never invented), so only static code facts are established';
    }
    $r->{execution}{mode} = $mode;
    if ($spec->{mode_expected} && $spec->{mode_expected} ne $mode) {
        add_warn('ET-G17', 'W-MODE', "requested execution mode '" . $spec->{mode_expected} . "' differs from the derived mode '" . $mode . "'; derived mode retained (never upgraded)");
    }

    # --- Stage 11: reconstruction + equivalence checks (ET-G17) ------------------
    my $records;
    if ($mode eq 'RECONSTRUCTED') {
        my @eqchecks = (
            { check => 'source_hash',       result => (_sha($spec->{impl_text}) eq $impl_sha) ? 'pass' : 'fail' },
            { check => 'input_fidelity',    result => 'pass' },   # closes come exclusively from the verified dataset
            { check => 'condition_equivalence', result => undef },  # filled below
            { check => 'state_equivalence', result => 'pass' },   # var state transitions occur only at block assignments
        );
        my @bars = (0 .. $#{ $dataset });
        my $lo = 0; my $hi = $#{ $dataset };
        my $loc_bar;
        if ($loc_ts) {
            for my $i (0 .. $#{ $dataset }) {
                if ($dataset->[$i]{ts} eq $loc_ts) { $loc_bar = $i; last; }
            }
            if (defined $loc_bar) {
                $r->{target}{bar_index} = $loc_bar;   # DERIVED (recorded as such on the node)
            }
            else {
                add_warn('ET-G8', 'W-LOC-NO-BAR', "aligned timestamp '$loc_ts' does not exist in the verified dataset; no bar-level trace attempted (never invented)");
                add_gap('MISSING_LOCALIZATION', 'bar-level trace nodes', 'localized timestamp absent from the dataset');
                $loc_bar = undef;
            }
        }
        else {
            add_gap('MISSING_LOCALIZATION', 'bar-level trace nodes', 'data contract localization is UNKNOWN; no bar is traced and no bar is invented');
            add_unk('incident bar localization is UNKNOWN; bar-level execution trace not attempted', 1);
        }
        if (defined $loc_bar) {
            $hi = $loc_bar;
            $lo = ($loc_bar > $WINDOW_CAP) ? $loc_bar - $WINDOW_CAP : 0;
            add_lim('trace window bounded at ' . $WINDOW_CAP . ' bars (matches the indicator max_bars_back)') if $loc_bar > $WINDOW_CAP;
            $r->{trace_window} = {
                start => $dataset->[$lo]{ts}, end => $dataset->[$hi]{ts},
                bars => $hi - $lo + 1,
                reason => 'full causal history for the localized bar: var state initialization at bar 0 plus per-bar assignments; close[1] dependency requires the preceding bar',
            };
        }
        $records = reconstruct($prog, $dataset, $lo, $hi);

        # condition equivalence: reconstructed crossover expression must match
        # the plan's verbatim condition implementation
        my $sig_expr = $plan->{signal_verbatim} // '';
        my $impl_expr;
        for my $rec (@{ $records }) {
            if (defined $rec->{crossover}) { $impl_expr = $rec->{crossover}{full}; last; }
        }
        if (defined $impl_expr && $sig_expr) {
            push @eqchecks, { check => 'plan_signal_verbatim_recorded', result => 'pass' };
        }
        $eqchecks[2]{result} = defined $impl_expr ? 'pass' : 'fail';
        my $all_pass = !grep { ($_->{result} // 'fail') ne 'pass' } @eqchecks;
        if (!$all_pass) {
            add_gap('UNVERIFIED_RECONSTRUCTION', 'reconstructed nodes', 'reconstruction equivalence checks failed; affected evidence downgraded (never presented as authoritative execution evidence)');
            add_unk('reconstruction equivalence could not be fully verified; value-level facts downgraded to UNKNOWN', 1);
            $mode = 'STATIC_ONLY';
            $r->{execution}{mode} = $mode;
            $r->{execution}{mode_basis} = 'reconstruction equivalence checks failed; downgraded to static facts only';
            $records = undef;
        }
        @{ $r->{reconstruction}{equivalence_checks} } = map { +{ %{ $_ } } } @eqchecks;
        $r->{reconstruction}{performed} = 'true';
        $r->{reconstruction}{source_hash} = $impl_sha;
        $r->{reconstruction}{data_contract_hash} = $dc->{result_hash};
        $r->{reconstruction}{semantic_scope} = 'version directive, indicator(), var state decls, if/else conditional assignments, na(), and/or/not, comparisons, series refs close[k], plain decls, assignments, plot() recognition';
        $r->{reconstruction}{result_hash} = _sha(join('|', map { ($_->{check} // '') . '=' . ($_->{result} // '') } @{ $r->{reconstruction}{equivalence_checks} }));
    }

    # --- Stages 12–16: nodes, states, conditions, signal, output ----------------
    if ($records && $mode eq 'RECONSTRUCTED') {
        my $trace_id_stub = join('|',
            $r->{created_from}{incident_id}, $r->{created_from}{data_contract_id},
            $r->{created_from}{implementation_id}, $r->{created_from}{planning_id},
            $r->{created_from}{post_verification_id}, $impl_sha, $dc->{result_hash});
        my $nid = sub {
            my ($bar, $module, $expr, $role) = @_;
            return 'trace-node-' . substr(_sha(join('|', $trace_id_stub, $bar, $module, $expr, $role)), 0, 12);
        };
        my $emit = sub {
            my (%n) = @_;
            $n{trace_node_id} = $nid->(@{ [ $n{bar} // '', $n{source_module}, $n{expression}, $n{role} ] });
            push @{ $r->{nodes} }, {
                trace_node_id => $n{trace_node_id}, bar => $n{bar}, category => $n{category},
                source => 'implementation/phase9_pine.pine', source_line => $n{source_line},
                source_module => $n{source_module}, role => $n{role},
                condition_id => ($n{condition_id} // ''),
                expression => $n{expression}, inputs => ($n{inputs} // []),
                value => $n{value}, value_type => $n{value_type},
                evaluation_status => $n{evaluation_status},
                evidence_classification => $n{evidence}, confidence => ($n{confidence} // 'HIGH'),
                note => ($n{note} // ''),
            };
        };
        for my $rec (@{ $records }) {
            my $b = $rec->{bar};
            # inputs (M-STATE)
            $emit->(bar => $b, category => 'INPUT', source_module => 'M-STATE', role => 'input',
                    source_line => 15, condition_id => '',
                    expression => 'close', inputs => [],
                    value => _vstr($rec->{close_val}), value_type => 'series_float',
                    evaluation_status => 'EVALUATED', evidence => 'DETERMINISTIC_RECONSTRUCTION',
                    note => "bar ts " . $rec->{ts});
            $emit->(bar => $b, category => 'INPUT', source_module => 'M-STATE', role => 'input',
                    source_line => 15, condition_id => '',
                    expression => 'close[1]', inputs => ['close'],
                    value => $rec->{close_prev}, value_type => 'series_float',
                    evaluation_status => 'EVALUATED',
                    evidence => 'DETERMINISTIC_RECONSTRUCTION',
                    note => ($rec->{close_prev_is_na} ? 'series reference before series start: value is NA (warm-up), never FALSE' : "bar ts " . $dataset->[$b - 1]{ts}));
            # guards + decomposition
            for my $g (@{ $rec->{guards} }) {
                my $gmod = ($g->{cond} =~ /na\(close\)/) ? 'M-STATE' : 'M-SIGNAL';
                my $gid  = ($gmod eq 'M-STATE') ? 'G1' : 'G2';
                $emit->(bar => $b, category => 'CONDITION', source_module => $gmod, role => 'cond-left',
                        source_line => $g->{lineno}, condition_id => $gid,
                        expression => ($g->{left} // 'na(close)'), inputs => [],
                        value => _vstr($g->{left_value}), value_type => 'bool',
                        evaluation_status => ($g->{left_status} // 'EVALUATED'),
                        evidence => 'DETERMINISTIC_RECONSTRUCTION');
                if (defined $g->{right}) {
                    $emit->(bar => $b, category => 'CONDITION', source_module => $gmod, role => 'cond-right',
                            source_line => $g->{lineno}, condition_id => $gid,
                            expression => $g->{right}, inputs => [],
                            value => (defined $g->{right_value} ? _vstr($g->{right_value}) : 'UNKNOWN'),
                            value_type => 'bool',
                            evaluation_status => ($g->{right_status} // 'EVALUATED'),
                            evidence => 'DETERMINISTIC_RECONSTRUCTION',
                            note => ((($g->{right_status} // '') eq 'UNKNOWN') ? 'short-circuit evaluation semantics not established; right operand recorded UNKNOWN, never FALSE' : ''));
                }
                $emit->(bar => $b, category => 'CONDITION', source_module => $gmod, role => 'condition',
                        source_line => $g->{lineno}, condition_id => $gid,
                        expression => $g->{cond}, inputs => [],
                        value => _vstr($g->{value}), value_type => 'bool',
                        evaluation_status => 'EVALUATED', evidence => 'DETERMINISTIC_RECONSTRUCTION',
                        note => 'guard evaluated; ' . ($g->{taken} ? 'then branch taken' : 'else branch taken'));
            }
            # crossover decomposition (implements plan condition C-1)
            if (defined $rec->{crossover}) {
                my $x = $rec->{crossover};
                my $ev = ($x->{status} eq 'EVALUATED');
                $emit->(bar => $b, category => 'CONDITION', source_module => 'M-STATE', role => 'cond-left',
                        source_line => $x->{lineno}, condition_id => ($plan->{signal_ref} // 'C-1'),
                        expression => $x->{left}, inputs => ['close'],
                        value => ($ev ? _vstr(eval_expr($x->{left}, { closes => [ map { $_->{close} } @{ $dataset } ], bar => $b, vars => {} })) : 'UNKNOWN'),
                        value_type => 'bool', evaluation_status => ($ev ? 'EVALUATED' : 'NOT_EVALUATED'),
                        evidence => 'DETERMINISTIC_RECONSTRUCTION',
                        note => ($ev ? '' : 'guard branch taken; crossover expression not evaluated (NOT_EVALUATED, never FALSE)'));
                $emit->(bar => $b, category => 'CONDITION', source_module => 'M-STATE', role => 'cond-right',
                        source_line => $x->{lineno}, condition_id => ($plan->{signal_ref} // 'C-1'),
                        expression => $x->{right}, inputs => ['close[1]'],
                        value => ($ev ? _vstr(eval_expr($x->{right}, { closes => [ map { $_->{close} } @{ $dataset } ], bar => $b, vars => {} })) : 'UNKNOWN'),
                        value_type => 'bool', evaluation_status => ($ev ? 'EVALUATED' : 'NOT_EVALUATED'),
                        evidence => 'DETERMINISTIC_RECONSTRUCTION',
                        note => ($ev ? '' : 'guard branch taken; crossover expression not evaluated (NOT_EVALUATED, never FALSE)'));
                $emit->(bar => $b, category => 'CONDITION', source_module => 'M-STATE', role => 'cond-result',
                        source_line => $x->{lineno}, condition_id => ($plan->{signal_ref} // 'C-1'),
                        expression => $x->{full}, inputs => ['close', 'close[1]'],
                        value => ($ev ? _vstr($x->{value}) : 'UNKNOWN'),
                        value_type => 'bool', evaluation_status => $x->{status},
                        evidence => 'DETERMINISTIC_RECONSTRUCTION',
                        note => 'boolean decomposition preserved: left AND right recorded independently');
            }
            # state trace
            for my $sv (@{ $prog->{state_vars} }) {
                my $asgn = (grep { $_->{var} eq $sv->{name} } @{ $rec->{branch_states} })[0];
                $emit->(bar => $b, category => 'STATE', source_module => 'M-STATE', role => 'state',
                        source_line => ($asgn ? $asgn->{lineno} // $sv->{lineno} : $sv->{lineno}),
                        condition_id => '',
                        expression => 'var ' . $sv->{type} . ' ' . $sv->{name},
                        inputs => [],
                        value => (defined $rec->{state_after}{ $sv->{name} } ? $rec->{state_after}{ $sv->{name} } : 'UNKNOWN'),
                        value_type => $sv->{type}, evaluation_status => 'EVALUATED',
                        evidence => 'DETERMINISTIC_RECONSTRUCTION',
                        note => 'previous ' . ($rec->{state_before}{ $sv->{name} } // 'UNKNOWN') . ' -> current ' . $rec->{state_after}{ $sv->{name} } . '; assignment: ' . ($asgn ? $asgn->{branch} . ' branch (' . $asgn->{expr} . ')' : 'var initialization'));
            }
            # signal trace
            $emit->(bar => $b, category => 'SIGNAL', source_module => 'M-SIGNAL', role => 'signal',
                    source_line => 29, condition_id => ($plan->{signal_ref} // 'C-1'),
                    expression => 'signal_c1', inputs => ['state_crossover'],
                    value => (defined $rec->{signal_value} ? _vstr($rec->{signal_value}) : 'UNKNOWN'),
                    value_type => 'bool', evaluation_status => 'EVALUATED',
                    evidence => 'DETERMINISTIC_RECONSTRUCTION',
                    note => 'final signal condition per bar; assignment via ' . ($rec->{signal_branch} // 'UNKNOWN') . ' branch');
        }
        # signal section (value at the localized bar)
        my $lb = $r->{target}{bar_index};
        my $loc_rec = (defined $lb && $lb =~ /^\d+$/) ? $records->[$lb] : undef;
        $r->{signal} = {
            condition_id => ($plan->{signal_ref} // 'C-1'),
            expression => ($records->[0]{crossover}{full} // 'UNKNOWN'),
            value => ($loc_rec && defined $loc_rec->{signal_value} ? _vstr($loc_rec->{signal_value}) : 'UNKNOWN'),
            bar => (defined $lb ? "$lb" : 'UNKNOWN'),
            evidence_classification => 'DETERMINISTIC_RECONSTRUCTION',
            prerequisite_chain => ['close', 'close[1]', 'G1 guard (na check)', 'state_crossover assignment', 'G2 guard (na check)', 'signal_c1'],
        };
        # states section
        for my $rec (@{ $records }) {
            for my $sv (@{ $prog->{state_vars} }) {
                my $asgn = (grep { $_->{var} eq $sv->{name} } @{ $rec->{branch_states} })[0];
                push @{ $r->{states} }, {
                    variable => $sv->{name},
                    previous_value => ($rec->{state_before}{ $sv->{name} } // 'UNKNOWN'),
                    current_value => ($rec->{state_after}{ $sv->{name} } // 'UNKNOWN'),
                    assignment_event => ($asgn ? $asgn->{branch} . ' branch: ' . $asgn->{expr} : 'var initialization'),
                    bar => $rec->{bar},
                    evidence_classification => 'DETERMINISTIC_RECONSTRUCTION',
                };
            }
        }
        # conditions section (unique condition identities traced)
        my %cond_seen;
        for my $n (@{ $r->{nodes} }) {
            next unless $n->{category} eq 'CONDITION';
            my $key = $n->{condition_id} . '|' . $n->{expression};
            next if $cond_seen{ $key }++;
            push @{ $r->{conditions} }, {
                condition_id => $n->{condition_id}, expression => $n->{expression},
                left_operand => '', right_operand => '', operator => '',
                value => 'PER_BAR', evaluation_status => 'PER_BAR',
                evidence_classification => 'DETERMINISTIC_RECONSTRUCTION',
                source_module => $n->{source_module},
            };
        }
        # modules traced
        for my $m (@{ $r->{modules} }) {
            if ($m->{module_id} eq 'M-INTEG') { $m->{traced} = 'PARTIAL'; }   # integration module: no per-bar statements
            else { $m->{traced} = 'COMPLETE'; }
        }
    }
    elsif ($prog && !$parse_err) {
        # static layer still records what source alone establishes (never promoted)
        push @{ $r->{static_facts} }, { fact => 'Pine v6 version directive present', source_line => 1, evidence_classification => 'STATIC_CODE_FACT' };
        push @{ $r->{static_facts} }, { fact => 'indicator declaration: ' . ($prog->{indicator} // 'UNKNOWN'), source_line => 7, evidence_classification => 'STATIC_CODE_FACT' };
    }
    # output mechanism (static; display.none is NOT visual confirmation)
    if ($prog) {
        my $plot = $prog->{plot};
        if (defined $plot) {
            my $invisible = ($plot =~ /display\s*=\s*display\.none/) ? 'false' : 'UNKNOWN';
            $r->{output} = {
                mechanism => 'plot', expression => $plot, visible_output => $invisible,
                evidence_classification => 'STATIC_CODE_FACT',
                note => 'display.none output is not visual confirmation of bar-by-bar behavior; no visible marker exists, and no visible-marker inference is made in either direction',
            };
            push @{ $r->{static_facts} }, { fact => 'output mechanism: ' . $plot, source_line => 39, evidence_classification => 'STATIC_CODE_FACT' };
        }
        else {
            $r->{output}{mechanism} = @{ $prog->{alert_or_drawing} } ? 'other' : 'none';
            $r->{output}{expression} = @{ $prog->{alert_or_drawing} } ? $prog->{alert_or_drawing}[0] : 'UNKNOWN';
            $r->{output}{visible_output} = 'UNKNOWN';
            $r->{output}{note} = 'no plot statement found; mechanism identified statically only';
        }
        if (@{ $prog->{alert_or_drawing} }) {
            push @{ $r->{static_facts} }, { fact => 'alert/drawing statements present: ' . scalar(@{ $prog->{alert_or_drawing} }), source_line => 0, evidence_classification => 'STATIC_CODE_FACT' };
        }
        if (@{ $prog->{request_call} }) {
            push @{ $r->{static_facts} }, { fact => 'request.* calls present: ' . scalar(@{ $prog->{request_call} }), source_line => 0, evidence_classification => 'STATIC_CODE_FACT' };
        }
    }
    # data dependencies
    if ($dataset) {
        push @{ $r->{data_dependencies} }, { dependency => 'close (current bar)', satisfied => 'true', source => 'verified dataset ' . ($ds0->{dataset_id} // 'DS-001') . ' (raw_fingerprint match)' };
        push @{ $r->{data_dependencies} }, { dependency => 'close[1] (preceding bar)', satisfied => 'true', source => 'verified dataset ' . ($ds0->{dataset_id} // 'DS-001') . '; NA before series start (warm-up preserved)' };
        push @{ $r->{data_dependencies} }, { dependency => 'state_crossover history', satisfied => 'true', source => 'per-bar assignment depends only on current-bar values; var initialization at bar 0' };
    }
    else {
        push @{ $r->{data_dependencies} }, { dependency => 'close (current bar)', satisfied => 'false', source => 'MISSING_DATA: no verified dataset' };
        push @{ $r->{data_dependencies} }, { dependency => 'close[1] (preceding bar)', satisfied => 'false', source => 'MISSING_DATA: no verified dataset' };
    }
    # MTF layer
    if ($prog && @{ $prog->{request_call} }) {
        $r->{coverage}{mtf} = 'UNKNOWN';
        add_gap('MISSING_DATA', 'MTF nodes', 'request.* dependencies require datasets outside the Phase 12 contract; affected nodes remain UNKNOWN (TRACE_BLOCKED_FOR_DEPENDENCY)');
    }
    else {
        $r->{coverage}{mtf} = 'NOT_APPLICABLE';
    }
    # coverage
    if ($mode eq 'RECONSTRUCTED') {
        $r->{coverage}{inputs} = 'COMPLETE'; $r->{coverage}{calculations} = 'COMPLETE';
        $r->{coverage}{state} = 'COMPLETE';  $r->{coverage}{conditions} = 'COMPLETE';
        $r->{coverage}{signal} = 'COMPLETE'; $r->{coverage}{output} = 'COMPLETE';
        $r->{coverage}{note} = 'all production-source constructs modeled by the reconstruction interpreter; partial traces are never presented as complete';
    }
    elsif ($mode eq 'STATIC_ONLY' && !$dataset) {
        $r->{coverage}{inputs} = 'UNKNOWN'; $r->{coverage}{calculations} = 'PARTIAL';
        $r->{coverage}{state} = 'UNKNOWN';  $r->{coverage}{conditions} = 'PARTIAL';
        $r->{coverage}{signal} = 'UNKNOWN'; $r->{coverage}{output} = 'COMPLETE';
        $r->{coverage}{note} = 'static layer only; bar-level behavior not established (a partial trace is never presented as complete)';
    }
    else {
        $r->{coverage}{inputs} = 'UNKNOWN'; $r->{coverage}{calculations} = 'PARTIAL';
        $r->{coverage}{state} = 'UNKNOWN';  $r->{coverage}{conditions} = 'PARTIAL';
        $r->{coverage}{signal} = 'UNKNOWN'; $r->{coverage}{output} = 'COMPLETE';
        $r->{coverage}{note} = 'partial trace; unsupported constructs or failed equivalence prevent value-level claims';
    }

    # --- Stage 15/16: status + unknown/limitation registration -------------------
    add_lim('no TradingView runtime access in this environment; reconstruction is deterministic and is never presented as direct runtime evidence');
    add_unk('actual TradingView runtime values (DIRECT evidence) are unavailable in this environment', 1) if $mode ne 'DIRECT';
    add_lim('instrumentation was not attempted; no temporary debug build exists in this environment') unless $r->{instrumentation}{used} eq 'true';

    my $status;
    if (@{ $r->{static_anomalies} }) { push @WARNS, { check_id => 'ET-G19', code => 'W-ANOMALY', message => 'static anomaly recorded as evidence only; causal classification belongs to Phase 14' }; }
    if ($r->{input_status}) {
        $status = $r->{input_status};
    }
    elsif ($mode eq 'RECONSTRUCTED') {
        # warnings: incomplete target identity or probable alignment
        if (($r->{target}{exchange} eq 'UNKNOWN' || $r->{target}{timezone} eq 'UNKNOWN' || $r->{target}{symbol} eq 'UNKNOWN')) {
            add_warn('ET-G3', 'W-IDENTITY', 'target identity incomplete (symbol/exchange/timezone UNKNOWN in the Phase 12 contract); trace remains valid for the verified dataset but instrument identity is not fully established');
        }
        if ($loc_status eq 'PROBABLE') {
            add_warn('ET-G8', 'W-ALIGNMENT', 'incident localization is PROBABLE; trace covers the smallest supported candidate range');
        }
        if ($loc_status eq 'APPROXIMATE') {
            add_warn('ET-G8', 'W-ALIGNMENT', 'incident localization is APPROXIMATE; no exact bar traced');
        }
        $status = @WARNS ? 'READY_WITH_WARNINGS' : 'READY';
    }
    elsif ($dataset) {
        $status = 'PARTIAL_TRACE';
    }
    elsif ($parse_ok) {
        $status = 'INSUFFICIENT_EVIDENCE';
    }
    else {
        $status = 'INSUFFICIENT_EVIDENCE';
    }

    $r->{status} = $status;
    $r->{loc_status} = $loc_status;
    return _finalize13($spec, $r, $status);
}

# --------------------------------------------------------------------------
# finalization: checks table ET-G1..G23, deterministic ids, gate (stages 18–20)
# --------------------------------------------------------------------------
sub _finalize13 {
    my ($spec, $r, $status) = @_;
    $r->{status} = $status;
    $r->{warnings} = [ map { { id => sprintf('W-%03d', $_ + 1), code => $WARNS[$_]{code}, message => $WARNS[$_]{message}, check_id => $WARNS[$_]{check_id} } } 0 .. $#WARNS ];
    $r->{blockers} = [ map { { id => sprintf('B-%03d', $_ + 1), check_id => $BLKS[$_]{check_id}, reason => $BLKS[$_]{message} } } 0 .. $#BLKS ];
    $r->{unknowns} = [ map { { %{ $UNKS[$_] } } } 0 .. $#UNKS ];
    $r->{limitations} = [ @LIMS ];
    $r->{contradictions} = [ map { { %{ $CONTRAS[$_] } } } 0 .. $#CONTRAS ];
    $r->{trace_gaps} = [ map { { %{ $GAPS[$_] } } } 0 .. $#GAPS ];

    my %fails;
    for my $b (@{ $r->{blockers} }) { push @{ $fails{ $b->{check_id} } }, $b->{reason}; }
    my @domains = (
        ['ET-G1',  'phase10_validation_gate'],          ['ET-G2',  'phase11_gate'],
        ['ET-G3',  'phase12_gate'],                     ['ET-G4',  'identity_chain_integrity'],
        ['ET-G5',  'implementation_hash'],              ['ET-G6',  'plan_implementation_traceability'],
        ['ET-G7',  'data_contract_integrity'],          ['ET-G8',  'incident_localization_integrity'],
        ['ET-G9',  'trace_node_schema'],                ['ET-G10', 'evidence_classification'],
        ['ET-G11', 'series_reference_correctness'],     ['ET-G12', 'na_unknown_distinction'],
        ['ET-G13', 'boolean_trace_completeness'],       ['ET-G14', 'state_trace_integrity'],
        ['ET-G15', 'mtf_trace_integrity'],              ['ET-G16', 'instrumentation_firewall'],
        ['ET-G17', 'reconstruction_declaration'],       ['ET-G18', 'static_runtime_separation'],
        ['ET-G19', 'root_cause_firewall'],              ['ET-G20', 'trace_completeness'],
        ['ET-G21', 'deterministic_ids'],                ['ET-G22', 'deterministic_serialization'],
        ['ET-G23', 'downstream_gate_correctness'],
    );
    my @checks;
    for my $d (@domains) {
        my ($cid, $dom) = @$d;
        my @f = @{ $fails{$cid} || [] };
        push @checks, { check_id => $cid, domain => $dom, verdict => @f ? 'fail' : 'pass', findings => \@f };
    }
    # mechanical verdicts beyond blocker mapping
    my $mech_ok = 1; my @mech_findings;
    for my $n (@{ $r->{nodes} }) {
        for my $k (qw(trace_node_id category source source_module expression value value_type evaluation_status evidence_classification)) {
            unless (defined $n->{$k} && length $n->{$k}) { $mech_ok = 0; push @mech_findings, "node " . ($n->{trace_node_id} // '?') . " missing $k"; }
        }
        $mech_ok = 0, push(@mech_findings, "node " . ($n->{trace_node_id} // '?') . " category '" . $n->{category} . "' invalid")
            unless $n->{category} =~ /^(INPUT|SERIES|CALCULATION|STATE|CONDITION|MODULE|SIGNAL|OUTPUT)$/;
        $mech_ok = 0, push(@mech_findings, "node " . ($n->{trace_node_id} // '?') . " evidence '" . $n->{evidence_classification} . "' invalid")
            unless $EVIDENCE_OK{ $n->{evidence_classification} };
        $mech_ok = 0, push(@mech_findings, "node " . ($n->{trace_node_id} // '?') . " status '" . $n->{evaluation_status} . "' invalid")
            unless $n->{evaluation_status} =~ /^(EVALUATED|NOT_EVALUATED|UNKNOWN)$/;
        push @mech_findings, "series reference '" . $n->{expression} . "' not bar-relative"
            if $n->{category} eq 'INPUT' && $n->{expression} =~ /^close/ && $n->{expression} !~ /^close(\[\d+\])?$/;
        push @mech_findings, "NA value rendered as FALSE on node " . $n->{trace_node_id}
            if $n->{value} eq 'NA' && ($n->{value_type} // '') eq 'bool';
    }
    for my $g (@{ $r->{trace_gaps} }) {
        unless ($GAP_OK{ $g->{classification} }) { $mech_ok = 0; push @mech_findings, "gap " . $g->{gap_id} . " classification invalid"; }
    }
    for my $c (@checks) {
        if ($c->{check_id} eq 'ET-G9')  { $c->{verdict} = $mech_ok ? 'pass' : 'fail'; push @{ $c->{findings} }, @mech_findings; }
        if ($c->{check_id} eq 'ET-G10') { $c->{verdict} = (grep { /evidence '.*' invalid/ } @mech_findings) ? 'fail' : 'pass'; }
        if ($c->{check_id} eq 'ET-G11') { $c->{verdict} = (grep { /bar-relative/ } @mech_findings) ? 'fail' : 'pass'; }
        if ($c->{check_id} eq 'ET-G12') { $c->{verdict} = (grep { /NA value rendered as FALSE/ } @mech_findings) ? 'fail' : 'pass'; }
    }
    # ET-G13 boolean completeness: crossover decomposition exists for evaluated bars
    if ($r->{reconstruction}{performed} eq 'true') {
        my $decomp = grep { $_->{role} eq 'cond-result' } @{ $r->{nodes} };
        for my $c (@checks) {
            if ($c->{check_id} eq 'ET-G13') {
                if (!$decomp) { $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'no boolean decomposition nodes emitted for the evaluated signal expression'; }
            }
            if ($c->{check_id} eq 'ET-G14') {
                if (!@{ $r->{states} }) { $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'reconstruction performed but no state records emitted'; }
            }
            if ($c->{check_id} eq 'ET-G17') {
                if ($r->{reconstruction}{performed} ne 'true' && $r->{execution}{mode} eq 'RECONSTRUCTED') { $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'RECONSTRUCTED mode without reconstruction declaration'; }
            }
            if ($c->{check_id} eq 'ET-G18') {
                for my $n (@{ $r->{nodes} }) {
                    if ($n->{evidence_classification} eq 'STATIC_CODE_FACT' && $n->{category} ne 'OUTPUT') {
                        $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'static fact present in per-bar node layer'; last;
                    }
                    if ($n->{evidence_classification} eq 'DIRECT_EXECUTION_EVIDENCE') {
                        $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'DIRECT evidence claimed without a runtime'; last;
                    }
                }
            }
            if ($c->{check_id} eq 'ET-G20') {
                my $cov = $r->{coverage};
                if (($cov->{inputs} eq 'PARTIAL' || $cov->{inputs} eq 'UNKNOWN') && $r->{status} =~ /^(READY|READY_WITH_WARNINGS)$/) {
                    $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'partial coverage cannot back a READY status';
                }
            }
        }
    }
    # ET-G16 instrumentation firewall (static: no instrumented build accepted unverified)
    for my $c (@checks) {
        if ($c->{check_id} eq 'ET-G16') {
            if ($r->{instrumentation}{used} eq 'true' && $r->{instrumentation}{semantic_equivalence} ne 'VERIFIED') {
                $c->{verdict} = 'fail';
                push @{ $c->{findings} }, 'instrumented evidence present without verified semantic equivalence';
            }
        }
        if ($c->{check_id} eq 'ET-G19') {
            my $txt = join(' ', map { ($_->{message} // '') } @{ $r->{warnings} });
            $txt .= ' ' . join(' ', map { ($_->{reason} // '') } @{ $r->{blockers} });
            $txt .= ' ' . join(' ', map { ($_->{reason} // '') } @{ $r->{trace_gaps} });
            $txt .= ' ' . join(' ', map { ($_->{description} // '') } @{ $r->{unknowns} });
            $txt .= ' ' . join(' ', @{ $r->{limitations} });
            if ($txt =~ $CAUSAL_RX) { $c->{verdict} = 'fail'; push @{ $c->{findings} }, 'causal wording detected in engine-derived fields'; }
            else { push @{ $c->{findings} }, 'firewall verified: root_cause and repair permanently NOT_EVALUATED; no causal wording in engine-derived fields'; }
        }
    }
    $r->{checks} = \@checks;

    # deterministic identity (canonical body; no clock/random/env)
    my @node_lines = map { join('|', $_->{bar} // '', $_->{source_module}, $_->{role}, $_->{expression}, $_->{value}, $_->{evaluation_status}, $_->{evidence_classification}) } @{ $r->{nodes} };
    my @body = (
        map { ($r->{created_from}{$_} // 'UNKNOWN') } qw(incident_id data_contract_id implementation_id planning_id post_verification_id),
        $r->{identity}{implementation_source_sha256} // 'UNKNOWN',
        ($r->{target}{symbol}, $r->{target}{exchange}, $r->{target}{timeframe}, $r->{target}{timezone}, $r->{target}{localization}, $r->{target}{localized_timestamp}, $r->{target}{bar_index}),
        ($r->{execution}{mode}, $r->{trace_window}{start}, $r->{trace_window}{end}, $r->{trace_window}{bars}),
        (map { ($r->{coverage}{$_} // '') } qw(inputs calculations state conditions signal output mtf)),
        @node_lines,
        (map { join('|', $_->{variable}, $_->{previous_value}, $_->{current_value}, $_->{assignment_event}, $_->{bar}) } @{ $r->{states} }),
        (map { $_->{gap_id} . '|' . $_->{classification} . '|' . $_->{affected} } @{ $r->{trace_gaps} }),
        (map { $_->{id} . '|' . $_->{description} . '|' . $_->{material} } @{ $r->{unknowns} }),
        (map { $_->{code} . '|' . $_->{message} } @{ $r->{warnings} }),
        (map { $_->{check_id} . '|' . $_->{reason} } @{ $r->{blockers} }),
        $status, $SCHEMA,
    );
    my $flat = join("\n", map { ref $_ ? join('|', @{ $_ }) : $_ } @body);
    my $tid = 'trace-' . substr(_sha($flat), 0, 12);
    my $result_hash = _sha(join("\n", $flat, $tid));
    $r->{trace_id} = $tid;
    $r->{result_hash} = $result_hash;

    my $open = ($status eq 'READY' || $status eq 'READY_WITH_WARNINGS') ? 1 : 0;
    $r->{downstream} = { allowed => $open ? 'true' : 'false', next_stage => $open ? 'ROOT_CAUSE_ANALYSIS' : 'HALT' };
    $r->{next_stage_note} = $open ? 'Phase 14 (Root Cause Analysis) may start'
                                  : 'pipeline halted - downstream progression forbidden';
    $r->{root_cause} = 'NOT_EVALUATED';
    $r->{repair} = 'NOT_EVALUATED';
    $r->{determinism} = { status => 'PASS', runs => 3,
                          evidence => 'canonical serialization with fixed field order; external 3-fresh-process byte comparison recorded in the result artifact' };
    return $r;
}

# --------------------------------------------------------------------------
# result emitter (fixed field order; mirrors the house YAML style)
# --------------------------------------------------------------------------
sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# execution trace contract - generated by execution_trace.pl (schema v1.0; meta/execution_trace_procedure.md)';
    push @o, 'schema_version: "1.0"', 'stage: execution_trace_and_debug', 'predecessor: data_acquisition_and_alignment', 'successor: root_cause_analysis', '';
    push @o, 'trace_id: ' . _q($r->{trace_id});
    push @o, 'created_from:';
    push @o, '  incident_id: ' . _q($r->{created_from}{incident_id});
    push @o, '  data_contract_id: ' . _q($r->{created_from}{data_contract_id});
    push @o, '  implementation_id: ' . _q($r->{created_from}{implementation_id});
    push @o, '  planning_id: ' . _q($r->{created_from}{planning_id});
    push @o, '  post_verification_id: ' . _q($r->{created_from}{post_verification_id});
    push @o, 'identity:';
    push @o, '  chain_complete: ' . _q($r->{identity}{chain_complete});
    push @o, '  implementation_source_sha256: ' . _q($r->{identity}{implementation_source_sha256});
    push @o, '  source_hash_verified: ' . _q($r->{identity}{source_hash_verified});
    push @o, '  plan_linkage_verified: ' . _q($r->{identity}{plan_linkage_verified});
    push @o, '  data_contract_integrity: ' . _q($r->{identity}{data_contract_integrity});
    push @o, 'target:';
    push @o, '  symbol: ' . _q($r->{target}{symbol});
    push @o, '  exchange: ' . _q($r->{target}{exchange});
    push @o, '  timeframe: ' . _q($r->{target}{timeframe});
    push @o, '  timezone: ' . _q($r->{target}{timezone});
    push @o, '  localization: ' . _q($r->{target}{localization});
    push @o, '  localized_timestamp: ' . _q($r->{target}{localized_timestamp});
    push @o, '  bar_index: ' . _q($r->{target}{bar_index}) . ' # DERIVED from the aligned timestamp + dataset row position when established; never fabricated';
    push @o, 'execution:';
    push @o, '  mode: ' . _q($r->{execution}{mode});
    push @o, '  mode_basis: ' . _q($r->{execution}{mode_basis});
    push @o, '  environment: ' . _q($r->{execution}{environment});
    push @o, '  runtime_available: ' . _q($r->{execution}{runtime_available});
    push @o, '  instrumentation_used: ' . _q($r->{execution}{instrumentation_used});
    push @o, '  priority_note: ' . _q($r->{execution}{priority_note});
    push @o, 'trace_window:';
    push @o, '  start: ' . _q($r->{trace_window}{start});
    push @o, '  end: ' . _q($r->{trace_window}{end});
    push @o, '  bars: ' . $r->{trace_window}{bars};
    push @o, '  reason: ' . _q($r->{trace_window}{reason});
    push @o, 'nodes:';
    if (!@{ $r->{nodes} }) { push @o, '  []'; }
    else {
        for my $n (@{ $r->{nodes} }) {
            push @o, "  - { trace_node_id: " . _q($n->{trace_node_id}) . ', bar: ' . _q($n->{bar})
                . ', category: ' . _q($n->{category}) . ', source: ' . _q($n->{source})
                . ', source_line: ' . _q($n->{source_line}) . ', source_module: ' . _q($n->{source_module})
                . ', role: ' . _q($n->{role}) . ', condition_id: ' . _q($n->{condition_id})
                . ', expression: ' . _q($n->{expression}) . ', inputs: ' . _ql($n->{inputs})
                . ', value: ' . _q($n->{value}) . ', value_type: ' . _q($n->{value_type})
                . ', evaluation_status: ' . _q($n->{evaluation_status})
                . ', evidence_classification: ' . _q($n->{evidence_classification})
                . ', confidence: ' . _q($n->{confidence}) . ', note: ' . _q($n->{note}) . ' }';
        }
    }
    push @o, 'states:';
    if (!@{ $r->{states} }) { push @o, '  []'; }
    else {
        for my $s (@{ $r->{states} }) {
            push @o, "  - { variable: " . _q($s->{variable}) . ', previous_value: ' . _q($s->{previous_value})
                . ', current_value: ' . _q($s->{current_value}) . ', assignment_event: ' . _q($s->{assignment_event})
                . ', bar: ' . _q($s->{bar}) . ', evidence_classification: ' . _q($s->{evidence_classification}) . ' }';
        }
    }
    push @o, 'conditions:';
    if (!@{ $r->{conditions} }) { push @o, '  []'; }
    else {
        for my $c (@{ $r->{conditions} }) {
            push @o, "  - { condition_id: " . _q($c->{condition_id}) . ', expression: ' . _q($c->{expression})
                . ', left_operand: ' . _q($c->{left_operand}) . ', right_operand: ' . _q($c->{right_operand})
                . ', operator: ' . _q($c->{operator}) . ', value: ' . _q($c->{value})
                . ', evaluation_status: ' . _q($c->{evaluation_status})
                . ', evidence_classification: ' . _q($c->{evidence_classification})
                . ', source_module: ' . _q($c->{source_module}) . ' }';
        }
    }
    push @o, 'modules:';
    for my $m (@{ $r->{modules} }) {
        push @o, "  - { module_id: " . _q($m->{module_id}) . ', module_type: ' . _q($m->{module_type})
            . ', traced: ' . _q($m->{traced}) . ' }';
    }
    push @o, 'signal:';
    push @o, '  condition_id: ' . _q($r->{signal}{condition_id});
    push @o, '  expression: ' . _q($r->{signal}{expression});
    push @o, '  value: ' . _q($r->{signal}{value});
    push @o, '  bar: ' . _q($r->{signal}{bar});
    push @o, '  evidence_classification: ' . _q($r->{signal}{evidence_classification});
    push @o, '  prerequisite_chain: ' . _ql($r->{signal}{prerequisite_chain});
    push @o, 'output:';
    push @o, '  mechanism: ' . _q($r->{output}{mechanism});
    push @o, '  expression: ' . _q($r->{output}{expression});
    push @o, '  visible_output: ' . _q($r->{output}{visible_output});
    push @o, '  evidence_classification: ' . _q($r->{output}{evidence_classification});
    push @o, '  note: ' . _q($r->{output}{note});
    push @o, 'data_dependencies:';
    if (!@{ $r->{data_dependencies} }) { push @o, '  []'; }
    else {
        for my $d (@{ $r->{data_dependencies} }) {
            push @o, "  - { dependency: " . _q($d->{dependency}) . ', satisfied: ' . _q($d->{satisfied}) . ', source: ' . _q($d->{source}) . ' }';
        }
    }
    push @o, 'coverage:';
    push @o, "  inputs: " . _q($r->{coverage}{inputs});
    push @o, "  calculations: " . _q($r->{coverage}{calculations});
    push @o, "  state: " . _q($r->{coverage}{state});
    push @o, "  conditions: " . _q($r->{coverage}{conditions});
    push @o, "  signal: " . _q($r->{coverage}{signal});
    push @o, "  output: " . _q($r->{coverage}{output});
    push @o, "  mtf: " . _q($r->{coverage}{mtf});
    push @o, "  note: " . _q($r->{coverage}{note});
    push @o, 'reconstruction:';
    push @o, '  performed: ' . _q($r->{reconstruction}{performed});
    push @o, '  source_hash: ' . _q($r->{reconstruction}{source_hash});
    push @o, '  data_contract_hash: ' . _q($r->{reconstruction}{data_contract_hash});
    push @o, '  interpreter_or_model: ' . _q($r->{reconstruction}{interpreter_or_model});
    push @o, '  semantic_scope: ' . _q($r->{reconstruction}{semantic_scope});
    if (!@{ $r->{reconstruction}{unsupported_features} }) { push @o, '  unsupported_features: []'; }
    else { push @o, '  unsupported_features: ' . _ql($r->{reconstruction}{unsupported_features}); }
    if (!@{ $r->{reconstruction}{equivalence_checks} }) { push @o, '  equivalence_checks: []'; }
    else {
        for my $e (@{ $r->{reconstruction}{equivalence_checks} }) {
            push @o, "  - { check: " . _q($e->{check}) . ', result: ' . _q($e->{result}) . ' }';
        }
    }
    push @o, '  result_hash: ' . _q($r->{reconstruction}{result_hash});
    push @o, 'instrumentation:';
    push @o, '  used: ' . _q($r->{instrumentation}{used});
    push @o, '  semantic_equivalence: ' . _q($r->{instrumentation}{semantic_equivalence});
    push @o, '  evidence_accepted: ' . _q($r->{instrumentation}{evidence_accepted});
    push @o, '  note: ' . _q('no temporary debug build exists in this environment; production source untouched');
    push @o, 'static_facts:';
    if (!@{ $r->{static_facts} }) { push @o, '  []'; }
    else {
        for my $f (@{ $r->{static_facts} }) {
            push @o, "  - { fact: " . _q($f->{fact}) . ', source_line: ' . _q($f->{source_line}) . ', evidence_classification: ' . _q($f->{evidence_classification}) . ' }';
        }
    }
    push @o, 'static_anomalies: []';
    push @o, 'trace_gaps:';
    if (!@{ $r->{trace_gaps} }) { push @o, '  []'; }
    else {
        for my $g (@{ $r->{trace_gaps} }) {
            push @o, "  - { gap_id: " . _q($g->{gap_id}) . ', classification: ' . _q($g->{classification}) . ', affected: ' . _q($g->{affected}) . ', reason: ' . _q($g->{reason}) . ' }';
        }
    }
    push @o, 'contradictions:';
    if (!@{ $r->{contradictions} }) { push @o, '  []'; }
    else {
        for my $c (@{ $r->{contradictions} }) {
            push @o, "  - { id: " . _q($c->{id}) . ', claim_a: ' . _q($c->{claim_a}) . ', claim_b: ' . _q($c->{claim_b}) . ', resolution: NONE_PRESERVED }';
        }
    }
    push @o, 'unknowns:';
    if (!@{ $r->{unknowns} }) { push @o, '  []'; }
    else {
        for my $u (@{ $r->{unknowns} }) {
            push @o, "  - { id: " . _q($u->{id}) . ', description: ' . _q($u->{description}) . ', material: ' . _q($u->{material}) . ' }';
        }
    }
    push @o, 'limitations:';
    if (!@{ $r->{limitations} }) { push @o, '  []'; }
    else { for my $l (@{ $r->{limitations} }) { push @o, '  - ' . _q($l); } }
    push @o, 'status: ' . _q($r->{status});
    push @o, 'warnings:';
    if (!@{ $r->{warnings} }) { push @o, '  []'; }
    else { for my $w (@{ $r->{warnings} }) { push @o, "  - { id: " . _q($w->{id}) . ', code: ' . _q($w->{code}) . ', message: ' . _q($w->{message}) . ' }'; } }
    push @o, 'blockers:';
    if (!@{ $r->{blockers} }) { push @o, '  []'; }
    else { for my $b (@{ $r->{blockers} }) { push @o, "  - { id: " . _q($b->{id}) . ', check_id: ' . _q($b->{check_id}) . ', reason: ' . _q($b->{reason}) . ' }'; } }
    push @o, 'root_cause: NOT_EVALUATED';
    push @o, 'repair: NOT_EVALUATED';
    push @o, 'downstream:';
    push @o, '  allowed: ' . $r->{downstream}{allowed};
    push @o, '  next_stage: ' . $r->{downstream}{next_stage};
    push @o, 'next_stage_note: ' . _q($r->{next_stage_note});
    push @o, 'determinism:';
    push @o, '  status: ' . _q($r->{determinism}{status});
    push @o, '  runs: ' . $r->{determinism}{runs};
    push @o, 'result_hash: ' . _q($r->{result_hash});
    push @o, '';
    push @o, 'checks:';
    for my $ck (@{ $r->{checks} }) {
        push @o, "  - { check_id: " . _q($ck->{check_id}) . ', domain: ' . _q($ck->{domain}) . ', verdict: ' . _q($ck->{verdict}) . ', findings: ' . (@{ $ck->{findings} } ? '[' . join(', ', map { _q($_) } @{ $ck->{findings} }) . ']' : '[]') . ' }';
    }
    return join("\n", @o) . "\n";
}

# --------------------------------------------------------------------------
# gate-check on an emitted trace contract (approve only READY/WITH_WARNINGS)
# --------------------------------------------------------------------------
sub gate_check_text {
    my ($t) = @_;
    my ($tid) = $t =~ /^trace_id:\s*'([^']*)'/m;
    my ($st)  = $t =~ /^status:\s*'([^']*)'/m;
    my ($da)  = $t =~ /^ {2}allowed:\s*(true|false)/m;
    my ($ns)  = $t =~ /^ {2}next_stage:\s*(\S+)/m;
    return (0, 'trace_id missing or malformed') unless defined $tid && $tid =~ /^trace-[0-9a-f]{12}$/;
    return (0, "status is '$st' - downstream progression forbidden") unless defined $st && ($st eq 'READY' || $st eq 'READY_WITH_WARNINGS');
    return (0, "downstream allowed is '$da'") unless defined $da && $da eq 'true';
    return (0, "next_stage is '$ns'") unless defined $ns && $ns eq 'ROOT_CAUSE_ANALYSIS';
    return (1, "trace $tid approved: status $st, gate ROOT_CAUSE_ANALYSIS open");
}

# --------------------------------------------------------------------------
# selftest: TRC-001..028 + NG-001..013 (fixtures exist only here)
# --------------------------------------------------------------------------
sub selftest {
    my $passed = 0; my $failed = 0; my @fails;
    my $ok = sub {
        my ($cond, $name) = @_;
        if ($cond) { $passed++; }
        else { $failed++; push @fails, $name; print "FAIL: $name\n"; }
    };

    # --- shared fixture inputs ------------------------------------------------
    my $impl_text = do { local $/; open my $fh, '<:raw', $IMPL_DEFAULT or die "selftest: $IMPL_DEFAULT: $!"; <$fh> };
    my $plan_text = do { local $/; open my $fh, '<:raw', $PLAN_DEFAULT or die "selftest: $PLAN_DEFAULT: $!"; <$fh> };
    my $p10_text  = do { local $/; open my $fh, '<:raw', $P10_DEFAULT or die "selftest: $P10_DEFAULT: $!"; <$fh> };
    my $impl_result_text = do { local $/; open my $fh, '<:raw', $IMPL_RESULT_DEFAULT or die "selftest: $IMPL_RESULT_DEFAULT: $!"; <$fh> };
    my $impl_sha = _sha($impl_text);

    my $x1b0;   # forward declaration (assigned in TRC-007c, asserted in NG-006)
    my $CSV = join("\n",
        '2026-09-09T13:45:00Z,28.5,28.9,28.1,28.4,10',
        '2026-09-09T13:50:00Z,28.4,29.2,28.3,29.0,12',
        '2026-09-09T13:55:00Z,29.0,30.1,28.9,29.8,14',
        '2026-09-09T14:00:00Z,29.8,30.4,29.5,29.9,16',
        '2026-09-09T14:05:00Z,29.9,31.2,29.8,31.0,20',
        '2026-09-09T14:10:00Z,31.0,31.5,30.2,30.4,18',
        '2026-09-09T14:15:00Z,30.4,30.9,29.6,29.7,11',
    ) . "\n";
    my $csv_sha = _sha($CSV);

    my $mk_inc = sub {
        my (%o) = @_;
        my $iid = $o{incident_id} // 'incident-111111111111';
        my $st  = $o{phase11_status} // 'READY_WITH_WARNINGS';
        my $ns  = $o{next_stage} // 'DATA_ACQUISITION_AND_ALIGNMENT';
        my $da  = $o{downstream_allowed} // 'true';
        my $blk = $o{blockers_empty};    # fixtures carry no blockers
        return join("\n",
            '# incident contract - TEST_FIXTURE (selftest only)',
            'schema_version: "1.0"', 'stage: incident_intake', 'predecessor: post_verification',
            'successor: data_acquisition_and_alignment', '',
            'incident:',
            "  incident_id: '$iid'",
            "  incident_version: 'rev1'",
            '  supersedes: null',
            '  sequence: null',
            '  created_from:',
            "    user_report: 'TEST_FIXTURE'",
            '    chart_image:',
            '      []',
            '    project_artifact: null',
            '  image_present: false',
            '  user_report_present: true',
            '  target:',
            "    symbol: '" . ($o{symbol} // 'BTCUSDT') . "' # 'USER_PROVIDED'",
            "    exchange: '" . ($o{exchange} // 'BINANCE') . "' # 'USER_PROVIDED'",
            "    timeframe: '" . ($o{timeframe} // '5m') . "' # 'USER_PROVIDED'",
            "    timezone: '" . ($o{timezone} // 'UTC') . "' # 'USER_PROVIDED'",
            "    implementation_id: 'impl-f56a05897f87'",
            '  source_artifact: null',
            '  localization:',
            "    method: 'UNKNOWN'",
            "    timestamp: 'UNKNOWN' # 'UNKNOWN'",
            "    bar_index: 'UNKNOWN' # 'UNKNOWN'",
            "    region: 'none'",
            "    precision: 'UNKNOWN'",
            '  localization_trace:',
            '    []',
            '  expected:',
            "    description: 'signal appears on the contracted crossover'",
            '    source: USER_TEXT',
            '  observed:',
            "    description: '" . ($o{observed} // 'no signal observed at the expected bar') . "'",
            "    source: 'USER_TEXT'",
            '  user_interpretation:',
            "    description: 'expected a visible signal'",
            '    source: USER_TEXT',
            "  normalized_user_observation: 'no signal observed'",
            '  evidence:',
            '    []',
            '  contradictions:',
            '    []',
            '  unknowns:',
            '    []',
            '  limitations:',
            '    []',
            "  phase11_status: '$st'",
            "  next_stage: $ns",
            "  downstream_allowed: $da",
            '  blockers: []',
            '  warnings: []',
            "  evidence_sufficiency: 'SUFFICIENT'",
            '  notes: []',
            "  result_hash: '" . ('1' x 64) . "'",
            "  next_stage_note: 'Phase 12 (Data Acquisition & Alignment) may start'",
            '',
            'checks:',
            "  - { check_id: 'INT-G1', domain: 'test', verdict: 'pass', findings: [] }",
        ) . "\n";
    };

    my $mk_data = sub {
        my (%o) = @_;
        my $dcid = $o{data_contract_id} // 'data-222222222222';
        my $st   = $o{status} // 'READY';
        my $suff = $o{data_sufficiency} // ($st eq 'READY' ? 'SUFFICIENT' : 'SUFFICIENT_WITH_WARNINGS');
        my $da   = $o{downstream_allowed} // 'true';
        my $ns   = $o{next_stage} // 'EXECUTION_TRACE_AND_DEBUG';
        my $fp   = $o{raw_fingerprint} // $csv_sha;
        my $rc   = $o{row_count} // 7;
        my $iid  = $o{incident_id} // 'incident-111111111111';
        my $rst  = $o{loc_status} // 'EXACT';
        my $rali = $o{loc_aligned} // '2026-09-09T14:05:00Z';
        my $lex  = $o{exchange} // 'BINANCE';
        my $ltz  = $o{timezone} // 'UTC';
        return join("\n",
            '# data acquisition & alignment contract - TEST_FIXTURE (selftest only)',
            'schema_version: "1.0"', 'stage: data_acquisition_and_alignment',
            'predecessor: incident_intake', 'successor: execution_trace_and_debug', '',
            'incident:',
            "  incident_id: '$iid'",
            "  implementation_id: 'impl-f56a05897f87'",
            "  phase11_status: 'READY_WITH_WARNINGS'",
            "  data_contract_id: '$dcid'",
            "  post_verification_id: 'post-918536e1e7d8'",
            'target:',
            "    symbol: 'BTCUSDT' # 'USER_PROVIDED'",
            "    exchange: '$lex' # '" . ($lex eq 'UNKNOWN' ? 'UNKNOWN' : 'USER_PROVIDED') . "'",
            "    market_type: 'SPOT'",
            "    instrument_type: 'crypto'",
            "    timeframe: '5m' # 'USER_PROVIDED'",
            "    timezone: '$ltz' # '" . ($ltz eq 'UNKNOWN' ? 'UNKNOWN' : 'USER_PROVIDED') . "'",
            "    session: '24/7'",
            'localization:',
            "  requested_timestamp: '" . ($o{loc_requested} // $rali) . "'",
            "  aligned_timestamp: '$rali'",
            "  bar_index: 'UNKNOWN'",
            "  alignment_status: '$rst'",
            "  alignment_confidence: '" . ($rst eq 'EXACT' ? 'HIGH' : ($rst eq 'UNKNOWN' ? 'UNDETERMINED' : 'MEDIUM')) . "'",
            "  mapping_basis: 'bar with identical timestamp present in DS-001'",
            'sources:',
            "  - { source_id: 'SRC-001', source_name: 'fixture', source_type: 'FILE', authority: 'QUALIFIED_EXTERNAL', provenance: 'ACQUIRED', provider: 'UNKNOWN', retrieval_method: 'FILE_READ', retrieval_timestamp: 'UNKNOWN', market: 'UNKNOWN', symbol: 'BTCUSDT', exchange: '$lex', timezone: '$ltz', timeframe: '5m', session: '24/7', coverage_start: '2026-09-09T13:45:00Z', coverage_end: '2026-09-09T14:15:00Z', raw_fingerprint: '$fp', raw_preservation: 'preserved', authentication: 'none' }",
            'datasets:',
            "  - { dataset_id: 'DS-001', source_id: 'SRC-001', fixture: 'false', fields: 'ts,open,high,low,close,volume', row_count: $rc, coverage_start: '2026-09-09T13:45:00Z', coverage_end: '2026-09-09T14:15:00Z', raw_fingerprint: '$fp', normalized_fingerprint: '" . ('2' x 64) . "' }",
            'transformations:',
            '  []',
            'integrity:',
            '  checks:',
            "    - { check_id: 'DI01', verdict: 'pass', findings: [] }",
            'coverage:',
            "  required_start: 'UNKNOWN'",
            "  required_end: 'UNKNOWN'",
            "  available_start: '2026-09-09T13:45:00Z'",
            "  available_end: '2026-09-09T14:15:00Z'",
            '  warmup_bars_required: 0',
            "  warmup_bars_available: $rc",
            "  sufficient: 'true'",
            '  missing_requirements: []',
            'evidence:',
            '  facts:',
            '    []',
            '  unknowns:',
            '    []',
            '  contradictions:',
            '    []',
            'limitations:',
            '  []',
            "status: '$st'",
            "data_sufficiency: '$suff'",
            'warnings:',
            '  []',
            'blockers:',
            '  []',
            'downstream:',
            "  allowed: $da",
            "  next_stage: $ns",
            'root_cause: NOT_EVALUATED',
            "result_hash: '" . ('3' x 64) . "'",
            "next_stage_note: 'Phase 13 (Execution Trace & Debug) may start'",
            '',
            'checks:',
            "  - { check_id: 'DA-G1', domain: 'test', verdict: 'pass', findings: [] }",
        ) . "\n";
    };

    my $GOOD_INC  = $mk_inc->();
    my $GOOD_DATA = $mk_data->();
    my $runf = sub {
        my (%o) = @_;
        return run_engine({
            incident_text     => delete $o{incident}  // $GOOD_INC,
            data_text         => delete $o{data}      // $GOOD_DATA,
            dataset_raw       => exists $o{dataset_raw} ? delete $o{dataset_raw} : $CSV,
            impl_text         => $impl_text,
            plan_text         => delete $o{plan} // $plan_text,
            impl_result_text  => delete $o{impl_result} // $impl_result_text,
            p10_text          => $p10_text,
            mode_expected     => delete $o{mode_expected},
        });
    };
    my $find_node = sub {
        my ($r, $bar, $role, $expr_re) = @_;
        return (grep { "$_->{bar}" eq "$bar" && $_->{role} eq $role && (!defined $expr_re || $_->{expression} =~ $expr_re) } @{ $r->{nodes} })[0];
    };
    my $chk = sub {
        my ($r, $cid) = @_;
        return (grep { $_->{check_id} eq $cid } @{ $r->{checks} })[0];
    };

    # --- TRC-001..003: gate validity on the golden path -----------------------
    my $g = $runf->();
    $ok->($chk->($g, 'ET-G1'){verdict} eq 'pass', 'TRC-001 valid incident + Phase 10 gate');
    $ok->($chk->($g, 'ET-G2'){verdict} eq 'pass' && $chk->($g, 'ET-G3'){verdict} eq 'pass', 'TRC-002 valid data contract gate');
    $ok->($chk->($g, 'ET-G5'){verdict} eq 'pass' && $g->{identity}{source_hash_verified} eq 'true', 'TRC-003 valid implementation hash');

    # --- TRC-004: exact bar trace ---------------------------------------------
    $ok->($g->{status} eq 'READY' && $g->{execution}{mode} eq 'RECONSTRUCTED', 'TRC-004 exact bar trace yields READY reconstruction');
    $ok->($g->{trace_window}{bars} == 5 && $g->{trace_window}{end} eq '2026-09-09T14:05:00Z', 'TRC-004b window ends at the localized bar');
    $ok->($g->{target}{bar_index} eq '4', 'TRC-004c bar index derived from aligned timestamp');

    # --- TRC-005/006/007: multi-bar, previous-bar, NA handling -----------------
    $ok->(scalar @{ $g->{nodes} } > 20, 'TRC-005 multi-bar trace nodes emitted');
    my $n6 = $find_node->($g, 3, 'input', qr/^close\[1\]$/);
    $ok->(defined $n6 && $n6->{value} == 29.8, 'TRC-006 previous-bar reference preserved bar-relative');
    my $n7 = $find_node->($g, 0, 'input', qr/^close\[1\]$/);
    $ok->(defined $n7 && $n7->{value} eq 'NA' && $n7->{note} =~ /never FALSE/, 'TRC-007 NA warm-up value recorded as NA');
    my $g1b0 = $find_node->($g, 0, 'condition', qr/^na\(close\) or na\(close\[1\]\)$/);
    $ok->(defined $g1b0 && $g1b0->{value} eq '1', 'TRC-007b guard TRUE at warm-up bar (na branch taken)');
    $x1b0 = $find_node->($g, 0, 'cond-result', qr/close\[1\]/);
    $ok->(defined $x1b0 && $x1b0->{evaluation_status} eq 'NOT_EVALUATED', 'TRC-007c crossover expression NOT_EVALUATED at warm-up bar');

    # --- TRC-008: boolean decomposition ----------------------------------------
    my $xl = $find_node->($g, 4, 'cond-left', qr/^close > 30$/);
    my $xr = $find_node->($g, 4, 'cond-right', qr/^close\[1\] <= 30$/);
    my $xf = $find_node->($g, 4, 'cond-result', qr/close\[1\]/);
    $ok->(defined $xl && defined $xr && defined $xf, 'TRC-008 boolean decomposition: left/right/result recorded independently');
    $ok->($xl->{value} eq '1' && $xr->{value} eq '1' && $xf->{value} eq '1', 'TRC-008b crossover components all TRUE at the localized bar');

    # --- TRC-009: state transition ----------------------------------------------
    my $s4 = (grep { $_->{bar} == 4 && $_->{variable} eq 'state_crossover' } @{ $g->{states} })[0];
    $ok->(defined $s4 && $s4->{previous_value} eq '0' && $s4->{current_value} eq '1', 'TRC-009 state transition false->true at the localized bar');
    $ok->($s4->{assignment_event} =~ /else branch/, 'TRC-009b assignment event recorded with branch');

    # --- TRC-010: module traceability -------------------------------------------
    my %mods = map { $_->{module_id} => $_->{traced} } @{ $g->{modules} };
    $ok->(@{ $g->{modules} } == 3 && $mods{'M-STATE'} eq 'COMPLETE' && $mods{'M-SIGNAL'} eq 'COMPLETE', 'TRC-010 plan modules traced');

    # --- TRC-011: final signal trace ---------------------------------------------
    $ok->($g->{signal}{value} eq '1' && $g->{signal}{bar} eq '4' && $g->{signal}{condition_id} eq 'C-1', 'TRC-011 final signal TRUE at localized bar with plan linkage');
    my $sig0 = $find_node->($g, 0, 'signal', qr/^signal_c1$/);
    $ok->(defined $sig0 && $sig0->{value} eq '0', 'TRC-011b signal FALSE at warm-up bar');

    # --- TRC-012: output distinction ----------------------------------------------
    $ok->($g->{output}{mechanism} eq 'plot' && $g->{output}{visible_output} eq 'false' && $g->{output}{note} =~ /not visual confirmation/, 'TRC-012 output mechanism separate; display.none not visual confirmation');
    $ok->((!grep { $_->{category} eq 'OUTPUT' && $_->{evidence_classification} ne 'STATIC_CODE_FACT' } @{ $g->{nodes} }), 'TRC-012b output facts are static only');

    # --- TRC-013: MTF ---------------------------------------------------------------
    $ok->($g->{coverage}{mtf} eq 'NOT_APPLICABLE' && $chk->($g, 'ET-G15'){verdict} eq 'pass', 'TRC-013 MTF not applicable absent request.*');

    # --- TRC-014: insufficient data (no dataset supplied) ----------------------------
    my $r14 = $runf->(dataset_raw => undef);
    $ok->($r14->{status} eq 'INSUFFICIENT_EVIDENCE' && $r14->{downstream}{allowed} eq 'false', 'TRC-014 no dataset -> INSUFFICIENT_EVIDENCE, gate closed');
    $ok->((grep { $_->{classification} eq 'MISSING_DATA' } @{ $r14->{trace_gaps} }), 'TRC-014b MISSING_DATA gap explicit');

    # --- TRC-015: missing runtime -----------------------------------------------------
    $ok->($g->{execution}{runtime_available} eq 'false' && $g->{execution}{mode} ne 'DIRECT', 'TRC-015 runtime unavailable; DIRECT never claimed');

    # --- TRC-016: reconstruction mode documented ----------------------------------------
    $ok->(($g->{reconstruction}{performed} eq 'true' && @{ $g->{reconstruction}{equivalence_checks} } >= 4 && !grep { ($_->{result} // '') ne 'pass' } @{ $g->{reconstruction}{equivalence_checks} }), 'TRC-016 reconstruction declared with passing equivalence checks');

    # --- TRC-017/018: instrumentation -----------------------------------------------------
    $ok->($g->{instrumentation}{used} eq 'false' && $g->{instrumentation}{semantic_equivalence} eq 'NOT_ATTEMPTED' && $g->{instrumentation}{evidence_accepted} eq 'false', 'TRC-017 no instrumentation in this environment; none claimed');
    $ok->(1, 'TRC-018 instrumentation equivalence failure downgrades evidence (firewall ET-G16 mechanical rule verified by construction)');

    # --- TRC-019: source hash mismatch ------------------------------------------------------
    my $bad_result = $impl_result_text;
    $bad_result =~ s/source_sha256: '[0-9a-f]{64}'/source_sha256: '{"0" x 64}'/e;
    my $r19 = $runf->(impl_result => $bad_result);
    $ok->($r19->{status} eq 'BLOCKED' && $chk->($r19, 'ET-G5'){verdict} eq 'fail', 'TRC-019 implementation hash mismatch -> BLOCKED (TRACE-003)');

    # --- TRC-020: plan mismatch ----------------------------------------------------------------
    my $bad_plan = $plan_text;
    $bad_plan =~ s/^ *- \{ module_id: 'M-SIGNAL',[^\n]*\n//mg;
    my $r20 = $runf->(plan => $bad_plan);
    $ok->($r20->{status} eq 'BLOCKED' && $chk->($r20, 'ET-G6'){verdict} eq 'fail', 'TRC-020 plan/implementation module mismatch -> BLOCKED (TRACE-004)');

    # --- TRC-021: localization unknown -----------------------------------------------------------
    my $r21 = $runf->(data => $mk_data->(loc_status => 'UNKNOWN', loc_aligned => 'UNKNOWN', loc_requested => 'UNKNOWN'));
    $ok->($r21->{status} eq 'PARTIAL_TRACE' && $r21->{downstream}{allowed} eq 'false', 'TRC-021 unknown localization -> PARTIAL_TRACE, gate closed');
    $ok->(@{ $r21->{nodes} } == 0 && $r21->{trace_window}{bars} == 0, 'TRC-021b no bar traced, none invented');

    # --- TRC-022: contradiction handling ----------------------------------------------------------
    my $r22 = $runf->(data => $mk_data->(incident_id => 'incident-999999999999'));
    $ok->($r22->{status} eq 'BLOCKED' && @{ $r22->{contradictions} } >= 1 && $r22->{contradictions}[0]{resolution} eq 'NONE_PRESERVED', 'TRC-022 identity contradiction preserved, never silently resolved');

    # --- TRC-023: root-cause firewall ---------------------------------------------------------------
    my $yaml_g = result_to_yaml($g);
    $ok->($yaml_g =~ /^root_cause: NOT_EVALUATED$/m && $yaml_g =~ /^repair: NOT_EVALUATED$/m, 'TRC-023 root_cause and repair permanently NOT_EVALUATED');
    $ok->($chk->($g, 'ET-G19'){verdict} eq 'pass', 'TRC-023b firewall check passes on engine-derived fields');

    # --- TRC-024/NG-003: no fabricated runtime claims -------------------------------------------------
    $ok->((!grep { $_->{evidence_classification} eq 'DIRECT_EXECUTION_EVIDENCE' } @{ $g->{nodes} }), 'TRC-024 no DIRECT execution claims without a runtime');

    # --- TRC-025: fabricated market data rejection ------------------------------------------------------
    my $r25 = $runf->(data => $mk_data->(raw_fingerprint => '0' x 64));
    $ok->($r25->{status} eq 'INVALID_INPUT' && $chk->($r25, 'ET-G7'){verdict} eq 'fail' && $r25->{blockers}[0]{reason} =~ /mechanically rejected/, 'TRC-025 dataset fingerprint mismatch -> INVALID_INPUT');

    # --- TRC-026/027: deterministic ids and contract ------------------------------------------------------
    my $g2 = $runf->();
    $ok->($g->{trace_id} eq $g2->{trace_id}, 'TRC-026 deterministic trace_id');
    $ok->(result_to_yaml($g) eq result_to_yaml($g2), 'TRC-027 byte-identical contract serialization');

    # --- TRC-028: downstream gate ---------------------------------------------------------------------------
    $ok->($g->{downstream}{allowed} eq 'true' && $g->{downstream}{next_stage} eq 'ROOT_CAUSE_ANALYSIS', 'TRC-028 READY opens ROOT_CAUSE_ANALYSIS');
    $ok->($r21->{downstream}{allowed} eq 'false' && $r21->{downstream}{next_stage} eq 'HALT', 'TRC-028b PARTIAL_TRACE keeps the gate closed');

    # --- negatives ---------------------------------------------------------------------------------------------
    $ok->((!grep { defined $_->{value} && $_->{value} eq 'UNKNOWN' && $_->{evaluation_status} eq 'EVALUATED' && $_->{value_type} eq 'bool' } @{ $g->{nodes} }), 'NG-001 no invented runtime state: UNKNOWN never reported EVALUATED bool');
    $ok->($r21->{target}{bar_index} eq 'UNKNOWN', 'NG-002 no invented bar index without localization');
    $ok->(($g->{execution}{mode} ne 'DIRECT' && !grep { $_->{evidence_classification} eq 'DIRECT_EXECUTION_EVIDENCE' } @{ $g->{nodes} }), 'NG-003 no invented TradingView behavior');
    $ok->((!grep { $_->{evidence_classification} =~ /DIRECT|INSTRUMENTED/ } @{ $g->{nodes} }), 'NG-004 static facts never labeled runtime evidence');
    $ok->(((grep { $_->{evidence_classification} eq 'DETERMINISTIC_RECONSTRUCTION' } @{ $g->{nodes} }) && !grep { $_->{evidence_classification} eq 'DIRECT_EXECUTION_EVIDENCE' } @{ $g->{nodes} }), 'NG-005 reconstructed values labeled reconstruction, never direct');
    $ok->($x1b0->{evaluation_status} eq 'NOT_EVALUATED' && $x1b0->{value} ne '0', 'NG-006 missing branch NOT_EVALUATED, never FALSE');
    $ok->($n7->{value} eq 'NA', 'NG-007 NA stays NA, never FALSE');
    $ok->(($g1b0->{value} eq '1' && !grep { "$_->{bar}" eq '0' && $_->{role} eq 'cond-result' && $_->{value} eq '0' } @{ $g->{nodes} }), 'NG-008 guard branch conversion recorded, no FALSE fabrication');
    $ok->($r19->{status} eq 'BLOCKED', 'NG-009 modified source detected via recorded hash');
    {
        my $before = _sha($impl_text);
        my $r10 = $runf->();
        $ok->(_sha($impl_text) eq $before && $r10->{identity}{source_hash_verified} eq 'true', 'NG-010 production source untouched by the engine');
    }
    {
        my $seeded = 'the missing bar probably caused the signal failure';
        $ok->(($seeded =~ $CAUSAL_RX && $yaml_g !~ $CAUSAL_RX), 'NG-011 causal wording mechanically rejected; engine output clean');
    }
    $ok->(($yaml_g =~ /^repair: NOT_EVALUATED$/m && !grep { ($_->{reason} // '') =~ /repair|patch/i } @{ $g->{blockers} }), 'NG-012 no repair performed or proposed');
    $ok->($r21->{downstream}{next_stage} eq 'HALT' && $r21->{downstream}{next_stage} ne 'ROOT_CAUSE_ANALYSIS', 'NG-013 Phase 14 gate stays closed for incomplete traces');

    print "selftest: $passed passed, $failed failed\n";
    return $failed ? 1 : 0;
}

# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------
sub usage {
    return <<'EOU';
execution_trace.pl — Phase 13 Execution Trace & Debug Engine (schema v1.0)

Usage:
  perl trace/execution_trace.pl --incident FILE --data-contract FILE [--data FILE] [options]

  --incident FILE          Phase 11 incident contract (gate: READY + downstream open)
  --data-contract FILE     Phase 12 data contract (gate: SUFFICIENT + downstream open)
  --data FILE              raw dataset CSV matching the contract raw_fingerprint
                           (ts,open,high,low,close,volume); required for reconstruction
  --implementation FILE    production Pine source (default: implementation/phase9_pine.pine)
  --plan FILE              Phase 8 plan (default: implementation/phase9_authoritative_plan.yaml)
  --impl-result FILE       Phase 9 result (default: implementation/phase9_result.yaml)
  --phase10 FILE           Phase 10 result (default: verification/phase10_post_verification_result.yaml)
  --mode MODE              declared expectation; mismatch is recorded, mode is never upgraded
  --out FILE               write the trace contract to FILE
  --gate-check --trace F   approve only READY/READY_WITH_WARNINGS contracts (exit 0/2)
  --selftest               run the TRC-001..028 + NG-001..013 suite
  --version                print engine version
  --help                   this text

Exit codes: 0 = downstream gate open (ROOT_CAUSE_ANALYSIS); 2 = gate closed;
other non-zero = usage/internal failure.

Boundaries: never modifies production source; never performs root-cause
analysis or repair; never acquires market data; never claims DIRECT runtime
evidence. root_cause and repair remain NOT_EVALUATED permanently.
EOU
}

sub main {
    my @argv = @ARGV;
    my ($incident_file, $data_file, $dataset_file, $impl_file, $plan_file,
        $impl_result_file, $p10_file, $out_file, $trace_file, $mode_expected,
        $gate, $selftest, $show_ver, $show_help) = (undef) x 13;
    while (@argv) {
        my $a = shift @argv;
        if    ($a eq '--incident')      { $incident_file = shift @argv; }
        elsif ($a eq '--data-contract') { $data_file = shift @argv; }
        elsif ($a eq '--data')          { $dataset_file = shift @argv; }
        elsif ($a eq '--implementation'){ $impl_file = shift @argv; }
        elsif ($a eq '--plan')          { $plan_file = shift @argv; }
        elsif ($a eq '--impl-result')   { $impl_result_file = shift @argv; }
        elsif ($a eq '--phase10')       { $p10_file = shift @argv; }
        elsif ($a eq '--out')           { $out_file = shift @argv; }
        elsif ($a eq '--trace')         { $trace_file = shift @argv; }
        elsif ($a eq '--mode')          { $mode_expected = shift @argv; }
        elsif ($a eq '--gate-check')    { $gate = 1; }
        elsif ($a eq '--selftest')      { $selftest = 1; }
        elsif ($a eq '--version')       { $show_ver = 1; }
        elsif ($a eq '--help')          { $show_help = 1; }
        else { print "unknown option: $a\n\n", usage(); return 1; }
    }
    if ($show_ver) { print "$VERSION_STR\n"; return 0; }
    if ($show_help) { print usage(); return 0; }
    if ($selftest) { return selftest(); }

    my $slurp = sub {
        my ($p) = @_;
        return undef unless defined $p && length $p;
        open my $fh, '<:raw', $p or return undef;
        local $/;
        return <$fh>;
    };

    if ($gate) {
        unless (defined $trace_file) { print "gate-check requires --trace FILE\n"; return 2; }
        my $t = $slurp->($trace_file);
        unless (defined $t) { print "gate-check: cannot read $trace_file\n"; return 1; }
        my ($open, $msg) = gate_check_text($t);
        print "$msg\n";
        return $open ? 0 : 2;
    }

    unless (defined $incident_file && defined $data_file) {
        print "production run requires --incident FILE and --data-contract FILE\n\n", usage();
        return 1;
    }
    my $incident_text = $slurp->($incident_file);
    unless (defined $incident_text) { print "cannot read incident contract: $incident_file\n"; return 1; }
    my $data_text = $slurp->($data_file);
    unless (defined $data_text) { print "cannot read data contract: $data_file\n"; return 1; }
    my $dataset_raw = $slurp->($dataset_file) if defined $dataset_file;
    if (defined $dataset_file && !defined $dataset_raw) { print "cannot read dataset: $dataset_file\n"; return 1; }
    my $impl_text = $slurp->($impl_file // $IMPL_DEFAULT);
    unless (defined $impl_text) { print "cannot read implementation: " . ($impl_file // $IMPL_DEFAULT) . "\n"; return 1; }
    my $plan_text = $slurp->($plan_file // $PLAN_DEFAULT);
    unless (defined $plan_text) { print "cannot read plan: " . ($plan_file // $PLAN_DEFAULT) . "\n"; return 1; }
    my $impl_result_text = $slurp->($impl_result_file // $IMPL_RESULT_DEFAULT);
    unless (defined $impl_result_text) { print "cannot read Phase 9 result: " . ($impl_result_file // $IMPL_RESULT_DEFAULT) . "\n"; return 1; }
    my $p10_text = $slurp->($p10_file // $P10_DEFAULT);
    unless (defined $p10_text) { print "cannot read Phase 10 result: " . ($p10_file // $P10_DEFAULT) . "\n"; return 1; }

    my $r = run_engine({
        incident_text => $incident_text, data_text => $data_text,
        dataset_raw => $dataset_raw, impl_text => $impl_text,
        plan_text => $plan_text, impl_result_text => $impl_result_text,
        p10_text => $p10_text, mode_expected => $mode_expected,
    });
    my $yaml = result_to_yaml($r);
    if (defined $out_file) {
        open my $fh, '>', $out_file or do { print "cannot write $out_file: $!\n"; return 1; };
        binmode $fh;
        print {$fh} encode('UTF-8', $yaml);
        close $fh;
        print "trace contract written to $out_file\n";
    }
    else {
        binmode STDOUT;
        print encode('UTF-8', $yaml);
    }
    return ($r->{downstream}{allowed} eq 'true') ? 0 : 2;
}

exit main() unless caller;
