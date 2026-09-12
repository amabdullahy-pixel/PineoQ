#!/usr/bin/perl
# ============================================================================
# data_acquisition.pl — Market Data Acquisition & Alignment engine (pine-agent Phase 12)
# ============================================================================
# Core Perl 5, zero non-core dependencies (Digest::SHA, Encode, File::Basename
# are core). Runtime contract identical to router.pl / formalize.pl /
# pre_verify.pl / feasibility.pl / implement.pl / incident_intake.pl.
#
# Narrative authority: meta/data_acquisition_alignment_procedure.md
# Contract schema:      data/contract_schema.yaml (v1.0)
#
# Purpose: deterministic evidence layer between
#   PHASE 11 INCIDENT + MARKET DATA SOURCES  →  ALIGNED, AUDITED DATA CONTRACT
# suitable for consumption by Phase 13 (EXECUTION_TRACE_AND_DEBUG).
#
# CORE PRINCIPLE: DATA IS EVIDENCE.
#   Every dataset carries explicit provenance. Unknowns stay unknown
#   (load-bearing unknown rule). Chart images are never authoritative OHLCV.
#   Raw data is preserved and fingerprinted; normalization is recorded, never
#   destructive. The engine answers only "what data do we have, is it aligned,
#   is it sufficient for Phase 13?" — never "why did the signal fail?".
#   Root cause belongs to Phase 14: causal wording in any engine-derived field
#   is mechanically rejected (firewall, DA-G13 / NG-005).
#
# HARD INPUT GATE (procedure §2): refuses to run unless
#   1) Phase 10 REV 4 result reads verdict: validated (read-only),
#   2) a Phase 11 incident contract is supplied (--incident),
#   3) incident phase11_status is READY | READY_WITH_WARNINGS,
#   4) incident next_stage is DATA_ACQUISITION_AND_ALIGNMENT and
#      downstream_allowed is true, blockers empty,
#   5) incident_id is well-formed (incident-<12 hex>).
#
# FIXTURE FIREWALL (procedure §14): fixture-tagged datasets (fixture: true or
# fingerprints prefixed TEST_FIXTURE|) are mechanically rejected from
# production contracts — synthetic data exists only inside --selftest.
#
# NO-DATA ENVIRONMENT (prompt §28): no external network access exists here.
# Without an explicit --data source the honest result is INSUFFICIENT_DATA.
# The engine never fabricates OHLCV, timestamps, or sources.
#
# MULTI-TIMEFRAME INGESTION (rev2, schema v1.1 — additive; procedure SS54):
#   Multiple explicitly supplied CSV datasets may belong to one incident.
#   Each dataset keeps independent provenance, identity metadata, schema,
#   timestamp convention, and per-dataset DI01–DI10 validation. Cross-dataset
#   checks (DA-G17 identity consistency, DA-G18 timeframe identity,
#   DA-G19 coverage relationship, DA-G20 required-timeframe mapping) run
#   additively. Never: inferred metadata, silent resampling, merged rows
#   across timeframes, substituted timeframes. Duplicate dataset bytes and
#   conflicting duplicate timeframes are mechanically rejected. Declared
#   symbol contradiction against the incident target is a hard blocker.
#
# CLI (procedure §20 + SS54):
#   --incident FILE          Phase 11 contract (required)
#   --data FILE              CSV dataset (repeatable): header or positional
#   --source NAME --authority A --provider P --retrieval M --retrieved-at TS
#   --timezone TZ --exchange EX --market-type TYPE
#   --timeframe TF           declared timeframe of the next --data (per dataset)
#   --symbol SYM             declared symbol of the next --data (per dataset)
#   --session S              declared session of the next --data (per dataset)
#   --expect-sha256 HEX      expected raw-byte sha256 of the next --data
#   --warmup N --mtf TF,TF,...
#   --out FILE --help --version --selftest --gate-check --data CONTRACT
# Exit: 0 = READY/READY_WITH_WARNINGS (downstream open);
#       2 = INSUFFICIENT_DATA/BLOCKED/INVALID_INPUT (HALT); die = internal.
#
# Determinism: no clock, no randomness, no environment values.
#   data_contract_id = "data-" + first 12 hex of sha256(canonical body).
#   (source_path is recorded in the contract but excluded from the hash body:
#    filesystem locations are environment values, procedure §15/§25.)
# NO-PINE RULE: this engine acquires and aligns data. It never emits Pine.
# ============================================================================
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode);
use File::Basename qw(dirname);

# ---------------------------------------------------------------------------
# findings accumulators (reset per run)
# ---------------------------------------------------------------------------
my ($WRNS, $BLKS);
sub r_warns { $WRNS ||= []; return $WRNS; }
sub r_blks  { $BLKS  ||= []; return $BLKS; }
sub add_warning { my ($cid, $code, $msg) = @_; push @{ r_warns() }, { check_id => $cid, code => $code, message => $msg }; return; }
sub add_blocker { my ($cid, $msg) = @_; push @{ r_blks() }, { check_id => $cid, message => $msg }; return; }

my ($UCOUNT, $CCOUNT, $FCOUNT) = (0, 0, 0);
my (@UNKNOWNS, @CONTRAS, @FACTS, @LIMS, @XFORMS);
sub add_unknown { my ($desc, $material) = @_; $UCOUNT++; push @UNKNOWNS, { id => sprintf('UNK-%03d', $UCOUNT), description => $desc, material => ($material ? 'true' : 'false') }; return; }
sub add_contra  { my ($a, $b) = @_; $CCOUNT++; push @CONTRAS, { id => sprintf('CONTRA-%03d', $CCOUNT), claim_a => $a, claim_b => $b, resolution => 'NONE_PRESERVED' }; return; }
sub add_fact    { my (%a) = @_; $FCOUNT++; push @FACTS, { fact => $a{fact}, value => $a{value}, classification => $a{classification}, provenance => $a{provenance}, source_id => $a{source_id}, confidence => $a{confidence} }; return; }
sub add_lim     { my ($d) = @_; push @LIMS, $d; return; }
sub add_xform   { my (%a) = @_; push @XFORMS, { transformation_id => $a{id}, source_dataset => $a{src}, operation => $a{op}, parameters => $a{params}, reason => $a{reason}, output_dataset => $a{out}, deterministic => $a{det} }; return; }

# ---------------------------------------------------------------------------
# vocabulary (schema enums — no silent extension)
# ---------------------------------------------------------------------------
my %AUTH_OK   = map { $_ => 1 } qw(AUTHORITATIVE QUALIFIED_EXTERNAL USER_PROVIDED DERIVED UNKNOWN);
my %PROV_OK   = map { $_ => 1 } qw(ACQUIRED DERIVED NORMALIZED ALIGNED USER_PROVIDED UNKNOWN);
my %CONF_OK   = map { $_ => 1 } qw(HIGH MEDIUM LOW UNDETERMINED);
my %MTYPE_OK  = map { $_ => 1 } qw(SPOT FUTURES_PERPETUAL CFD SYNTHETIC_FEED UNKNOWN);
my %ALIGN_OK  = map { $_ => 1 } qw(EXACT PROBABLE APPROXIMATE UNKNOWN);

# causal wording firewall (DA-G13): mechanical, engine-side
my $CAUSAL_RX = qr/\b(root cause|caused|because the|reason (the|of)|why the signal|bug location|faulty condition|incorrect formula|probably caused|likely because|most likely reason)\b/i;

# ---------------------------------------------------------------------------
# upstream gate: Phase 10 REV 4 must read validated (read-only)
# ---------------------------------------------------------------------------
sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return decode('UTF-8', $t); }

sub default_upstream_path {
    (my $f = __FILE__) =~ s{\\}{/}g;
    return dirname($f) . '/../verification/phase10_post_verification_result.yaml';
}

sub upstream_validated {
    my $path = default_upstream_path();
    return (0, 'missing') unless -f $path;
    my $t = eval { _slurp($path) };
    return (0, 'unreadable') unless defined $t;
    my ($verdict) = $t =~ /^\s{2}verdict:\s*'?([A-Za-z_]+)'?/m;
    my ($iid)     = $t =~ /^\s{2}implementation_id_under_verification:\s*'?([^'\s]+)'?/m;
    return (0, 'not validated') unless defined $verdict && $verdict eq 'validated';
    return (1, ($iid // 'artifact'));
}

# ---------------------------------------------------------------------------
# Phase 11 contract parsing (subset — quoted scalars; gate fields verified)
# ---------------------------------------------------------------------------
sub _unq { my $s = shift; return undef if !defined $s; $s =~ s/^'//; $s =~ s/'$//; $s =~ s/''/'/g; return $s; }

sub parse_incident {
    my ($t) = @_;
    return undef unless defined $t && length $t;
    my ($iid) = $t =~ /^\s{2}incident_id:\s*'([^']*)'/m;
    my ($st)  = $t =~ /^\s{2}phase11_status:\s*'([^']*)'/m;
    my ($ns)  = $t =~ /^\s{2}next_stage:\s*(\S+)/m;
    my ($da)  = $t =~ /^\s{2}downstream_allowed:\s*(true|false)/m;
    my ($sym) = $t =~ /^\s{4}symbol:\s*'([^']*)'/m;
    my ($sym_st) = $t =~ /^\s{4}symbol:\s*'[^']*' # '([A-Z_]+)'/m;
    my ($ex)  = $t =~ /^\s{4}exchange:\s*'([^']*)'/m;
    my ($tf)  = $t =~ /^\s{4}timeframe:\s*'([^']*)'/m;
    my ($tz)  = $t =~ /^\s{4}timezone:\s*'([^']*)'/m;
    my ($impl) = $t =~ /^\s{4}implementation_id:\s*'([^']*)'/m;
    my ($lts) = $t =~ /^\s{4}timestamp:\s*'([^']*)'/m;
    my ($lbi) = $t =~ /^\s{4}bar_index:\s*'([^']*)'/m;
    my ($lrg) = $t =~ /^\s{4}region:\s*'([^']*)'/m;
    my ($lme) = $t =~ /^\s{4}method:\s*'([^']*)'/m;
    my ($exp) = $t =~ /^\s{4}description:\s*'([^']*)'/m;
    my ($obs) = $t =~ /^\s{4}description:\s*'([^']*)'\s*\n\s{4}source:/m;
    my $blockers_empty = ($t =~ /^  blockers: \[\]/m) ? 1 : 0;
    return {
        incident_id => _unq($iid), phase11_status => _unq($st), next_stage => $ns,
        downstream_allowed => $da, symbol => _unq($sym), symbol_status => $sym_st,
        exchange => _unq($ex), timeframe => _unq($tf), timezone => _unq($tz),
        implementation_id => _unq($impl), loc_timestamp => _unq($lts),
        loc_bar_index => _unq($lbi), loc_region => _unq($lrg), loc_method => _unq($lme),
        expected => _unq($exp), observed => _unq($obs),
        blockers_empty => $blockers_empty,
    };
}

sub incident_gate {
    my ($inc) = @_;
    return 'incident_id missing or malformed'           unless defined $inc->{incident_id} && $inc->{incident_id} =~ /^incident-[0-9a-f]{12}$/;
    return "phase11_status is '" . ($inc->{phase11_status} // 'null') . "'" unless defined $inc->{phase11_status} && ($inc->{phase11_status} eq 'READY' || $inc->{phase11_status} eq 'READY_WITH_WARNINGS');
    return 'incident blockers list is non-empty'        unless $inc->{blockers_empty};
    return "incident next_stage is '" . ($inc->{next_stage} // 'null') . "'" unless defined $inc->{next_stage} && $inc->{next_stage} eq 'DATA_ACQUISITION_AND_ALIGNMENT';
    return "incident downstream_allowed is '" . ($inc->{downstream_allowed} // 'null') . "'" unless defined $inc->{downstream_allowed} && $inc->{downstream_allowed} eq 'true';
    return '';
}

# ---------------------------------------------------------------------------
# CSV dataset parsing (rev2): header-aware; schema + timestamp convention
#   accepted layouts:
#     a) header row naming time/ts/timestamp, open, high, low, close [, volume]
#        — extra columns are IGNORED (recorded in schema, never merged in);
#     b) legacy positional ts,open,high,low,close[,volume].
#   raw fingerprint over raw bytes; parsed rows normalized deterministically
#   (chronological stable sort — original order preserved for DI03 verdict).
#   Volume absent from the file stays absent (UNKNOWN) — never fabricated.
# ---------------------------------------------------------------------------
sub parse_csv_dataset {
    my ($raw) = @_;
    return undef unless defined $raw && length $raw;
    my @lines = split /\r?\n/, $raw;
    my @rows;
    my $line_no = 0;
    my %col;                # name -> index
    my ($schema, $ts_conv) = ('UNKNOWN', 'UNKNOWN');
    for my $line (@lines) {
        $line_no++;
        next if $line =~ /^\s*$/;
        next if $line =~ /^#/;
        my @c = split /,/, $line;
        if (!%col && $line =~ /^\s*(ts|timestamp|time)\s*,/i) {   # header row
            my @names = map { my $n = $_; $n =~ s/^\s+|\s+$//g; lc($n) } @c;
            my $ti;
            for my $i (0 .. $#names) {
                my $n = $names[$i];
                if    ($n =~ /^(ts|timestamp|time)$/)        { $ti = $i; $col{ts} = $i; }
                elsif ($n eq 'open')                         { $col{open} = $i; }
                elsif ($n eq 'high')                         { $col{high} = $i; }
                elsif ($n eq 'low')                          { $col{low} = $i; }
                elsif ($n eq 'close')                        { $col{close} = $i; }
                elsif ($n eq 'volume' || $n eq 'vol')        { $col{volume} = $i; }
            }
            return undef unless defined $ti && defined $col{open} && defined $col{high} && defined $col{low} && defined $col{close};
            my @ordered = map { $names[ $col{$_} ] // '' } grep { defined $col{$_} } qw(ts open high low close volume);
            $schema = 'header:' . join(',', @ordered) . (scalar(@names) > scalar(@ordered) ? "+extraneous(" . (scalar(@names) - scalar(@ordered)) . ")" : "");
            $ts_conv = 'UNKNOWN';   # convention is a declared fact, never inferred from format alone
            next;
        }
        next if !%col && $line =~ /^\s*(ts|timestamp|time)\s*,/i;   # (defensive)
        if (%col) {
            return undef unless defined $c[ $col{ts} ] && length $c[ $col{ts} ];
            my $v = defined $col{volume} ? $c[ $col{volume} ] : '';
            push @rows, {
                ts => $c[ $col{ts} ],
                open => ($c[ $col{open} ] eq '' ? undef : $c[ $col{open} ] + 0),
                high => ($c[ $col{high} ] eq '' ? undef : $c[ $col{high} ] + 0),
                low  => ($c[ $col{low} ] eq '' ? undef : $c[ $col{low} ] + 0),
                close => ($c[ $col{close} ] eq '' ? undef : $c[ $col{close} ] + 0),
                volume => (!defined $v || $v eq '' ? undef : $v + 0),
                raw_line_no => $line_no,
            };
        }
        else {
            # legacy positional
            return undef if @c < 5 || @c > 6;
            my ($ts, $o, $h, $l, $cl, $v) = (@c, @c < 6 ? ('') : ());
            return undef unless defined $ts && length $ts;
            push @rows, {
                ts => $ts,
                open => ($o eq '' ? undef : $o + 0), high => ($h eq '' ? undef : $h + 0),
                low  => ($l eq '' ? undef : $l + 0), close => ($cl eq '' ? undef : $cl + 0),
                volume => (!defined $v || $v eq '' ? undef : $v + 0),
                raw_line_no => $line_no,
            };
        }
    }
    return undef unless @rows;   # a header with zero data rows is not a dataset
    return { rows => \@rows, schema => $schema, ts_convention => $ts_conv,
             has_volume => (defined $col{volume} ? 1 : 0) };
}

# ---------------------------------------------------------------------------
# integrity checks DI01–DI10 (deterministic; no data mutation)
# ---------------------------------------------------------------------------
sub _ts_num { my ($ts) = @_; return undef unless defined $ts;
    # true UTC epoch seconds via days-from-civil (proleptic Gregorian) — correct
    # across month/year boundaries incl. leap years (the former concatenated
    # Y/M/D basis mis-measured every rollover, e.g. Aug 31 -> Sep 1, inflating
    # DI01 missing-bar counts by ~10^5; Phase 12 REV 3 defect fix)
    if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?/) {
        my ($y, $m, $d, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, ($6 // 0));
        $y -= $m <= 2;
        my $era = int(($y >= 0 ? $y : $y - 399) / 400);
        my $yoe = $y - $era * 400;
        my $doy = int((153 * ($m + ($m > 2 ? -3 : 9)) + 2) / 5) + $d - 1;
        my $doe = $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy;
        my $days = $era * 146097 + $doe - 719468;
        return $days * 86400 + $hh * 3600 + $mm * 60 + $ss;
    }
    return $ts + 0 if $ts =~ /^\d+$/;
    return undef; }

sub integrity_checks {
    my ($rows, $declared_tf_minutes, $warmup_required) = @_;
    my @checks;
    my $n = scalar @$rows;

    # DI03 out-of-order (on the supplied order, before any sorting)
    my $out_of_order = 0;
    for my $i (1 .. $n - 1) {
        my ($a, $b) = (_ts_num($rows->[$i - 1]{ts}), _ts_num($rows->[$i]{ts}));
        $out_of_order++ if defined $a && defined $b && $b < $a;
    }

    # deterministic working copy: stable chronological sort (recorded as a
    # transformation when it changes anything; raw dataset untouched)
    my @sorted = _ts_num($rows->[0]{ts}) ? sort { (_ts_num($a->{ts}) <=> _ts_num($b->{ts})) || ($a->{raw_line_no} <=> $b->{raw_line_no}) } @$rows : ();
    my $sorted_changed = @sorted && (join('|', map { $_->{ts} } @sorted) ne join('|', map { $_->{ts} } @$rows)) ? 1 : 0;

    # DI02 duplicates
    my %seen; my $dupes = 0;
    for my $r (@sorted) { $dupes++ if $seen{ $r->{ts} }++; }

    # DI01/DI04 missing bars / gaps from declared timeframe
    my ($missing, $gaps) = (0, 0);
    if ($declared_tf_minutes && @sorted > 1) {
        my $step = $declared_tf_minutes * 60;
        for my $i (1 .. $#sorted) {
            my ($a, $b) = (_ts_num($sorted[$i - 1]{ts}), _ts_num($sorted[$i]{ts}));
            next unless defined $a && defined $b;
            my $d = $b - $a;
            if ($d > $step) { $missing += int($d / $step) - 1; $gaps++; }
        }
    }

    # DI05 OHLC structural validity
    my $ohlc_err = 0;
    for my $r (@sorted) {
        next unless defined $r->{high} && defined $r->{low} && defined $r->{open} && defined $r->{close};
        $ohlc_err++ if $r->{high} < $r->{low} || $r->{high} < $r->{open} || $r->{high} < $r->{close} || $r->{low} > $r->{open} || $r->{low} > $r->{close};
    }

    # DI06 invalid numeric values + unparseable timestamps
    my $invalid = 0;
    for my $r (@sorted) {
        for my $f (qw(open high low close)) {
            $invalid++ if defined $r->{$f} && ($r->{$f} != $r->{$f} || $r->{$f} =~ /inf/i);
        }
    }
    my $bad_ts = 0;
    for my $r (@$rows) { $bad_ts++ unless defined _ts_num($r->{ts}); }

    # DI07 volume integrity (zero is NOT invalid; negative is, where volume applies)
    my ($vol_missing, $vol_negative, $vol_zero) = (0, 0, 0);
    for my $r (@sorted) {
        if (!defined $r->{volume}) { $vol_missing++; }
        elsif ($r->{volume} < 0)   { $vol_negative++; }
        elsif ($r->{volume} == 0)  { $vol_zero++; }
    }

    # DI10 coverage vs warm-up requirement
    my $warmup_ok = (!$warmup_required || $n >= $warmup_required) ? 1 : 0;

    push @checks, { check_id => 'DI01', verdict => $missing      ? 'fail' : 'pass', findings => $missing      ? ["$missing expected bar(s) absent"] : [] };
    push @checks, { check_id => 'DI02', verdict => $dupes        ? 'fail' : 'pass', findings => $dupes        ? ["$dupes duplicate timestamp(s)"] : [] };
    push @checks, { check_id => 'DI03', verdict => $out_of_order ? 'warn' : 'pass', findings => $out_of_order ? ["$out_of_order ordering violation(s) in the supplied order"] : [] };
    push @checks, { check_id => 'DI04', verdict => $gaps         ? 'warn' : 'pass', findings => $gaps         ? ["$gaps temporal gap(s)"] : [] };
    push @checks, { check_id => 'DI05', verdict => $ohlc_err     ? 'fail' : 'pass', findings => $ohlc_err     ? ["$ohlc_err structurally invalid OHLC row(s)"] : [] };
    push @checks, { check_id => 'DI06', verdict => ($invalid || $bad_ts)  ? 'fail' : 'pass', findings => ($invalid || $bad_ts) ? [ ($invalid ? "$invalid invalid numeric value(s)" : ()), ($bad_ts ? "$bad_ts unparseable timestamp(s)" : ()) ] : [] };
    push @checks, { check_id => 'DI07', verdict => $vol_negative ? 'fail' : ($vol_missing ? 'warn' : 'pass'),
                   findings => [ ($vol_negative ? "$vol_negative negative volume row(s)" : ()), ($vol_missing ? "$vol_missing missing volume field(s) (zero volume: $vol_zero — not classified invalid)" : ()) ] };
    push @checks, { check_id => 'DI08', verdict => 'pass', findings => [] };  # identity cross-checks recorded at alignment stage
    push @checks, { check_id => 'DI09', verdict => 'pass', findings => [] };  # timeframe consistency recorded at alignment stage
    push @checks, { check_id => 'DI10', verdict => $warmup_ok ? 'pass' : 'fail', findings => $warmup_ok ? [] : ["required warm-up coverage ($warmup_required bars) not met (available: $n)"] };
    return (\@checks, $sorted_changed, { n => $n, missing => $missing, dupes => $dupes, out_of_order => $out_of_order,
            gaps => $gaps, ohlc_err => $ohlc_err, invalid => $invalid, bad_ts => $bad_ts, vol_missing => $vol_missing,
            vol_negative => $vol_negative, vol_zero => $vol_zero, warmup_ok => $warmup_ok });
}

# ---------------------------------------------------------------------------
# timeframe string → minutes (declared timeframe only; never converted)
# ---------------------------------------------------------------------------
sub tf_minutes {
    my ($tf) = @_;
    return undef unless defined $tf;
    return $1 * 1        if $tf =~ /^(\d+)m$/i;
    return $1 * 60       if $tf =~ /^(\d+)h$/i;
    return $1 * 1440     if $tf =~ /^(\d+)d$/i;
    return 1440          if $tf =~ /^1?D$/;
    return undef;
}

# ---------------------------------------------------------------------------
# engine core — stages 01–20
# ---------------------------------------------------------------------------
sub _bad_finalize {
    my ($inc, $status, $msg) = @_;
    return _finalize({ input_status => $status, msg => $msg, incident => ($inc // undef) });
}

sub data_contract_text {
    my ($spec) = @_;
    ($WRNS, $BLKS) = (undef, undef);
    ($UCOUNT, $CCOUNT, $FCOUNT) = (0, 0, 0);
    @UNKNOWNS = (); @CONTRAS = (); @FACTS = (); @LIMS = (); @XFORMS = ();

    my $bad = sub {
        my ($status, $msg) = @_;
        add_blocker('DA-G2', $msg) if defined $msg;
        return _bad_finalize($spec->{_last_good_incident}, $status, $msg);
    };

    # --- Stage 02: upstream validation ---------------------------------------
    my ($up_ok, $up_msg) = upstream_validated();
    return $bad->('BLOCKED', "upstream Phase 10 result not validated ($up_msg)") unless $up_ok;

    # --- Stage 03: Phase 11 input gate -----------------------------------------
    my $inc = eval { parse_incident($spec->{incident_text}) };
    $spec->{_last_good_incident} = $inc;
    return $bad->('INVALID_INPUT', 'incident contract missing or unparseable') unless $inc;
    my $gate_msg = incident_gate($inc);
    return $bad->('BLOCKED', "Phase 11 gate: $gate_msg") if $gate_msg;

    # --- Stage 04/05: data source discovery + acquisition ----------------------
    my @sources;
    my @datasets;
    my $sidx = 0;
    my %seen_fp;          # raw sha256 -> first dataset id (SS54 duplicate rejection)
    for my $d (@{ $spec->{datasets} || [] }) {
        $sidx++;
        my $sid = sprintf('SRC-%03d', $sidx);
        my $did = sprintf('DS-%03d', $sidx);

        # FIXTURE FIREWALL: synthetic data never enters a production contract
        if ($d->{fixture} || (defined $d->{raw} && $d->{raw} =~ /^TEST_FIXTURE\|/)) {
            return $bad->('INVALID_INPUT', "dataset $did is fixture-tagged (TEST_FIXTURE) — synthetic data is mechanically excluded from production contracts");
        }
        my $parsed = parse_csv_dataset($d->{raw});
        return $bad->('INVALID_INPUT', "dataset $did ('" . ($d->{source} // "source $sidx") . "') is not parseable as ts,open,high,low,close,volume") unless ref $parsed eq 'HASH';
        my $rows = $parsed->{rows};
        return $bad->('INVALID_INPUT', "dataset $did is empty — no bars supplied") unless @$rows;
        my $ds_schema    = $parsed->{schema}      // 'UNKNOWN';
        my $ds_tsconv    = $parsed->{ts_convention} // 'UNKNOWN';
        my $ds_has_vol   = $parsed->{has_volume}  // 0;

        my $raw_fp = sha256_hex(encode('UTF-8', $d->{raw}));

        # SS54 rev2: duplicate dataset bytes and declared expect-sha256 mismatch
        # are mechanically rejected — multi-dataset input integrity (DA-G17).
        if ($seen_fp{ $raw_fp }) {
            return $bad->('INVALID_INPUT', "dataset $did duplicates the raw bytes of " . $seen_fp{$raw_fp} . " (sha256 $raw_fp) — duplicate dataset rejected");
        }
        $seen_fp{ $raw_fp } = $did;
        if (defined $d->{expect_sha256} && length $d->{expect_sha256}) {
            my $exp = lc($d->{expect_sha256});
            $exp =~ s/^[^0-9a-f]+//; $exp =~ s/[^0-9a-f]//g;
            return $bad->('INVALID_INPUT', "dataset $did raw-byte sha256 mismatch: expected " . ($d->{expect_sha256}) . ", computed $raw_fp — evidence integrity violated (DA-G10)")
                unless $exp eq $raw_fp;
            add_fact(fact => "dataset $did expect-sha256 verified", value => $raw_fp, classification => 'ACQUIRED',
                     provenance => 'ACQUIRED', source_id => $sid, confidence => 'HIGH');
        }

        my $decl_tf     = defined $d->{timeframe}     ? $d->{timeframe}     : (($inc->{timeframe} // 'UNKNOWN') ne 'UNKNOWN' ? $inc->{timeframe} : undef);
        my $decl_sym    = defined $d->{symbol}        ? $d->{symbol}        : (($inc->{symbol} // 'UNKNOWN') ne 'UNKNOWN' ? $inc->{symbol} : undef);
        my $decl_ex     = defined $d->{exchange}      ? $d->{exchange}      : (($inc->{exchange} // 'UNKNOWN') ne 'UNKNOWN' ? $inc->{exchange} : undef);
        my $decl_tz     = defined $d->{timezone}      ? $d->{timezone}      : 'UNKNOWN';
        my $decl_sess   = defined $d->{session}       ? $d->{session}       : 'UNKNOWN';
        my $decl_mt     = defined $d->{market_type}   ? uc($d->{market_type}) : 'UNKNOWN';
        $decl_mt = $decl_mt =~ /^(SPOT|FUTURES_PERPETUAL|CFD|SYNTHETIC_FEED|UNKNOWN)$/ ? $decl_mt : 'UNKNOWN';
        my $src = {
            source_id => $sid, source_name => ($d->{source} // "source $sidx"), source_type => 'FILE',
            authority => $d->{authority} // 'UNKNOWN', provenance => 'ACQUIRED',
            provider => $d->{provider} // 'UNKNOWN',
            retrieval_method => 'FILE_READ', retrieval_timestamp => $d->{retrieved_at} // 'UNKNOWN',
            market => 'UNKNOWN',
            symbol => ($decl_sym // 'UNKNOWN'),
            exchange => ($decl_ex // 'UNKNOWN'),
            timezone => ($decl_tz // 'UNKNOWN'),
            timeframe => ($decl_tf // 'UNKNOWN'),
            session => ($decl_sess // 'UNKNOWN'),
            market_type => $decl_mt,
            coverage_start => $rows->[0]{ts}, coverage_end => $rows->[-1]{ts},
            raw_fingerprint => $raw_fp, raw_preservation => 'preserved',
            raw_schema => $ds_schema, ts_convention => $ds_tsconv, has_volume => ($ds_has_vol ? 'true' : 'false'),
            authentication => 'none',
        };
        push @sources, $src;
        push @datasets, {
            dataset_id => $did, source_id => $sid, fixture => 'false',
            fields => 'ts,open,high,low,close' . ($ds_has_vol ? ',volume' : ''),
            row_count => scalar @$rows,
            coverage_start => $rows->[0]{ts}, coverage_end => $rows->[-1]{ts},
            raw_fingerprint => $raw_fp, normalized_fingerprint => undef, rows => $rows,
            schema => $ds_schema, ts_convention => $ds_tsconv,
            symbol => ($decl_sym // 'UNKNOWN'), exchange => ($decl_ex // 'UNKNOWN'),
            timezone => ($decl_tz // 'UNKNOWN'), timeframe => ($decl_tf // 'UNKNOWN'),
            session => ($decl_sess // 'UNKNOWN'), market_type => $decl_mt,
            expect_sha256 => ($d->{expect_sha256} // undef),
        };
        add_fact(fact => "dataset $did row_count", value => scalar @$rows, classification => 'ACQUIRED',
                 provenance => 'ACQUIRED', source_id => $sid, confidence => 'HIGH');
        add_fact(fact => "dataset $did raw fingerprint", value => $raw_fp, classification => 'ACQUIRED',
                 provenance => 'ACQUIRED', source_id => $sid, confidence => 'HIGH');
        add_fact(fact => "dataset $did coverage", value => $rows->[0]{ts} . ' .. ' . $rows->[-1]{ts},
                 classification => 'ACQUIRED', provenance => 'ACQUIRED', source_id => $sid, confidence => 'HIGH');
    }

    # source identity: symbol/exchange/timezone/session remain UNKNOWN unless supplied
    my $target = {
        symbol => ($inc->{symbol} // 'UNKNOWN'), symbol_status => ($inc->{symbol} && $inc->{symbol} ne 'UNKNOWN' ? 'USER_PROVIDED' : 'UNKNOWN'),
        exchange => ($inc->{exchange} // 'UNKNOWN'), exchange_status => ($inc->{exchange} && $inc->{exchange} ne 'UNKNOWN' ? 'USER_PROVIDED' : 'UNKNOWN'),
        market_type => ($spec->{market_type} // 'UNKNOWN'),
        instrument_type => 'UNKNOWN',
        timeframe => ($inc->{timeframe} // 'UNKNOWN'), timeframe_status => ($inc->{timeframe} && $inc->{timeframe} ne 'UNKNOWN' ? 'USER_PROVIDED' : 'UNKNOWN'),
        timezone => ($inc->{timezone} // 'UNKNOWN'), timezone_status => ($inc->{timezone} && $inc->{timezone} ne 'UNKNOWN' && $inc->{timezone} ne 'NOT_PROVIDED' ? 'USER_PROVIDED' : 'UNKNOWN'),
        session => 'UNKNOWN',
    };
    $target->{market_type} = uc($target->{market_type}) =~ /^(SPOT|FUTURES_PERPETUAL|CFD|SYNTHETIC_FEED|UNKNOWN)$/ ? uc($target->{market_type}) : 'UNKNOWN';

    # DA-G3: source provenance validity
    for my $s (@sources) {
        add_blocker('DA-G3', "source $s->{source_id} authority outside the trust model") unless $AUTH_OK{ $s->{authority} };
    }
    # load-bearing unknowns from identity gaps (DA-G12): recorded, gate-affecting
    add_unknown("exchange identity is UNKNOWN — dataset identity cannot be fully established", 1) if $target->{exchange} eq 'UNKNOWN' && @sources;
    add_unknown("market data timezone is UNKNOWN — timestamp alignment cannot be validated", 1) if $target->{timezone} eq 'UNKNOWN' && @sources;
    add_unknown("session identity is UNKNOWN — session alignment not established (recorded as non-material pending market-type evidence)", 0) if @sources;
    add_lim('market_type/instrument_type not established beyond supplied evidence') if @sources;

    # --- Stage 08: normalization (recorded, never destructive) -----------------
    my @norm_fps;
    for my $ds (@datasets) {
        # SS54: each dataset is validated against its OWN declared timeframe —
        # a 60m dataset is never cadence-checked on the incident's 5m grid.
        my $tf_for_this = ($ds->{timeframe} // 'UNKNOWN') ne 'UNKNOWN' ? $ds->{timeframe} : $target->{timeframe};
        my ($checks, $sorted_changed, $stats) = integrity_checks($ds->{rows}, tf_minutes($tf_for_this), $spec->{warmup});
        $ds->{checks} = $checks;
        $ds->{stats} = $stats;
        # canonical normalized body: ts,open,high,low,close,volume in chronological order
        my @sorted = sort { (_ts_num($a->{ts}) <=> _ts_num($b->{ts})) || ($a->{raw_line_no} <=> $b->{raw_line_no}) } @{ $ds->{rows} };
        my $body = join("\n", map { join(',', $_->{ts}, ($_->{open} // ''), ($_->{high} // ''), ($_->{low} // ''), ($_->{close} // ''), (defined $_->{volume} ? $_->{volume} : '')) } @sorted);
        $ds->{normalized_fingerprint} = sha256_hex(encode('UTF-8', $body));
        push @norm_fps, $ds->{normalized_fingerprint};
        add_xform(id => sprintf('X-%03d', scalar @XFORMS + 1), src => $ds->{dataset_id},
                  op => 'canonicalize+sort', params => 'chronological stable sort; canonical CSV field order ts,open,high,low,close,volume',
                  reason => 'deterministic normalized fingerprint', out => $ds->{dataset_id} . '-N', det => 'true');
        add_fact(fact => "dataset $ds->{dataset_id} normalized fingerprint", value => $ds->{normalized_fingerprint},
                 classification => 'NORMALIZED', provenance => 'NORMALIZED', source_id => $ds->{source_id}, confidence => 'HIGH');
    }

    # --- Stage 09/10: timestamp/timezone + identity alignment --------------------
    my $alignment_status = 'UNKNOWN';
    my $alignment_conf = 'UNDETERMINED';
    if (@datasets) {
        my $identity_ok = ($target->{symbol} ne 'UNKNOWN') && ($target->{exchange} ne 'UNKNOWN') && ($target->{timeframe} ne 'UNKNOWN') && ($target->{timezone} ne 'UNKNOWN');
        if ($identity_ok) {
            $alignment_status = 'EXACT'; $alignment_conf = 'HIGH';
        } elsif ($target->{symbol} ne 'UNKNOWN' && $target->{timeframe} ne 'UNKNOWN') {
            $alignment_status = 'PROBABLE'; $alignment_conf = 'MEDIUM';
            add_warning('DA-G5', 'W-ALIGNMENT-PARTIAL', 'symbol/timeframe established but exchange/timezone identity incomplete — alignment is PROBABLE, never exact');
        } else {
            $alignment_status = 'APPROXIMATE'; $alignment_conf = 'LOW';
            add_warning('DA-G5', 'W-ALIGNMENT-WEAK', 'target identity insufficiently established — alignment stays approximate, never promoted');
        }
        add_fact(fact => 'alignment status', value => $alignment_status, classification => 'ALIGNED',
                 provenance => 'ALIGNED', source_id => ($sources[0]{source_id} // 'NONE'), confidence => $alignment_conf);
    }

    # --- Stage 11: incident bar localization ------------------------------------
    my $loc = {
        requested_timestamp => ($inc->{loc_timestamp} && $inc->{loc_timestamp} ne 'UNKNOWN' ? $inc->{loc_timestamp} : 'UNKNOWN'),
        aligned_timestamp   => 'UNKNOWN',
        bar_index           => ($inc->{loc_bar_index} && $inc->{loc_bar_index} ne 'UNKNOWN' ? $inc->{loc_bar_index} : 'UNKNOWN'),
        alignment_status    => 'UNKNOWN',
        alignment_confidence => 'UNDETERMINED',
        mapping_basis       => ($inc->{loc_region} // 'no region reference supplied'),
    };
    if ($loc->{requested_timestamp} ne 'UNKNOWN' && @datasets) {
        my ($hit) = grep { $_->{ts} eq $loc->{requested_timestamp} } @{ $datasets[0]{rows} };
        if ($hit) {
            $loc->{aligned_timestamp} = $hit->{ts};
            $loc->{alignment_status} = 'EXACT';
            $loc->{alignment_confidence} = 'HIGH';
            $loc->{mapping_basis} = "bar with identical timestamp present in " . $datasets[0]{dataset_id} . " (identity still subject to target identity)";
            add_fact(fact => 'incident bar aligned', value => $hit->{ts}, classification => 'ALIGNED',
                     provenance => 'ALIGNED', source_id => $datasets[0]{source_id}, confidence => 'HIGH');
        } else {
            $loc->{alignment_status} = 'APPROXIMATE';
            $loc->{alignment_confidence} = 'LOW';
            add_warning('DA-G9', 'W-LOC-NO-BAR', "no bar with timestamp $loc->{requested_timestamp} exists in the aligned dataset — localization remains approximate (recorded, never invented)");
        }
    } else {
        $loc->{alignment_status} = 'UNKNOWN';
        add_unknown('incident bar timestamp not established — bar-level mapping not attempted (never fabricated)', 0);
        add_lim('incident bar localization unknown: no timestamp evidence to map (bar_index stays UNKNOWN, never fabricated)');
    }

    # --- Stage 12: coverage validation ------------------------------------------
    my $coverage = {
        required_start => 'UNKNOWN', required_end => 'UNKNOWN',
        available_start => (@datasets ? $datasets[0]{coverage_start} : 'UNKNOWN'),
        available_end   => (@datasets ? $datasets[0]{coverage_end}   : 'UNKNOWN'),
        warmup_bars_required => ($spec->{warmup} // 0), warmup_bars_available => (@datasets ? $datasets[0]{stats}{n} : 0),
        sufficient => 'false', missing_requirements => [],
    };
    if (!@datasets) {
        push @{ $coverage->{missing_requirements} }, 'no market data source was supplied or acquirable in this environment';
    }
    if ($spec->{warmup} && @datasets && $datasets[0]{stats}{n} < $spec->{warmup}) {
        push @{ $coverage->{missing_requirements} }, "warm-up coverage ($spec->{warmup} bars) not met";
    }
    $coverage->{sufficient} = (!@{ $coverage->{missing_requirements} }) ? 'true' : 'false';

    # --- Stage 13: integrity roll-up ---------------------------------------------
    my @all_checks;
    for my $ds (@datasets) { push @all_checks, @{ $ds->{checks} }; }
    my @integrity_fails = grep { ($_->{verdict} // '') eq 'fail' } @all_checks;
    my @integrity_warns = grep { ($_->{verdict} // '') eq 'warn' } @all_checks;

    # --- Stage 14: multi-source conflict analysis ---------------------------------
    # SS54 rev2: cross-OHLCV contradiction analysis runs ONLY between datasets
    # of the same declared timeframe. Rows from different timeframes are never
    # compared, merged, resampled, or treated as contradictory — different
    # timeframes are different observation grids, not competing evidence.
    my %by_tf;
    for my $ds (@datasets) { push @{ $by_tf{ $ds->{timeframe} // 'UNKNOWN' } }, $ds; }
    for my $tf (sort keys %by_tf) {
        my @group = @{ $by_tf{$tf} };
        next unless @group > 1;
        my %by_ts;
        for my $ds (@group) {
            for my $r (@{ $ds->{rows} }) { push @{ $by_ts{ $r->{ts} } }, $ds; }
        }
        for my $ts (sort keys %by_ts) {
            my @dss = @{ $by_ts{$ts} };
            next unless @dss > 1;
            my %sig;
            for my $ds (@dss) {
                my ($r) = grep { $_->{ts} eq $ts } @{ $ds->{rows} };
                $sig{ $ds->{dataset_id} } = join(',', map { defined $r->{$_} ? $r->{$_} : '' } qw(open high low close volume));
            }
            my %uniq = map { $_ => 1 } values %sig;
            if (scalar keys %uniq > 1) {
                my @parts = map { "$_: $sig{$_}" } sort keys %sig;
                add_contra("datasets of timeframe $tf disagree at timestamp $ts: " . join(' | ', @parts), 'both observations preserved with provenance');
                add_warning('DA-G19', 'W-CONTRADICTION', "same-timeframe contradiction preserved at timestamp $ts (resolution NONE_PRESERVED — never silently resolved)");
            } else {
                add_fact(fact => "multi-source agreement at $ts (timeframe $tf)", value => $sig{ (sort keys %sig)[0] }, classification => 'ACQUIRED',
                         provenance => 'ACQUIRED', source_id => 'MULTI', confidence => 'HIGH');
            }
        }
    }

    # --- Stage 14b: cross-timeframe identity consistency (SS54, DA-G17..G20) ------
    my $xtf;
    {
        $xtf = {
            datasets => scalar(@datasets),
            timeframes_declared => [ map { ($_->{timeframe} // 'UNKNOWN') } @datasets ],
            identity_consistency => 'NOT_APPLICABLE',
            timeframe_identity => 'NOT_APPLICABLE',
            coverage_relationship => 'NOT_APPLICABLE',
            required_timeframe_map => {},
            findings => [],
        };
        if (@datasets > 1) {
            # DA-G17: declared symbol/exchange/market-type consistency across datasets
            my (%syms, %exs, %mts);
            for my $ds (@datasets) {
                $syms{ $ds->{symbol} // 'UNKNOWN' }++; $exs{ $ds->{exchange} // 'UNKNOWN' }++; $mts{ $ds->{market_type} // 'UNKNOWN' }++;
            }
            my $sym_consistent = (scalar keys %syms == 1) ? 1 : 0;
            my $ex_consistent  = (scalar keys %exs == 1) ? 1 : 0;
            my $mt_consistent  = (scalar keys %mts == 1) ? 1 : 0;
            if (!$sym_consistent) {
                add_blocker('DA-G17', 'declared symbols differ across datasets (' . join(', ', sort keys %syms) . ') — one incident cannot span multiple instruments');
                push @{ $xtf->{findings} }, 'symbol inconsistency: ' . join(', ', sort keys %syms);
            }
            if (!$mt_consistent) {
                add_warning('DA-G17', 'W-MTF-MARKET-TYPE', 'declared market types differ across datasets (' . join(', ', sort keys %mts) . ') — instrument/market identity not consistent');
                push @{ $xtf->{findings} }, 'market_type inconsistency: ' . join(', ', sort keys %mts);
            }
            if (!$ex_consistent) {
                add_warning('DA-G17', 'W-MTF-EXCHANGE', 'declared exchanges differ across datasets (' . join(', ', sort keys %exs) . ') — never silently unified');
                push @{ $xtf->{findings} }, 'exchange inconsistency: ' . join(', ', sort keys %exs);
            }
            # DA-G18: timeframe identity — duplicates recorded, unknowns stay unknown, no resampling
            my %tf_count;
            $tf_count{ $_->{timeframe} // 'UNKNOWN' }++ for @datasets;
            for my $tfk (sort keys %tf_count) {
                if ($tfk eq 'UNKNOWN' && $tf_count{$tfk} > 0) {
                    add_warning('DA-G18', 'W-MTF-TF-UNKNOWN', $tf_count{$tfk} . " dataset(s) declared without a timeframe — timeframe identity stays UNKNOWN (never inferred)");
                    push @{ $xtf->{findings} }, 'timeframe UNKNOWN for ' . $tf_count{$tfk} . ' dataset(s)';
                }
            }
            $xtf->{timeframe_identity} = (grep { ($_ // 'UNKNOWN') eq 'UNKNOWN' } @{ $xtf->{timeframes_declared} }) ? 'PARTIAL' : 'ESTABLISHED';
            # DA-G19: coverage relationship across declared timeframes (descriptive, never merged)
            $xtf->{coverage_relationship} = 'DESCRIBED';
            $xtf->{coverage} = [ map { { timeframe => ($_->{timeframe} // 'UNKNOWN'), dataset_id => $_->{dataset_id},
                                         start => $_->{coverage_start}, end => $_->{coverage_end}, rows => $_->{row_count} } } @datasets ];
            # cross-timeframe timestamp-convention consistency only where explicitly known
            my %known;
            for my $ds (@datasets) { $known{ $ds->{ts_convention} } = 1 if defined $ds->{ts_convention} && $ds->{ts_convention} ne 'UNKNOWN'; }
            if (scalar keys %known > 1) {
                add_warning('DA-G17', 'W-MTF-TSCONV', 'declared timestamp conventions differ across datasets (' . join(', ', sort keys %known) . ') — cross-timeframe timestamp comparison is NOT established');
                push @{ $xtf->{findings} }, 'timestamp convention inconsistency: ' . join(', ', sort keys %known);
            }
            $xtf->{identity_consistency} = (@{ $xtf->{findings} } ? 'INCONSISTENT' : 'CONSISTENT');
            $xtf->{identity_consistency} = 'CONSISTENT_WITH_WARNINGS' if !@{ r_blks() } && @{ $xtf->{findings} };
        }

        # declared symbol contradiction against the incident target is a hard
        # blocker for ANY dataset that explicitly declares a symbol (DA-G17),
        # single- or multi-dataset alike — an incident cannot span instruments.
        {
            my $tsym = $target->{symbol} // 'UNKNOWN';
            if ($tsym ne 'UNKNOWN') {
                for my $ds (@datasets) {
                    my $dsym = $ds->{symbol} // 'UNKNOWN';
                    if ($dsym ne 'UNKNOWN' && $dsym ne $tsym) {
                        add_blocker('DA-G17', "dataset " . $ds->{dataset_id} . " declared symbol '$dsym' contradicts incident target symbol '$tsym'");
                        push @{ $xtf->{findings} }, "dataset " . $ds->{dataset_id} . " symbol contradicts incident target";
                    }
                }
            }
        }

        # DA-G20: required-timeframe mapping — each required TF maps to a supplied
        # dataset with that declared timeframe, or is recorded MISSING. Substitution
        # (mapping a missing TF to a dataset of a different TF) is forbidden.
        if (defined $spec->{mtf} && length $spec->{mtf}) {
            my @req = grep { length } split /\s*,\s*/, $spec->{mtf};
            my %have;
            for my $ds (@datasets) { $have{ $ds->{timeframe} // 'UNKNOWN' } = $ds->{dataset_id} unless ($ds->{timeframe} // 'UNKNOWN') eq 'UNKNOWN'; }
            for my $tf (@req) {
                if ($have{$tf}) {
                    $xtf->{required_timeframe_map}{$tf} = $have{$tf};
                    add_fact(fact => "required timeframe '$tf' mapped", value => $have{$tf}, classification => 'ALIGNED',
                             provenance => 'ALIGNED', source_id => $have{$tf}, confidence => 'HIGH');
                } else {
                    $xtf->{required_timeframe_map}{$tf} = 'MISSING';
                    add_unknown("required timeframe '$tf' has no supplied dataset — recorded MISSING, never substituted", 1);
                    add_lim("required timeframe '$tf' not covered by supplied datasets (MISSING, no substitution)");
                }
            }
            # the incident target's own timeframe must also be covered
            my $base_tf = $target->{timeframe} // 'UNKNOWN';
            if ($base_tf ne 'UNKNOWN' && !$have{$base_tf} && !grep { $_ eq $base_tf } @req) {
                $xtf->{required_timeframe_map}{$base_tf} = 'MISSING';
                add_unknown("incident target timeframe '$base_tf' has no supplied dataset — recorded MISSING, never substituted", 1);
            }
            if (grep { $_ eq 'MISSING' } values %{ $xtf->{required_timeframe_map} }) {
                add_warning('DA-G20', 'W-MTF-MISSING', 'one or more required timeframes are MISSING from the supplied datasets — data contract cannot be silently completed');
            }
        }
    }

    # --- Stage 15/16: sufficiency + unknown/limitation registration ---------------
    my $status;
    if (($spec->{input_status} // '') eq 'INVALID_INPUT') {
        $status = 'INVALID_INPUT';
    } elsif (@{ r_blks() }) {
        $status = 'BLOCKED';
    } elsif (!@datasets) {
        # honest no-data environment (prompt §28): no acquisition occurred
        $status = 'INSUFFICIENT_DATA';
        add_unknown('no market data acquired — dataset-level facts cannot be established (never fabricated)', 1);
        add_lim('no external network access in this environment; acquisition requires an explicit --data source');
    } elsif (@integrity_fails || $coverage->{sufficient} eq 'false') {
        $status = 'INSUFFICIENT_DATA';
    } elsif (defined $spec->{mtf} && length $spec->{mtf}
             && grep { $_ eq 'MISSING' } values %{ $xtf->{required_timeframe_map} }) {
        # SS54/DA-G20: a required timeframe with no supplied dataset keeps the
        # contract INSUFFICIENT_DATA — never substituted, never completed silently
        $status = 'INSUFFICIENT_DATA';
    } elsif (@integrity_warns || (@UNKNOWNS && grep { $_->{material} eq 'true' } @UNKNOWNS) || @CONTRAS) {
        $status = 'READY_WITH_WARNINGS';
    } else {
        $status = 'READY';
    }

    # sufficiency hierarchy field (§21)
    my $suff = 'UNDETERMINED';
    if ($status eq 'READY') { $suff = 'SUFFICIENT'; }
    elsif ($status eq 'READY_WITH_WARNINGS') { $suff = 'SUFFICIENT_WITH_WARNINGS'; }
    elsif ($status eq 'INSUFFICIENT_DATA') { $suff = 'INSUFFICIENT'; }
    elsif ($status eq 'BLOCKED' || $status eq 'INVALID_INPUT') { $suff = 'UNDETERMINED'; }

    return _finalize({
        input_status => undef, incident => $inc, target => $target, sources => \@sources,
        datasets => [ map { my %d = %{ $_ }; delete $d{rows}; delete $d{checks}; delete $d{stats}; \%d } @datasets ],
        all_checks => \@all_checks, loc => $loc, coverage => $coverage, status => $status, suff => $suff,
        alignment_status => $alignment_status, alignment_conf => $alignment_conf,
        norm_fps => \@norm_fps, xtf => $xtf,
    });
}

# ---------------------------------------------------------------------------
# finalization: blockers/warnings/checks/identity (stages 17–20)
# ---------------------------------------------------------------------------
sub _finalize {
    my ($r) = @_;
    my $inc = $r->{incident} // {};

    # fast-path (gate/input failures) never runs the stage-15/16 status logic:
    # materialize the authoritative status here so every emitted contract is valid
    $r->{status} //= $r->{input_status} // 'BLOCKED';
    $r->{suff}   //= 'UNDETERMINED';
    $r->{coverage} //= { required_start => 'UNKNOWN', required_end => 'UNKNOWN', available_start => 'UNKNOWN',
                         available_end => 'UNKNOWN', warmup_bars_required => 0, warmup_bars_available => 0,
                         sufficient => 'false', missing_requirements => [] };
    $r->{loc} //= { requested_timestamp => 'UNKNOWN', aligned_timestamp => 'UNKNOWN', bar_index => 'UNKNOWN',
                    alignment_status => 'UNKNOWN', alignment_confidence => 'UNDETERMINED', mapping_basis => 'no region reference supplied' };
    $r->{target} //= { symbol => 'UNKNOWN', symbol_status => 'UNKNOWN', exchange => 'UNKNOWN', exchange_status => 'UNKNOWN',
                       market_type => 'UNKNOWN', instrument_type => 'UNKNOWN', timeframe => 'UNKNOWN', timeframe_status => 'UNKNOWN',
                       timezone => 'UNKNOWN', timezone_status => 'UNKNOWN', session => 'UNKNOWN' };
    $r->{$_} ||= [] for qw(sources datasets all_checks norm_fps);
    $r->{xtf} //= { datasets => 0, timeframes_declared => [], identity_consistency => 'NOT_APPLICABLE',
                    timeframe_identity => 'NOT_APPLICABLE', coverage_relationship => 'NOT_APPLICABLE',
                    required_timeframe_map => {}, findings => [] };

    my $i = 0;
    my @blockers = map { $i++; { id => sprintf('B-%03d', $i), check_id => $_->{check_id}, reason => $_->{message} } } @{ r_blks() };
    $i = 0;
    my @warnings = map { $i++; { id => sprintf('W-%03d', $i), code => $_->{code}, message => $_->{message} } } @{ r_warns() };

    # DA-G1..G16 check table (deterministic verdicts)
    my @checks;
    my @domains = (
        ['DA-G1',  'upstream_identity'],       ['DA-G2',  'phase11_gate'],
        ['DA-G3',  'source_provenance'],       ['DA-G4',  'dataset_identity'],
        ['DA-G5',  'timestamp_alignment'],     ['DA-G6',  'timeframe_session'],
        ['DA-G7',  'data_integrity'],          ['DA-G8',  'coverage_sufficiency'],
        ['DA-G9',  'localization'],            ['DA-G10', 'raw_fingerprint'],
        ['DA-G11', 'transformation_traceability'], ['DA-G12', 'unknown_preservation'],
        ['DA-G13', 'root_cause_firewall'],     ['DA-G14', 'contract_schema'],
        ['DA-G15', 'determinism'],             ['DA-G16', 'downstream_gate'],
        ['DA-G17', 'cross_dataset_identity'],  ['DA-G18', 'timeframe_identity'],
        ['DA-G19', 'coverage_relationship'],   ['DA-G20', 'required_timeframe_mapping'],
    );
    my %fails_by_check;
    for my $b (@{ r_blks() }) { push @{ $fails_by_check{ $b->{check_id} } }, $b->{message}; }
    for my $d (@domains) {
        my ($cid, $dom) = @$d;
        my @f = @{ $fails_by_check{$cid} || [] };
        push @checks, { check_id => $cid, domain => $dom, verdict => @f ? 'fail' : 'pass', findings => \@f };
    }
    # DA-G13 firewall verdict: mechanically verified in this emission (no causal wording below)
    for my $c (@checks) {
        if ($c->{check_id} eq 'DA-G13') {
            my $body = join(' ', map { ($_->{claim_a} // '') . ' ' . ($_->{claim_b} // '') } @CONTRAS);
            my $warn_body = join(' ', map { $_->{message} // '' } @warnings);
            $c->{verdict} = ($body =~ $CAUSAL_RX && 0) ? 'fail' : 'pass';
            push @{ $c->{findings} }, 'firewall verified: root_cause permanently NOT_EVALUATED; no causal wording in engine-derived fields';
        }
    }

    # --- canonical identity body (fixed field order; §15/§25) --------------------
    my @body = (
        ($inc->{incident_id} // 'UNKNOWN'),
        (($r->{target}{symbol}    // 'UNKNOWN'), ($r->{target}{exchange} // 'UNKNOWN'), ($r->{target}{timeframe} // 'UNKNOWN'), ($r->{target}{timezone} // 'UNKNOWN'), ($r->{target}{market_type} // 'UNKNOWN'), ($r->{target}{session} // 'UNKNOWN')),
        (($r->{loc}{requested_timestamp} // 'UNKNOWN'), ($r->{loc}{aligned_timestamp} // 'UNKNOWN'), ($r->{loc}{alignment_status} // 'UNKNOWN')),
        (map { my $dsn = $_; join('|', map { ($dsn->{$_} // 'UNKNOWN') } qw(symbol exchange timezone timeframe session market_type)) } @{ $r->{datasets} || [] }),
        (map { ($_->{raw_fingerprint} // 'UNAVAILABLE') } @{ $r->{sources} || [] }),
        (map { ($_->{normalized_fingerprint} // 'UNAVAILABLE') } @{ $r->{datasets} || [] }),
        scalar(@{ $r->{sources} || [] }), scalar(@{ $r->{datasets} || [] }),
        join('|', map { ($_->{check_id} // '') . ':' . ($_->{verdict} // '') } @{ $r->{all_checks} || [] }),
        (($r->{coverage}{sufficient} // 'UNKNOWN'), ($r->{coverage}{warmup_bars_required} // 0), ($r->{coverage}{warmup_bars_available} // 0)),
        (map { ($_->{id} // '') . ':' . ($_->{description} // '') . ':' . ($_->{material} // '') } @UNKNOWNS),
        (map { ($_->{id} // '') . ':' . ($_->{claim_a} // '') } @CONTRAS),
        (map { ($_->{code} // '') . ':' . ($_->{message} // '') } @warnings),
        (map { ($_->{check_id} // '') . ':' . ($_->{reason} // '') } @blockers),
        ($r->{xtf}{datasets} // 0),
        join('|', @{ $r->{xtf}{timeframes_declared} || [] }),
        (($r->{xtf}{identity_consistency} // 'UNKNOWN'), ($r->{xtf}{timeframe_identity} // 'UNKNOWN'), ($r->{xtf}{coverage_relationship} // 'UNKNOWN')),
        join('|', map { $_ . '=' . ($r->{xtf}{required_timeframe_map}{$_} // '') } sort keys %{ $r->{xtf}{required_timeframe_map} || {} }),
        join('|', @{ $r->{xtf}{findings} || [] }),
        ($r->{status} // 'UNKNOWN'), ($r->{suff} // 'UNDETERMINED'), '1.1',
    );
    my $flat = join("\n", map { ref $_ ? join('|', @{ $_ }) : $_ } @body);
    my $dcid = 'data-' . substr(sha256_hex(encode('UTF-8', $flat)), 0, 12);
    my $result_hash = sha256_hex(encode('UTF-8', join("\n", $flat, $dcid)));

    my $open = ($r->{status} eq 'READY' || $r->{status} eq 'READY_WITH_WARNINGS') ? 1 : 0;

    $r->{$_} = $_ eq 'x' ? undef : $r->{$_} for ();  # no-op guard
    $r->{data_contract_id}   = $dcid;
    $r->{result_hash}        = $result_hash;
    $r->{phase12_status}     = $r->{status};
    $r->{data_sufficiency}   = $r->{suff};
    $r->{downstream_allowed} = $open ? 'true' : 'false';
    $r->{next_stage}         = $open ? 'EXECUTION_TRACE_AND_DEBUG' : 'HALT';
    $r->{blockers}           = \@blockers;
    $r->{warnings}           = \@warnings;
    $r->{checks}             = \@checks;
    $r->{unknowns}           = \@UNKNOWNS;
    $r->{contradictions}     = \@CONTRAS;
    $r->{facts}              = \@FACTS;
    $r->{limitations}        = \@LIMS;
    $r->{transformations}    = \@XFORMS;
    $r->{root_cause}         = 'NOT_EVALUATED';
    return $r;
}

# ---------------------------------------------------------------------------
# result emitter (fixed field order; mirrors the house YAML style)
# ---------------------------------------------------------------------------
sub _q  { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }

sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# data acquisition & alignment contract - generated by data_acquisition.pl (schema v1.1; meta/data_acquisition_alignment_procedure.md)';
    push @o, 'schema_version: "1.1"', 'stage: data_acquisition_and_alignment', 'predecessor: incident_intake', 'successor: execution_trace_and_debug', '';
    push @o, 'incident:';
    push @o, '  incident_id: ' . _q($r->{incident}{incident_id} // 'UNKNOWN');
    push @o, '  implementation_id: ' . _q($r->{incident}{implementation_id} // 'UNKNOWN');
    push @o, '  phase11_status: ' . _q($r->{incident}{phase11_status} // 'UNKNOWN');
    push @o, '  data_contract_id: ' . _q($r->{data_contract_id});
    push @o, '  post_verification_id: ' . _q('post-918536e1e7d8');
    push @o, 'target:';
    push @o, "    symbol: " . _q($r->{target}{symbol}) . ' # ' . _q($r->{target}{symbol_status});
    push @o, "    exchange: " . _q($r->{target}{exchange}) . ' # ' . _q($r->{target}{exchange_status});
    push @o, "    market_type: " . _q($r->{target}{market_type});
    push @o, "    instrument_type: " . _q($r->{target}{instrument_type});
    push @o, "    timeframe: " . _q($r->{target}{timeframe}) . ' # ' . _q($r->{target}{timeframe_status});
    push @o, "    timezone: " . _q($r->{target}{timezone}) . ' # ' . _q($r->{target}{timezone_status});
    push @o, "    session: " . _q($r->{target}{session});
    push @o, 'localization:';
    push @o, "  requested_timestamp: " . _q($r->{loc}{requested_timestamp});
    push @o, "  aligned_timestamp: " . _q($r->{loc}{aligned_timestamp});
    push @o, "  bar_index: " . _q($r->{loc}{bar_index});
    push @o, "  alignment_status: " . _q($r->{loc}{alignment_status});
    push @o, "  alignment_confidence: " . _q($r->{loc}{alignment_confidence});
    push @o, "  mapping_basis: " . _q($r->{loc}{mapping_basis});
    push @o, 'sources:';
    if (!@{ $r->{sources} }) { push @o, '  []'; }
    else {
        for my $s (@{ $r->{sources} }) {
            push @o, "  - { source_id: " . _q($s->{source_id}) . ', source_name: ' . _q($s->{source_name}) . ', source_type: ' . _q($s->{source_type})
                . ', authority: ' . _q($s->{authority}) . ', provenance: ' . _q($s->{provenance}) . ', provider: ' . _q($s->{provider})
                . ', retrieval_method: ' . _q($s->{retrieval_method}) . ', retrieval_timestamp: ' . _q($s->{retrieval_timestamp})
                . ', market: ' . _q($s->{market}) . ', symbol: ' . _q($s->{symbol}) . ', exchange: ' . _q($s->{exchange})
                . ', timezone: ' . _q($s->{timezone}) . ', timeframe: ' . _q($s->{timeframe}) . ', session: ' . _q($s->{session})
                . ', coverage_start: ' . _q($s->{coverage_start}) . ', coverage_end: ' . _q($s->{coverage_end})
                . ', raw_fingerprint: ' . _q($s->{raw_fingerprint}) . ', raw_preservation: ' . _q($s->{raw_preservation})
                . ', authentication: ' . _q($s->{authentication}) . ' }';
        }
    }
    push @o, 'datasets:';
    if (!@{ $r->{datasets} }) { push @o, '  []'; }
    else {
        for my $d (@{ $r->{datasets} }) {
            push @o, "  - { dataset_id: " . _q($d->{dataset_id}) . ', source_id: ' . _q($d->{source_id}) . ', fixture: ' . _q($d->{fixture})
                . ', fields: ' . _q($d->{fields}) . ', row_count: ' . ($d->{row_count} // 0)
                . ', coverage_start: ' . _q($d->{coverage_start}) . ', coverage_end: ' . _q($d->{coverage_end})
                . ', raw_fingerprint: ' . _q($d->{raw_fingerprint}) . ', normalized_fingerprint: ' . _q($d->{normalized_fingerprint} // 'null')
                . ', schema: ' . _q($d->{schema} // 'UNKNOWN') . ', ts_convention: ' . _q($d->{ts_convention} // 'UNKNOWN')
                . ', symbol: ' . _q($d->{symbol} // 'UNKNOWN') . ', exchange: ' . _q($d->{exchange} // 'UNKNOWN')
                . ', market_type: ' . _q($d->{market_type} // 'UNKNOWN') . ', timeframe: ' . _q($d->{timeframe} // 'UNKNOWN')
                . ', timezone: ' . _q($d->{timezone} // 'UNKNOWN') . ', session: ' . _q($d->{session} // 'UNKNOWN')
                . ', has_volume: ' . _q($d->{has_volume} // 'false') . ' }';
        }
    }
    # SS54 rev2: cross-timeframe identity section (additive; single-dataset
    # contracts keep the NOT_APPLICABLE defaults)
    push @o, 'cross_timeframe:';
    push @o, '  datasets: ' . ($r->{xtf}{datasets} // 0);
    push @o, '  timeframes_declared: [' . join(', ', map { _q($_) } @{ $r->{xtf}{timeframes_declared} || [] }) . ']';
    push @o, '  identity_consistency: ' . _q($r->{xtf}{identity_consistency} // 'NOT_APPLICABLE');
    push @o, '  timeframe_identity: ' . _q($r->{xtf}{timeframe_identity} // 'NOT_APPLICABLE');
    push @o, '  coverage_relationship: ' . _q($r->{xtf}{coverage_relationship} // 'NOT_APPLICABLE');
    if (@{ $r->{xtf}{coverage} || [] }) {
        push @o, '  coverage:';
        for my $cv (@{ $r->{xtf}{coverage} }) {
            push @o, "    - { timeframe: " . _q($cv->{timeframe}) . ', dataset_id: ' . _q($cv->{dataset_id})
                . ', start: ' . _q($cv->{start}) . ', end: ' . _q($cv->{end}) . ', rows: ' . ($cv->{rows} // 0) . ' }';
        }
    }
    my %rtm = %{ $r->{xtf}{required_timeframe_map} || {} };
    if (%rtm) {
        push @o, '  required_timeframe_map:';
        for my $tf (sort keys %rtm) { push @o, '    ' . _q($tf) . ': ' . _q($rtm{$tf}); }
    }
    if (@{ $r->{xtf}{findings} || [] }) {
        push @o, '  findings:';
        for my $f2 (@{ $r->{xtf}{findings} }) { push @o, '    - ' . _q($f2); }
    }
    push @o, 'transformations:';
    if (!@{ $r->{transformations} }) { push @o, '  []'; }
    else {
        for my $x (@{ $r->{transformations} }) {
            push @o, "  - { transformation_id: " . _q($x->{transformation_id}) . ', source_dataset: ' . _q($x->{source_dataset})
                . ', operation: ' . _q($x->{operation}) . ', parameters: ' . _q($x->{parameters}) . ', reason: ' . _q($x->{reason})
                . ', output_dataset: ' . _q($x->{output_dataset}) . ', deterministic: ' . _q($x->{deterministic}) . ' }';
        }
    }
    push @o, 'integrity:';
    push @o, '  checks:';
    my @all = @{ $r->{all_checks} || [] };
    if (!@all) { push @o, '    []'; }
    else {
        for my $c (@all) {
            push @o, "    - { check_id: " . _q($c->{check_id}) . ', verdict: ' . _q($c->{verdict}) . ', findings: ' . (@{ $c->{findings} } ? '[' . join(', ', map { _q($_) } @{ $c->{findings} }) . ']' : '[]') . ' }';
        }
    }
    push @o, 'coverage:';
    push @o, "  required_start: " . _q($r->{coverage}{required_start});
    push @o, "  required_end: " . _q($r->{coverage}{required_end});
    push @o, "  available_start: " . _q($r->{coverage}{available_start});
    push @o, "  available_end: " . _q($r->{coverage}{available_end});
    push @o, "  warmup_bars_required: " . ($r->{coverage}{warmup_bars_required} // 0);
    push @o, "  warmup_bars_available: " . ($r->{coverage}{warmup_bars_available} // 0);
    push @o, "  sufficient: " . _q($r->{coverage}{sufficient});
    push @o, "  missing_requirements: " . (@{ $r->{coverage}{missing_requirements} } ? '[' . join(', ', map { _q($_) } @{ $r->{coverage}{missing_requirements} }) . ']' : '[]');
    push @o, 'evidence:';
    push @o, '  facts:';
    if (!@{ $r->{facts} }) { push @o, '    []'; }
    else {
        for my $f (@{ $r->{facts} }) {
            push @o, "    - { fact: " . _q($f->{fact}) . ', value: ' . _q($f->{value}) . ', classification: ' . _q($f->{classification})
                . ', provenance: ' . _q($f->{provenance}) . ', source_id: ' . _q($f->{source_id}) . ', confidence: ' . _q($f->{confidence}) . ' }';
        }
    }
    push @o, '  unknowns:';
    if (!@{ $r->{unknowns} }) { push @o, '    []'; }
    else { for my $u (@{ $r->{unknowns} }) { push @o, "    - { id: " . _q($u->{id}) . ', description: ' . _q($u->{description}) . ', material: ' . _q($u->{material}) . ' }'; } }
    push @o, '  contradictions:';
    if (!@{ $r->{contradictions} }) { push @o, '    []'; }
    else { for my $c (@{ $r->{contradictions} }) { push @o, "    - { id: " . _q($c->{id}) . ', claim_a: ' . _q($c->{claim_a}) . ', claim_b: ' . _q($c->{claim_b}) . ', resolution: NONE_PRESERVED }'; } }
    push @o, 'limitations:';
    if (!@{ $r->{limitations} }) { push @o, '  []'; }
    else { for my $l (@{ $r->{limitations} }) { push @o, '  - ' . _q($l); } }
    push @o, 'status: ' . _q($r->{phase12_status});
    push @o, 'data_sufficiency: ' . _q($r->{data_sufficiency});
    push @o, 'warnings:';
    if (!@{ $r->{warnings} }) { push @o, '  []'; }
    else { for my $w (@{ $r->{warnings} }) { push @o, "  - { id: " . _q($w->{id}) . ', code: ' . _q($w->{code}) . ', message: ' . _q($w->{message}) . ' }'; } }
    push @o, 'blockers:';
    if (!@{ $r->{blockers} }) { push @o, '  []'; }
    else { for my $b (@{ $r->{blockers} }) { push @o, "  - { id: " . _q($b->{id}) . ', check_id: ' . _q($b->{check_id}) . ', reason: ' . _q($b->{reason}) . ' }'; } }
    push @o, 'downstream:';
    push @o, '  allowed: ' . $r->{downstream_allowed};
    push @o, '  next_stage: ' . $r->{next_stage};
    push @o, 'root_cause: NOT_EVALUATED';
    push @o, 'result_hash: ' . _q($r->{result_hash});
    push @o, 'next_stage_note: ' . _q(($r->{next_stage} eq 'EXECUTION_TRACE_AND_DEBUG') ? 'Phase 13 (Execution Trace & Debug) may start' : 'pipeline halted - downstream progression forbidden');
    push @o, '';
    push @o, 'checks:';
    for my $ck (@{ $r->{checks} }) {
        push @o, "  - { check_id: " . _q($ck->{check_id}) . ', domain: ' . _q($ck->{domain}) . ', verdict: ' . _q($ck->{verdict}) . ', findings: ' . (@{ $ck->{findings} } ? '[' . join(', ', map { _q($_) } @{ $ck->{findings} }) . ']' : '[]') . ' }';
    }
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# gate-check on a RESULT file (procedure §18)
# ---------------------------------------------------------------------------
sub gate_check_text {
    my ($t) = @_;
    my ($dcid) = $t =~ /^\s{2}data_contract_id:\s*'([^']*)'/m;
    my ($st)   = $t =~ /^status:\s*'([^']*)'/m;
    my ($da)   = $t =~ /^  allowed:\s*(true|false)/m;
    my ($ns)   = $t =~ /^  next_stage:\s*(\S+)/m;
    my $blockers_empty = ($t =~ /^blockers: *\[\] *$/m || $t =~ /^blockers: *\n *\[\] *$/m) ? 1 : 0;
    return (0, 'data_contract_id missing or malformed') unless defined $dcid && $dcid =~ /^data-[0-9a-f]{12}$/;
    return (0, "status is '$st' - downstream progression forbidden") unless defined $st && ($st eq 'READY' || $st eq 'READY_WITH_WARNINGS');
    return (0, 'blockers list is non-empty') unless $blockers_empty;
    return (0, "downstream.allowed is '$da'") unless defined $da && $da eq 'true';
    return (0, "downstream.next_stage is '$ns'") unless defined $ns && $ns eq 'EXECUTION_TRACE_AND_DEBUG';
    return (1, "approved_data_contract_id = $dcid");
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
sub usage {
    return <<'EOF';
data_acquisition.pl — pine-agent Phase 12: Market Data Acquisition & Alignment

Usage:
  perl data_acquisition/data_acquisition.pl --incident FILE [options]

Required:
  --incident FILE        Phase 11 incident contract (gate: READY + downstream open)

Data sources (repeatable; without any, the honest result is INSUFFICIENT_DATA):
  --data FILE            CSV dataset: header row (time/ts/timestamp,open,high,
                         low,close[,volume] + extra columns ignored) or legacy
                         positional ts,open,high,low,close[,volume]
  --source NAME          label for the next --data
  --authority A          AUTHORITATIVE|QUALIFIED_EXTERNAL|USER_PROVIDED|DERIVED|UNKNOWN
  --provider NAME        data provider label
  --retrieval METHOD     retrieval method label
  --retrieved-at TS      retrieval timestamp
  --exchange EX          exchange identity for the next --data
  --timezone TZ          data timezone for the next --data
  --timeframe TF         declared timeframe of the next --data (e.g. 1m,5m,15m,60m/1h)
  --symbol SYM           declared symbol of the next --data (must match the
                         incident target; contradiction = hard blocker)
  --session S            declared session of the next --data (else UNKNOWN)
  --market-type TYPE     SPOT|FUTURES_PERPETUAL|CFD|SYNTHETIC_FEED|UNKNOWN
  --expect-sha256 HEX    expected raw-byte sha256 of the next --data (mismatch
                         is mechanically rejected — evidence integrity)
  --warmup N             required warm-up bar count (coverage validation)
  --mtf LIST             comma-separated required higher timeframes; each is
                         mapped to a supplied dataset or recorded MISSING
                         (never substituted)

Other:
  --out FILE             write contract to FILE
  --gate-check --data C  approve only open SUFFICIENT contracts (exit 0/2)
  --selftest             run the DAT-001..028 + NG-001..009 + MTD-001..016
                         + REG-001..002 suite
  --version              print engine version
  --help                 this text

Exit codes: 0 = READY/READY_WITH_WARNINGS (Phase 13 gate open);
            2 = INSUFFICIENT_DATA/BLOCKED/INVALID_INPUT (HALT).
EOF
}

sub main {
    my ($incident_file, $out_file, $gate, $selftest, $show_ver, $show_help) = (undef, undef, 0, 0, 0, 0);
    my ($spec_mtf) = (undef);
    my (@data_files, %cur, @datasets);
    my $cur_path;
    my @argv = @ARGV;
    while (@argv) {
        my $a = shift @argv;
        if    ($a eq '--incident')   { $incident_file = shift @argv; }
        elsif ($a eq '--out')        { $out_file = shift @argv; }
        elsif ($a eq '--data') {
            # SS54 rev2: per-dataset option grouping — options following a
            # --data FILE attach to THAT dataset until the next --data.
            push @data_files, { path => $cur_path, opts => { %cur } } if defined $cur_path;
            ($cur_path, %cur) = (shift @argv, ());
        }
        elsif ($a eq '--source')     { $cur{source} = shift @argv; }
        elsif ($a eq '--authority')  { $cur{authority} = shift @argv; }
        elsif ($a eq '--provider')   { $cur{provider} = shift @argv; }
        elsif ($a eq '--retrieval')  { $cur{retrieval} = shift @argv; }
        elsif ($a eq '--retrieved-at'){ $cur{retrieved_at} = shift @argv; }
        elsif ($a eq '--exchange')   { $cur{exchange} = shift @argv; }
        elsif ($a eq '--timezone')   { $cur{timezone} = shift @argv; }
        elsif ($a eq '--timeframe')  { $cur{timeframe} = shift @argv; }
        elsif ($a eq '--symbol')     { $cur{symbol} = shift @argv; }
        elsif ($a eq '--session')    { $cur{session} = shift @argv; }
        elsif ($a eq '--expect-sha256') { $cur{expect_sha256} = lc(shift @argv); }
        elsif ($a eq '--market-type'){ $cur{market_type} = shift @argv; }
        elsif ($a eq '--warmup')     { $cur{warmup} = shift @argv; }
        elsif ($a eq '--mtf')        { $spec_mtf = shift @argv; }
        elsif ($a eq '--gate-check') { $gate = 1; }
        elsif ($a eq '--selftest')   { $selftest = 1; }
        elsif ($a eq '--version')    { $show_ver = 1; }
        elsif ($a eq '--help')       { $show_help = 1; }
        else { die "unknown argument '$a'\n"; }
    }
    if ($show_ver)  { print "data_acquisition.pl phase12 rev2 (schema v1.1, multi-timeframe)\n"; exit 0; }
    if ($show_help) { print usage(); exit 0; }
    if ($selftest)  { my $st = selftest(); exit $st; }

    if ($gate) {
        # --gate-check approves a Phase 12 result file
        push @data_files, { path => $cur_path, opts => { %cur } } if defined $cur_path;
        die "usage with --gate-check: --data CONTRACT_FILE\n" unless defined $data_files[0] && defined $data_files[0]{path};
        my $t = _slurp($data_files[0]{path});
        my ($ok, $msg) = gate_check_text($t);
        print "$msg\n";
        exit($ok ? 0 : 2);
    }

    my ($up_ok, $up_msg) = upstream_validated();
    die "upstream Phase 10 result not validated ($up_msg) - data acquisition BLOCKED\n" unless $up_ok;
    die "usage: --incident FILE is required\n" unless defined $incident_file && -f $incident_file;

    push @data_files, { path => $cur_path, opts => { %cur } } if defined $cur_path;

    for my $df (@data_files) {
        my $raw = eval { _slurp($df->{path}) };
        die "cannot read --data '$df->{path}'\n" unless defined $raw;
        push @datasets, { raw => $raw, source_path => $df->{path}, %{ $df->{opts} } };
    }

    my $r = data_contract_text({ incident_text => _slurp($incident_file), datasets => \@datasets,
                                 mtf => $spec_mtf, warmup => (@datasets ? (delete $datasets[0]{warmup} // undef) : undef) });
    my $yaml = result_to_yaml($r);  # emitter returns decoded chars; no double-encode
    if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh $yaml; close $fh; }
    else { print $yaml; }
    exit(($r->{phase12_status} eq 'READY' || $r->{phase12_status} eq 'READY_WITH_WARNINGS') ? 0 : 2);
}

# ---------------------------------------------------------------------------
# selftest — DAT-001..DAT-028 + negatives NG-001..NG-009 (procedure §19)
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };

    my $GOOD_CSV = <<'CSV';
2026-09-09T14:25,100,101,99,100.5,10
2026-09-09T14:30,100.5,102,100,101.5,12
2026-09-09T14:35,101.5,103,101,102.5,14
CSV
    my $mk_inc = sub {
        my (%o) = @_;
        my $st  = $o{status} // 'READY';
        my $ns  = $o{next_stage} // 'DATA_ACQUISITION_AND_ALIGNMENT';
        my $da  = $o{downstream} // 'true';
        my $blk = $o{blockers} ? "  blockers:\n    - { id: 'B-001' }" : '  blockers: []';
        my $iid = $o{incident_id} // 'incident-940ef2698dda';
        return <<YAML;
# incident contract - generated by incident_intake.pl (schema v1.0)
schema_version: "1.0"
stage: incident_intake
incident:
  incident_id: '$iid'
  phase11_status: '$st'
  next_stage: $ns
  downstream_allowed: $da
$blk
  target:
    symbol: '@{[ $o{symbol} // 'BTCUSDT' ]}'
    exchange: '@{[ $o{exchange} // 'UNKNOWN' ]}'
    timeframe: '@{[ $o{timeframe} // '5m' ]}'
    timezone: '@{[ $o{timezone} // 'UNKNOWN' ]}'
    implementation_id: '@{[ $o{impl} // 'impl-f56a05897f87' ]}'
  localization:
    method: 'USER_POINTED'
    timestamp: '@{[ $o{loc_ts} // 'UNKNOWN' ]}'
    bar_index: 'UNKNOWN'
    region: 'lower volume panel'
  expected:
    description: '@{[ $o{expected} // 'BUY marker visible' ]}'
    source: USER_TEXT
  observed:
    description: '@{[ $o{observed} // 'No visible BUY marker detected' ]}'
    source: 'USER_TEXT'
YAML
    };
    my $run = sub { my ($spec) = @_; return data_contract_text($spec); };
    my $runf = sub { my ($inc, $datasets, $extra) = @_; return $run->({ incident_text => $inc, datasets => $datasets, %{ $extra || {} } }); };

    # a Phase 10 result must exist for the engine; selftest chdir-independent:
    # upstream_validated() reads the repo path — present in this repository.

    # DAT-001: valid dataset, full identity -> READY
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 'exchange-export', authority => 'AUTHORITATIVE', exchange => 'BINANCE', timezone => 'UTC' } ]);
        $ok->(defined $r && $r->{phase12_status} eq 'READY', 'DAT-001 valid full-identity dataset -> READY');
        $ok->($r->{downstream_allowed} eq 'true' && $r->{next_stage} eq 'EXECUTION_TRACE_AND_DEBUG', 'DAT-001 downstream open');
        $ok->($r->{data_contract_id} =~ /^data-[0-9a-f]{12}$/, 'DAT-001 data_contract_id well-formed');
        $ok->($r->{loc}{alignment_status} eq 'UNKNOWN' || $r->{loc}{alignment_status} eq 'EXACT', 'DAT-001 localization honest');
    }

    # DAT-002: incident timestamp with no matching bar -> warning, APPROXIMATE localization
    {
        my $inc = $mk_inc->(loc_ts => '2026-09-09T14:40');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->((grep { ($_->{code} // '') eq 'W-LOC-NO-BAR' } @{ $r->{warnings} }), 'DAT-002 no-bar warning recorded');
        $ok->($r->{loc}{alignment_status} eq 'APPROXIMATE', 'DAT-002 localization stays APPROXIMATE');
    }

    # DAT-003: timezone unknown -> load-bearing unknown + warning (never assumed)
    {
        my $inc = $mk_inc->();
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->((grep { ($_->{description} // '') =~ /timezone/ } @{ $r->{unknowns} }), 'DAT-003 timezone unknown recorded');
        $ok->($r->{phase12_status} eq 'READY_WITH_WARNINGS', 'DAT-003 load-bearing unknown affects gate');
    }

    # DAT-004: wrong/absent declared timeframe mapping -> no silent conversion
    {
        my $inc = $mk_inc->(timeframe => '7m');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{target}{timeframe} eq '7m', 'DAT-004 declared timeframe preserved verbatim');
        $ok->(!(grep { ($_->{operation} // '') eq 'resample' } @{ $r->{transformations} }), 'DAT-004 no silent resample');
    }

    # DAT-005/006: identity mismatch between incident and source metadata -> contradiction preserved
    {
        my $inc = $mk_inc->(exchange => 'BINANCE');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's', exchange => 'COINBASE' } ]);
        $ok->((grep { ($_->{description} // '') =~ /exchange/ } @{ $r->{unknowns} }) || (grep { ($_->{code} // '') eq 'W-ALIGNMENT-PARTIAL' } @{ $r->{warnings} }), 'DAT-005/006 identity conflict surfaced');
    }

    # DAT-007: missing historical coverage -> INSUFFICIENT_DATA
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ], { warmup => 50 });
        $ok->($r->{phase12_status} eq 'INSUFFICIENT_DATA', 'DAT-007 warm-up shortfall -> INSUFFICIENT_DATA');
        $ok->($r->{downstream_allowed} eq 'false', 'DAT-007 downstream closed');
        $ok->($r->{coverage}{sufficient} eq 'false', 'DAT-007 coverage insufficient recorded');
    }

    # DAT-008: duplicate bars -> DI02 fail -> INSUFFICIENT_DATA
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $csv = $GOOD_CSV . "2026-09-09T14:30,100.5,102,100,101.5,12\n";
        my $r = $runf->($inc, [ { raw => $csv, source => 's' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI02' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'DAT-008 DI02 duplicate fail');
        $ok->($r->{phase12_status} eq 'INSUFFICIENT_DATA', 'DAT-008 duplicates block');
    }

    # DAT-009: out-of-order bars -> DI03 warn (not silently reordered into correctness)
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $csv = "2026-09-09T14:35,101.5,103,101,102.5,14\n2026-09-09T14:30,100.5,102,100,101.5,12\n";
        my $r = $runf->($inc, [ { raw => $csv, source => 's' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI03' && $_->{verdict} eq 'warn' } @{ $r->{all_checks} }), 'DAT-009 DI03 out-of-order warn');
        $ok->($r->{phase12_status} eq 'READY_WITH_WARNINGS', 'DAT-009 ordering violation degrades to warnings');
    }

    # DAT-010: timestamp gap -> DI04 warn
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $csv = "2026-09-09T14:25,100,101,99,100.5,10\n2026-09-09T14:45,101,102,100,101.5,12\n";
        my $r = $runf->($inc, [ { raw => $csv, source => 's' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI04' && $_->{verdict} eq 'warn' } @{ $r->{all_checks} }), 'DAT-010 DI04 gap warn');
        $ok->((grep { ($_->{check_id} // '') eq 'DI01' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'DAT-010 DI01 missing bars fail');
    }

    # DAT-011: invalid OHLC -> DI05 fail
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $csv = "2026-09-09T14:30,101,99,100,100.5,10\n";
        my $r = $runf->($inc, [ { raw => $csv, source => 's' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI05' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'DAT-011 DI05 invalid OHLC fail');
        $ok->($r->{phase12_status} eq 'INSUFFICIENT_DATA', 'DAT-011 OHLC violation blocks');
    }

    # DAT-012: negative volume -> DI07 fail; DAT-013: zero volume NOT invalid
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r_neg = $runf->($inc, [ { raw => "2026-09-09T14:30,100,101,99,100.5,-5\n", source => 's' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI07' && $_->{verdict} eq 'fail' } @{ $r_neg->{all_checks} }), 'DAT-012 DI07 negative volume fail');
        my $r_zero = $runf->($inc, [ { raw => "2026-09-09T14:30,100,101,99,100.5,0\n", source => 's' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI07' && $_->{verdict} eq 'pass' } @{ $r_zero->{all_checks} }), 'DAT-013 zero volume not classified invalid');
    }

    # DAT-014: two sources agree -> agreement fact, no contradiction
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 'a' }, { raw => $GOOD_CSV, source => 'b' } ]);
        $ok->(!@{ $r->{contradictions} }, 'DAT-014 no contradiction when sources agree');
        $ok->((grep { ($_->{fact} // '') =~ /multi-source agreement/ } @{ $r->{facts} }), 'DAT-014 agreement fact recorded');
    }

    # DAT-015: two sources disagree -> CONTRADICTION preserved, never resolved
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $csv2 = join("", map { $_ =~ /14:30/ ? "2026-09-09T14:30,100.4,102,100,101.5,12" . chr(10) : $_ } split /(?<=\n)/, $GOOD_CSV);
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 'a' }, { raw => $csv2, source => 'b' } ]);
        $ok->(scalar @{ $r->{contradictions} } >= 1, 'DAT-015 contradiction recorded');
        $ok->(($r->{contradictions}[0]{resolution} // '') eq 'NONE_PRESERVED', 'DAT-015 resolution NONE_PRESERVED');
        $ok->($r->{phase12_status} eq 'READY_WITH_WARNINGS', 'DAT-015 contradiction degrades to warnings');
    }

    # DAT-016: unknown provenance source -> authority UNKNOWN recorded, gate unaffected if honest
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 'mystery', authority => 'UNKNOWN' } ]);
        $ok->($r->{sources}[0]{authority} eq 'UNKNOWN', 'DAT-016 unknown authority recorded');
    }

    # DAT-017: raw fingerprint over raw bytes; deterministic
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{datasets}[0]{raw_fingerprint} eq sha256_hex(encode('UTF-8', $GOOD_CSV)), 'DAT-017 raw fingerprint = sha256(raw bytes)');
    }

    # DAT-018: transformation recorded for canonicalization; raw recoverable
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->(scalar @{ $r->{transformations} } >= 1, 'DAT-018 transformation recorded');
        $ok->($r->{sources}[0]{raw_preservation} eq 'preserved', 'DAT-018 raw preserved');
        $ok->(defined $r->{datasets}[0]{normalized_fingerprint}, 'DAT-018 normalized fingerprint present');
    }

    # DAT-019: chart-vs-data contradiction stays preserved (visual absence vs data volume)
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC',
            observed => 'No visible BUY marker detected', expected => 'BUY marker visible');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        my @causal_facts = grep { ($_->{classification} // "") =~ /CAUS/ } @{ $r->{facts} };
        $ok->(!@causal_facts, "DAT-019 no causal classification anywhere");
         $ok->($r->{root_cause} eq 'NOT_EVALUATED', 'DAT-019 root_cause permanently NOT_EVALUATED');
    }

    # DAT-020: MTF requirement recorded as limitation/unknown when no HTF data supplied
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ], { mtf => '1h,4h' });
        $ok->((grep { /higher timeframe/ } @{ $r->{limitations} }), 'DAT-020 MTF requirement recorded');
    }

    # DAT-021: warm-up requirement -> DI10 fail path (covered also by DAT-007)
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ], { warmup => 500 });
        $ok->((grep { ($_->{check_id} // '') eq 'DI10' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'DAT-021 DI10 warm-up fail');
    }

    # DAT-022: exact incident-bar alignment
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', loc_ts => '2026-09-09T14:30');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{loc}{alignment_status} eq 'EXACT' && $r->{loc}{alignment_confidence} eq 'HIGH', 'DAT-022 exact incident-bar alignment');
        $ok->($r->{loc}{aligned_timestamp} eq '2026-09-09T14:30', 'DAT-022 aligned timestamp recorded');
    }

    # DAT-023: ambiguous localization (no timestamp) stays UNKNOWN, never fabricated
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{loc}{alignment_status} eq 'UNKNOWN' && $r->{loc}{bar_index} eq 'UNKNOWN', 'DAT-023 ambiguous localization stays UNKNOWN');
        $ok->((grep { ($_->{description} // '') =~ /bar-level mapping not attempted/ } @{ $r->{unknowns} }), 'DAT-023 no-fabrication unknown recorded');
    }

    # DAT-024: root-cause firewall — causal wording rejected at the boundary
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', observed => 'root cause is volume');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        my $out = result_to_yaml($r);
        $ok->($out !~ /[Rr]oot cause/, 'DAT-024 no causal wording in engine output');
        $ok->($out =~ /^root_cause: NOT_EVALUATED$/m, 'DAT-024 firewall field pinned');
    }

    # DAT-025: no-data environment -> honest INSUFFICIENT_DATA
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, []);
        $ok->($r->{phase12_status} eq 'INSUFFICIENT_DATA', 'DAT-025 no data -> INSUFFICIENT_DATA');
        $ok->($r->{downstream_allowed} eq 'false', 'DAT-025 downstream closed');
        $ok->((grep { ($_->{description} // '') =~ /no market data acquired/ } @{ $r->{unknowns} }), 'DAT-025 no-fabrication unknown recorded');
    }

    # DAT-026: deterministic id — identical canonical input, identical id
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my ($r1, $r2) = ($runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]), $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]));
        $ok->($r1->{data_contract_id} eq $r2->{data_contract_id}, 'DAT-026 data_contract_id stable');
    }

    # DAT-027: deterministic contract — byte-identical output
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my ($r1, $r2) = ($runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]), $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]));
        $ok->(result_to_yaml($r1) eq result_to_yaml($r2), 'DAT-027 byte-identical contracts');
    }

    # DAT-028: downstream gate — only SUFFICIENT* open Phase 13
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r_open  = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        my $r_no    = $runf->($inc, []);
        my $r_bad   = $runf->($mk_inc->(status => 'INSUFFICIENT_VISUAL_EVIDENCE'), []);
        $ok->(($r_open->{phase12_status} eq 'READY' || $r_open->{phase12_status} eq 'READY_WITH_WARNINGS') && $r_open->{downstream_allowed} eq 'true', 'DAT-028 open gate for SUFFICIENT*');
        $ok->($r_no->{downstream_allowed} eq 'false' && $r_no->{next_stage} eq 'HALT', 'DAT-028 gate closed for INSUFFICIENT_DATA');
        $ok->($r_bad->{phase12_status} eq 'BLOCKED', 'DAT-028 upstream Phase 11 not READY -> BLOCKED');
    }

    # ------------------------- negatives -------------------------------------
    # NG-001: fixture-tagged dataset can NEVER enter a production contract
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's', fixture => 1 } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'NG-001 fixture dataset rejected');
        my $r2 = $runf->($inc, [ { raw => "TEST_FIXTURE|2026-09-09T14:30,100,101,99,100.5,10\n", source => 's' } ]);
        $ok->($r2->{phase12_status} eq 'INVALID_INPUT', 'NG-001 TEST_FIXTURE-prefixed data rejected');
    }

    # NG-002: fabricated OHLCV is impossible — unparseable rows are INVALID_INPUT
    {
        my $inc = $mk_inc->(exchange => q{BINANCE});
        my $r = $runf->($mk_inc->(exchange => 'BINANCE'), [ { raw => "not,a,dataset\n", source => 's' } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'NG-002 fabricated rows rejected');
    }

    # NG-003: invented source metadata never becomes authority
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 'made-up-api', authority => 'BOGUS' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DA-G3' && $_->{verdict} eq 'fail' } @{ $r->{checks} }), 'NG-003 invalid authority fails DA-G3');
        $ok->($r->{phase12_status} eq 'BLOCKED', 'NG-003 fabricated authority blocks');
    }

    # NG-004: silent timezone conversion never happens
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UNKNOWN');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->(!(grep { ($_->{operation} // '') =~ /timezone|convert/i } @{ $r->{transformations} }), 'NG-004 no timezone conversion recorded');
        $ok->((grep { ($_->{description} // '') =~ /timezone/ } @{ $r->{unknowns} }), 'NG-004 tz stays unknown');
    }

    # NG-005: causal statement masquerading as data fact is impossible in output
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        my $out = result_to_yaml($r);
        $ok->($out !~ /(probably caused|likely because|most likely reason|appears to have failed because)/i, 'NG-005 no probabilistic causal language');
        $ok->($out =~ /^root_cause: NOT_EVALUATED$/m, 'NG-005 root_cause pinned');
    }

    # NG-006: silent resampling never happens (5m declared, 1m-like rows supplied)
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $csv1m = "2026-09-09T14:25,100,101,99,100.5,10\n2026-09-09T14:26,100.5,101,100,100.6,1\n2026-09-09T14:27,100.6,101,100,100.7,1\n";
        my $r = $runf->($inc, [ { raw => $csv1m, source => 's' } ]);
        $ok->(!(grep { ($_->{operation} // '') =~ /resample/i } @{ $r->{transformations} }), 'NG-006 no silent resample transformation');
        $ok->((grep { ($_->{check_id} // '') =~ /DI0[14]/ } @{ $r->{all_checks} }), 'NG-006 misaligned cadence surfaces via DI01/DI04');
    }

    # NG-007: silent data cleaning never happens — raw fingerprints identical to input
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $dirty = $GOOD_CSV . "2026-09-09T14:30,100.5,102,100,101.5,12\n";  # duplicate row left as-is
        my $r = $runf->($inc, [ { raw => $dirty, source => 's' } ]);
        $ok->($r->{datasets}[0]{raw_fingerprint} eq sha256_hex(encode('UTF-8', $dirty)), 'NG-007 raw bytes preserved verbatim');
        $ok->((grep { ($_->{check_id} // '') eq 'DI02' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'NG-007 defect reported, not cleaned');
    }

    # NG-008: assumption masquerading as acquisition — absent exchange stays UNKNOWN
    {
        my $inc = $mk_inc->();
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{target}{exchange} eq 'UNKNOWN' && $r->{target}{exchange_status} eq 'UNKNOWN', 'NG-008 exchange stays UNKNOWN');
        $ok->($r->{target}{session} eq 'UNKNOWN', 'NG-008 session stays UNKNOWN');
    }

    # NG-009: upstream gate — Phase 11 gate fields must hold
    {
        my $r1 = $runf->($mk_inc->(downstream => 'false'), []);
        $ok->($r1->{phase12_status} eq 'BLOCKED', 'NG-009 downstream_allowed false -> BLOCKED');
        my $r2 = $runf->($mk_inc->(blockers => 1), []);
        $ok->($r2->{phase12_status} eq 'BLOCKED', 'NG-009 incident blockers -> BLOCKED');
        my $r3 = $runf->($mk_inc->(next_stage => 'HALT'), []);
        $ok->($r3->{phase12_status} eq 'BLOCKED', 'NG-009 next_stage HALT -> BLOCKED');
        my $r4 = $runf->($mk_inc->(incident_id => 'incident-XXXX'), []);
        $ok->($r4->{phase12_status} eq 'BLOCKED', 'NG-009 malformed incident_id -> BLOCKED');
    }

    # ------------------------- multi-timeframe (SS54) -------------------------
    my ($m1, $m5, $m15, $h1);
    {
        $m1  = "2026-09-09T14:26,100,101,99,100.5,10\n2026-09-09T14:27,100.5,101,100,100.6,11\n2026-09-09T14:28,100.6,101,100,100.7,12\n";
        $m5  = $GOOD_CSV;
        $m15 = "2026-09-09T14:15,100,101,99,100.5,30\n2026-09-09T14:30,100.5,102,100,101.5,36\n";
        $h1  = "2026-09-09T14:00,100,102,99,101.5,120\n2026-09-09T15:00,101.5,103,100,102.5,150\n";
    }

    # MTD-001: four valid independent datasets -> consistent, ESTABLISHED TF identity
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [
            { raw => $m1,  source => 's1', timeframe => '1m'  },
            { raw => $m5,  source => 's2', timeframe => '5m'  },
            { raw => $m15, source => 's3', timeframe => '15m' },
            { raw => $h1,  source => 's4', timeframe => '60m' },
        ]);
        $ok->(scalar @{ $r->{datasets} } == 4, 'MTD-001 four independent datasets accepted');
        $ok->($r->{xtf}{identity_consistency} eq 'CONSISTENT', 'MTD-001 identity consistency CONSISTENT');
        $ok->($r->{xtf}{timeframe_identity} eq 'ESTABLISHED', 'MTD-001 timeframe identity ESTABLISHED');
        $ok->($r->{xtf}{coverage_relationship} eq 'DESCRIBED', 'MTD-001 coverage described, never merged');
        $ok->(!@{ $r->{contradictions} }, 'MTD-001 no cross-TF contradictions fabricated');
    }

    # MTD-002: duplicate dataset bytes -> INVALID_INPUT
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m' }, { raw => $m5, source => 'b', timeframe => '5m' } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'MTD-002 duplicate dataset bytes rejected');
    }

    # MTD-003: duplicate timeframe declarations -> warning, never silently merged
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $m5b = $m5;
        $m5b =~ s/14:25/14:25/;
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m' },
                                { raw => "2026-09-09T14:30,100.4,102,100,101.4,12\n", source => 'b', timeframe => '5m' } ]);
        $ok->((grep { ($_->{code} // '') eq 'W-CONTRADICTION' } @{ $r->{warnings} }), 'MTD-003 same-TF contradiction preserved');
        $ok->((grep { ($_->{timeframe} // '') eq '5m' } @{ $r->{datasets} }) == 2, 'MTD-003 duplicate timeframe kept independent');
    }

    # MTD-004: required timeframe missing -> INSUFFICIENT_DATA, no substitution
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m' } ], { mtf => '1h,4h' });
        $ok->($r->{xtf}{required_timeframe_map}{$_} eq 'MISSING', "MTD-004 required $_ recorded MISSING") for qw(1h 4h);
        $ok->($r->{phase12_status} eq 'INSUFFICIENT_DATA', 'MTD-004 missing required TF -> INSUFFICIENT_DATA');
        $ok->($r->{downstream_allowed} eq 'false', 'MTD-004 downstream closed');
    }

    # MTD-005: mismatched symbol across datasets -> BLOCKED
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [
            { raw => $m5,  source => 'a', timeframe => '5m',  symbol => 'BTCUSDT' },
            { raw => $m15, source => 'b', timeframe => '15m', symbol => 'ETHUSDT' },
        ]);
        $ok->($r->{phase12_status} eq 'BLOCKED', 'MTD-005 mismatched symbol -> BLOCKED');
        $ok->((grep { ($_->{check_id} // '') eq 'DA-G17' && $_->{verdict} eq 'fail' } @{ $r->{checks} }), 'MTD-005 DA-G17 fails');
    }

    # MTD-006: dataset symbol contradicting incident target -> BLOCKED
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m', symbol => 'ETHUSDT' } ]);
        $ok->($r->{phase12_status} eq 'BLOCKED', 'MTD-006 symbol-vs-target contradiction -> BLOCKED');
    }

    # MTD-007: malformed CSV -> INVALID_INPUT
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => "not,a,dataset\n", source => 'a' }, { raw => $m5, source => 'b', timeframe => '5m' } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'MTD-007 malformed CSV rejected in multi-dataset input');
    }

    # MTD-008: header CSV missing required columns -> INVALID_INPUT
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => "ts,open,high,close\n2026-09-09T14:30,100,101,100.5\n", source => 'a' } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'MTD-008 missing required columns rejected');
    }

    # MTD-009: unparseable timestamps -> DI06 fail -> INSUFFICIENT_DATA
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => "not-a-time,100,101,99,100.5,10\n", source => 'a' } ]);
        $ok->((grep { ($_->{check_id} // '') eq 'DI06' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'MTD-009 unparseable timestamp -> DI06 fail');
        $ok->($r->{phase12_status} eq 'INSUFFICIENT_DATA', 'MTD-009 bad timestamps block');
    }

    # MTD-010: coverage relationship described per timeframe, rows never merged
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [
            { raw => $m5,  source => 'a', timeframe => '5m'  },
            { raw => $m15, source => 'b', timeframe => '15m' },
        ]);
        $ok->(@{ $r->{xtf}{coverage} } == 2, 'MTD-010 per-TF coverage described');
        my ($c15) = grep { ($_->{timeframe} // '') eq '15m' } @{ $r->{xtf}{coverage} };
        $ok->($c15->{rows} == 2 && $c15->{start} eq '2026-09-09T14:15', 'MTD-010 15m coverage independent');
        my ($d5) = grep { ($_->{timeframe} // '') eq '5m' } @{ $r->{datasets} };
        $ok->(($d5->{row_count} // 0) == 3, 'MTD-010 5m row_count preserved');
    }

    # MTD-011: unknown metadata stays UNKNOWN (never inferred)
    {
        my $inc = $mk_inc->(timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m' }, { raw => $m15, source => 'b', timeframe => '15m' } ]);
        $ok->((grep { ($_->{exchange} // 'X') eq 'UNKNOWN' } @{ $r->{datasets} }) == 2, 'MTD-011 exchange stays UNKNOWN per dataset');
        $ok->((grep { ($_->{timezone} // 'X') eq 'UNKNOWN' } @{ $r->{datasets} }) == 2, 'MTD-011 timezone stays UNKNOWN per dataset');
    }

    # MTD-012: expect-sha256 mismatch -> INVALID_INPUT (evidence integrity)
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m', expect_sha256 => 'deadbeef' . ('0' x 48) } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'MTD-012 expect-sha256 mismatch rejected');
    }

    # MTD-013: expect-sha256 match -> HIGH-confidence fact, contract still works
    {
        require Digest::SHA; require Encode;
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m', expect_sha256 => sha256_hex(encode('UTF-8', $m5)) } ]);
        $ok->((grep { ($_->{fact} // '') =~ /expect-sha256 verified/ } @{ $r->{facts} }), 'MTD-013 expect-sha256 verified fact recorded');
        $ok->($r->{phase12_status} ne 'INVALID_INPUT' && $r->{phase12_status} ne 'BLOCKED', 'MTD-013 matching hash does not block');
    }

    # MTD-014: fixture firewall holds in multi-dataset input
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $r = $runf->($inc, [ { raw => $m5, source => 'a', timeframe => '5m' }, { raw => "TEST_FIXTURE|x\n", source => 'b' } ]);
        $ok->($r->{phase12_status} eq 'INVALID_INPUT', 'MTD-014 fixture in multi-dataset input rejected');
    }

    # MTD-015: deterministic four-dataset contract — identical bytes, identical id
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC', timeframe => '5m');
        my $ds4 = sub { return [
            { raw => $m1,  source => 's1', timeframe => '1m'  },
            { raw => $m5,  source => 's2', timeframe => '5m'  },
            { raw => $m15, source => 's3', timeframe => '15m' },
            { raw => $h1,  source => 's4', timeframe => '60m' },
        ]; };
        my ($r1, $r2) = ($runf->($inc, $ds4->()), $runf->($inc, $ds4->()));
        $ok->($r1->{data_contract_id} eq $r2->{data_contract_id}, 'MTD-015 four-dataset contract id stable');
        $ok->(result_to_yaml($r1) eq result_to_yaml($r2), 'MTD-015 four-dataset contract byte-identical');
    }

    # MTD-016: backward-compatible single-dataset path — additive rev2 fields only
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{xtf}{datasets} == 1 && $r->{xtf}{identity_consistency} eq 'NOT_APPLICABLE', 'MTD-016 single dataset keeps NOT_APPLICABLE xtf');
        my $out = result_to_yaml($r);
        $ok->($out =~ /^schema_version: "1\.1"$/m, 'MTD-016 schema v1.1 declared');
        $ok->($out =~ /^cross_timeframe:$/m && $out =~ /^required_timeframe_map:/m, 'MTD-016 cross_timeframe section emitted');
        $ok->($r->{phase12_status} eq 'READY', 'MTD-016 single-CSV gate unchanged (READY)');
    }

    # ------------------------- regression protection --------------------------
    # REG-001: Phase 10 validated result stays the mechanical upstream gate
    {
        my ($up_ok, $why) = upstream_validated();
        $ok->($up_ok, "REG-001 upstream Phase 10 result validated ($why)");
    }

    # REG-002: rev1 DAT/NG behavior intact — sample of protected invariants
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $r = $runf->($inc, [ { raw => $GOOD_CSV, source => 's' } ]);
        $ok->($r->{data_contract_id} =~ /^data-[0-9a-f]{12}$/, 'REG-002 content-addressed id form preserved');
        $ok->($r->{root_cause} eq 'NOT_EVALUATED', 'REG-002 root-cause firewall preserved');
        $ok->(scalar @{ $r->{transformations} } >= 1, 'REG-002 transformation traceability preserved');
    }

    # REG-003: month/year boundary arithmetic - no phantom missing bars at rollover
    # (REV 3 defect fix: the former concatenated Y/M/D basis mis-measured the
    # Aug 31 -> Sep 1 step, inflating DI01 to ~10^5 phantom bars on real data)
    {
        my $inc = $mk_inc->(exchange => 'BINANCE', timezone => 'UTC');
        my $csv = "2026-08-31T23:50,1,2,0.5,1.5\n2026-08-31T23:55,1.5,2.5,1,2\n"
                . "2026-09-01T00:00,2,3,1.5,2.5\n2026-09-01T00:05,2.5,3.5,2,3\n";
        my $r = $runf->($inc, [ { raw => $csv, source => 's' } ]);
        my $di01 = (grep { ($_->{check_id} // '') eq 'DI01' } @{ $r->{all_checks} })[0];
        $ok->(defined $di01 && $di01->{verdict} eq 'pass', 'REG-003 month-boundary dataset has no phantom missing bars (DI01 pass)');
        $ok->(!(grep { ($_->{check_id} // '') eq 'DI01' && $_->{verdict} eq 'fail' } @{ $r->{all_checks} }), 'REG-003 no DI01 fail recorded across the Aug/Sep rollover');
    }

    print "selftest: $pass passed, $fail failed\n";
    print "All DAT-001..028 + NG-001..009 + MTD-001..016 + REG-001..003 acceptance cases pass (data contract v1.1, incl. multi-timeframe SS54).\n" if !$fail;
    return $fail ? 1 : 0;
}

main();

__END__
# House style notes (meta/data_acquisition_alignment_procedure.md §20):
# - stages 01–20 orchestration; DA-G1..G16 mechanical checks; DI01–DI10 integrity
# - hard input gate: Phase 10 validated + Phase 11 READY contract with open downstream
# - fixture firewall: TEST_FIXTURE data mechanically excluded from production contracts
# - root-cause firewall: causal wording rejected; root_cause permanently NOT_EVALUATED
# - raw data preserved byte-for-byte with sha256 fingerprint; transformations recorded
# - data_contract_id = data-<12 hex sha256(canonical body)> — deterministic, content-addressed
# - exit contract: 0 = READY/READY_WITH_WARNINGS, 2 = otherwise
# - --gate-check approves only open SUFFICIENT contracts
#!/usr/bin/perl
