#!/usr/bin/perl
# ============================================================================
# incident_intake.pl — Incident Intake & Visual Evidence engine (pine-agent Phase 11)
# ============================================================================
# Core Perl 5, zero non-core dependencies (Digest::SHA, Encode, File::Temp,
# File::Basename are core). Runtime contract identical to router.pl /
# formalize.pl / pre_verify.pl / feasibility.pl / implement.pl.
#
# Narrative authority: incident/visual_evidence_procedure.md
# Contract schema:      incident/incident_contract_schema.yaml (v1.0)
#
# Purpose: deterministic evidence-ingestion layer between
#   USER + CHART IMAGE + OBSERVATION   →   STRUCTURED INCIDENT EVIDENCE
# suitable for consumption by Phase 12 (DATA_ACQUISITION_AND_ALIGNMENT).
#
# CORE PRINCIPLE: OBSERVATION != INFERENCE != DIAGNOSIS.
#   USER_REPORTED is never converted to OBSERVED. OBSERVED is never converted
#   to ROOT_CAUSE. Root cause belongs to Phase 14 — 'root cause' wording in
#   any engine-derived field is mechanically rejected (firewall, NG-001).
#   The verbatim user report is always preserved as-is (created_from).
#
# Inputs : --user-report FILE   (verbatim user text, UTF-8; optional)
#          --image FILE         (chart image; repeatable, supplied order kept;
#                                raw bytes hashed only — never modified)
#          --report-text TEXT   (inline alternative to --user-report)
#          --symbol/--exchange/--timeframe/--timezone (user-reported target
#                                identity; recorded as USER_REPORTED)
#          --implementation-id  (target artifact id, e.g. impl-f56a05897f87)
#          --expected TEXT      --observed TEXT  --interpretation TEXT
#          --region TEXT        (verbatim user region reference)
#          --artifact PATH      (inspected project artifact, read-only)
#          --supersedes ID      (incident id of a superseded incident; recorded
#                                as a link, never mutated — e.g. an identity-
#                                corrected re-intake keeps the old incident intact)
#          --out FILE
# Output : incident contract (schema v1.0) + exit code.
#   exit 0  READY | READY_WITH_WARNINGS  (downstream_allowed true)
#   exit 2  INSUFFICIENT_VISUAL_EVIDENCE | INVALID_INPUT | BLOCKED (next_stage HALT)
#
# --gate-check --incident FILE approves only READY/READY_WITH_WARNINGS
# contracts with empty blockers and next_stage=DATA_ACQUISITION_AND_ALIGNMENT
# (exit 0); refuses all others (exit 2).
#
# Determinism: no clock, no randomness, no environment values.
#   incident_id = "incident-" + first 12 hex of sha256(canonical body)
#   (visual_evidence_procedure.md §9; identical canonical inputs produce
#   identical ids; the contract is never mutated in place).
#
# NO-MARKET-DATA RULE: web/exchange/OHLCV acquisition is exclusively Phase 12.
# Phase 11 evidence sources are CHART_IMAGE, USER_TEXT, USER_MARKED_REGION,
# PROJECT_ARTIFACT, UNKNOWN. Skill knowledge explains concepts; never evidence.
#
# NO-PINE RULE: this engine ingests incident evidence. It never emits Pine.
# ============================================================================
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode);
use File::Basename qw(dirname);

# ---------------------------------------------------------------------------
# tiny YAML-subset helpers (same style as the other engines)
# ---------------------------------------------------------------------------
sub _unq { my $s = shift; return undef if !defined $s; $s =~ s/^'//; $s =~ s/'$//; $s =~ s/''/'/g; return $s; }

# ---------------------------------------------------------------------------
# evidence accumulators (reset per run in incident_text)
# ---------------------------------------------------------------------------
my ($EV, $CONTRA, $UNKN, $LIMITS, $LOC_TRACE, $WARNS, $BLKS);
sub r_evidence   { $EV        ||= []; return $EV; }
sub r_contra     { $CONTRA    ||= []; return $CONTRA; }
sub r_unknowns   { $UNKN      ||= []; return $UNKN; }
sub r_limits     { $LIMITS    ||= []; return $LIMITS; }
sub r_loc_trace  { $LOC_TRACE ||= []; return $LOC_TRACE; }
sub r_warns      { $WARNS     ||= []; return $WARNS; }
sub r_blks       { $BLKS      ||= []; return $BLKS; }

my ($ECOUNT, $CCOUNT, $UCOUNT, $LCOUNT) = (0, 0, 0, 0);

# ---------------------------------------------------------------------------
# vocabulary (schema enums — no silent extension)
# ---------------------------------------------------------------------------
my %CLASS_OK = map { $_ => 1 } qw(OBSERVED USER_REPORTED INFERRED UNKNOWN);
my %CONF_OK  = map { $_ => 1 } qw(HIGH MEDIUM LOW UNDETERMINED);
my %LOC_OK   = map { $_ => 1 } qw(USER_POINTED VISUALLY_IDENTIFIED TEXT_LABEL TIME_AXIS PRICE_AXIS APPROXIMATE_ONLY NOT_LOCALIZABLE);

sub add_evidence {
    my (%a) = @_;
    $ECOUNT++;
    my $id = sprintf('EV-%03d', $ECOUNT);
    push @{ r_evidence() }, {
        evidence_id    => $id,
        source         => $a{source} // 'UNKNOWN',
        classification => $a{classification} // 'UNKNOWN',
        confidence     => $a{confidence} // 'UNDETERMINED',
        location       => $a{location} // 'unspecified',
        statement      => $a{statement} // '',
        source_image   => $a{source_image},
    };
    return $id;
}

sub add_contradiction {
    my ($claim_a, $claim_b) = @_;
    $CCOUNT++;
    push @{ r_contra() }, { id => sprintf('CONTRA-%03d', $CCOUNT), claim_a => $claim_a, claim_b => $claim_b, resolution => 'NONE_PRESERVED' };
    return sprintf('CONTRA-%03d', $CCOUNT);
}

sub add_unknown {
    my ($description) = @_;
    $UCOUNT++;
    push @{ r_unknowns() }, { id => sprintf('UNK-%03d', $UCOUNT), description => $description };
    return sprintf('UNK-%03d', $UCOUNT);
}

sub add_limitation {
    my ($description) = @_;
    $LCOUNT++;
    push @{ r_limits() }, { id => sprintf('LIM-%03d', $LCOUNT), description => $description };
    return sprintf('LIM-%03d', $LCOUNT);
}

sub add_warning {
    my ($check_id, $code, $message) = @_;
    push @{ r_warns() }, { check_id => $check_id, code => $code, message => $message };
    return;
}

sub add_blocker {
    my ($check_id, $message) = @_;
    push @{ r_blks() }, { check_id => $check_id, message => $message };
    return;
}

# ---------------------------------------------------------------------------
# input model (visual_evidence_procedure.md §2) — none fabricated when absent
# ---------------------------------------------------------------------------
sub parse_input {
    my ($spec) = @_;
    die "unparseable: empty input spec\n" unless ref $spec eq 'HASH' && %$spec;
    my %i = %$spec;
    my $has_image = @{ $i{images} || [] } ? 1 : 0;
    my $has_text  = (defined $i{user_report} && $i{user_report} =~ /\S/) ? 1 : 0;
    die "INVALID_INPUT: at least one of user_report / chart_image must be supplied\n" unless $has_image || $has_text;
    return {
        user_report         => $i{user_report},
        images              => $i{images} || [],            # [{ path, sha256 }] in supplied order
        image_observations  => $i{image_observations} // {},# { IMG-001 => [ {statement,classification,confidence} ] }
        symbol              => $i{symbol},
        exchange            => $i{exchange},
        timeframe           => $i{timeframe},
        timezone            => $i{timezone},
        implementation_id   => $i{implementation_id},
        expected            => $i{expected},
        observed            => $i{observed},
        interpretation      => $i{interpretation},
        region              => $i{region},
        region_confidence   => $i{region_confidence},
        project_artifact    => $i{project_artifact},
        supersedes          => $i{supersedes},           # link to a superseded incident (recorded, never mutated)
    };
}

# canonical UTF-8 body over the supplied bytes (identity field excluded)
sub user_report_bytes_sha256 {
    my ($text) = @_;
    return 'NULL' unless defined $text && length $text;
    return sha256_hex(encode('UTF-8', $text));
}

# ---------------------------------------------------------------------------
# mechanical checks INT-G1..INT-G8 (visual_evidence_procedure.md §1, §12)
#   INT-G1  input validation (+ upstream Phase 10 validated state at CLI level)
#   INT-G2  image ingestion (fingerprint; never modified/recompressed)
#   INT-G3  visual evidence extraction (classification vocabulary enforced)
#   INT-G4  user observation normalization (verbatim preserved; no conversion)
#   INT-G5  region/event localization (no invented bar index / timestamp)
#   INT-G6  expected / observed / user_interpretation separation (+ firewall)
#   INT-G7  contradiction analysis (recorded, never resolved)
#   INT-G8  sufficiency + downstream gate (Phase 12 rules)
# ---------------------------------------------------------------------------

# --- INT-G1 ---------------------------------------------------------------
sub check_g1 {
    my ($inp) = @_;
    push @{ r_blks() }, { check_id => 'INT-G1', message => 'user_report/chart_image: at least one required' }
        unless (defined $inp->{user_report} && $inp->{user_report} =~ /\S/) || @{ $inp->{images} || [] };
    for my $k (qw(symbol exchange timeframe timezone implementation_id expected observed interpretation region project_artifact)) {
        next unless defined $inp->{$k};
        $inp->{$k} =~ s/^\s+//; $inp->{$k} =~ s/\s+$//;
        add_blocker('INT-G1', "field '$k' is empty after trimming") if $inp->{$k} eq '';
    }
    if (defined $inp->{supersedes}) {
        $inp->{supersedes} =~ s/^\s+//; $inp->{supersedes} =~ s/\s+$//;
        add_blocker('INT-G1', "supersedes must be a well-formed incident id (incident-<12 hex>)")
            unless $inp->{supersedes} =~ /^incident-[0-9a-f]{12}$/;
    }
    return;
}

# --- INT-G2: image ingestion ------------------------------------------------
# image_sha256 computed over raw bytes (Digest::SHA, core Perl) for evidence
# identity only; the image is never modified or recompressed. When
# fingerprinting is unavailable: UNAVAILABLE — never fabricated (§7).
sub check_g2 {
    my ($inp) = @_;
    my @imgs;
    my $n = 0;
    for my $im (@{ $inp->{images} || [] }) {
        $n++;
        my $img_id = sprintf('IMG-%03d', $n);
        if (!defined $im->{sha256} || $im->{sha256} !~ /^[0-9a-f]{64}$/) {
            add_limitation("image $img_id fingerprint UNAVAILABLE — image identity unverifiable (never fabricated)");
            push @imgs, { img_id => $img_id, path => ($im->{path} // 'UNKNOWN'), image_sha256 => undef, fingerprint_status => 'UNAVAILABLE' };
            add_warning('INT-G2', 'W-FINGERPRINT', "image $img_id fingerprint unavailable; image identity unverifiable (provenance degraded, not blocking)");
            next;
        }
        push @imgs, { img_id => $img_id, path => ($im->{path} // 'UNKNOWN'), image_sha256 => $im->{sha256}, fingerprint_status => 'COMPUTED' };
    }
    if (!@imgs) {
        add_warning('INT-G2', 'W-NO-IMAGE', 'no chart image supplied — visual evidence limited to the user report (recorded, not hidden)');
        add_limitation('no chart image supplied — chart identity, price structure, volume, and visible signals cannot be independently observed');
    }
    return \@imgs;
}

# --- INT-G3: visual evidence extraction --------------------------------------
# A visual statement is accepted only with an explicit classification +
# confidence + provenance (schema enums). Absence claims are restricted to
# visual phrasing — never runtime claims (§3.5).
sub check_g3 {
    my ($inp) = @_;
    my $definitely = ($inp->{user_report} // '') =~ /\b(signal (did|does|will) not fire|never fired|indicator (failed|is broken)|is broken)\b/i;
    if ($definitely) {
        add_warning('INT-G3', 'W-ABSENCE-PHRASING',
            "user wording makes a runtime claim ('the signal did not fire'); Phase 11 records it as USER_REPORTED and restricts the OBSERVED dimension to a visual-absence claim ('no visible marker detected in the inspected region') — never a runtime claim");
    }
    return;
}

# --- INT-G4: user observation normalization ----------------------------------
sub check_g4 {
    my ($inp) = @_;
    return unless defined $inp->{user_report} && $inp->{user_report} =~ /\S/;
    # verbatim preserved in created_from.user_report; normalization is separate
    add_evidence(
        source => 'USER_TEXT', classification => 'USER_REPORTED', confidence => 'HIGH',
        location => 'user report (verbatim)',
        statement => substr($inp->{user_report}, 0, 400),
    );
    return;
}

# --- INT-G5: region/event localization ----------------------------------------
# Never invent a precise bar index or timestamp (§4). USER_POINTED when the
# user supplies a region reference with an image to anchor it;
# APPROXIMATE_ONLY textually; NOT_LOCALIZABLE with no reference at all.
sub check_g5 {
    my ($inp, $imgs) = @_;
    my $region = $inp->{region};
    my $has_img = @$imgs ? 1 : 0;
    if (defined $region && $region =~ /\S/) {
        my $method = $inp->{region_confidence} // ($has_img ? 'USER_POINTED' : 'APPROXIMATE_ONLY');
        if (!$LOC_OK{$method}) {
            add_blocker('INT-G5', "localization method '$method' is outside the fixed vocabulary");
            $method = 'NOT_LOCALIZABLE';
        }
        my $eid = add_evidence(
            source => 'USER_TEXT', classification => 'USER_REPORTED', confidence => 'MEDIUM',
            location => 'region reference (verbatim)', statement => $region,
        );
        push @{ r_loc_trace() }, { evidence_id => $eid, method => $method, statement => $region };
        return {
            method => $method, timestamp => 'UNKNOWN', timestamp_status => 'NOT_ESTABLISHED',
            bar_index => 'UNKNOWN', bar_index_status => 'NOT_ESTABLISHED',
            region => $region, precision => 'APPROXIMATE',
        };
    }
    add_unknown('exact bar index cannot be established from the supplied evidence (never invented)');
    add_unknown('exact timestamp cannot be established from the supplied evidence (never invented)');
    return {
        method => 'NOT_LOCALIZABLE', timestamp => 'UNKNOWN', timestamp_status => 'NOT_ESTABLISHED',
        bar_index => 'UNKNOWN', bar_index_status => 'NOT_ESTABLISHED',
        region => undef, precision => 'UNKNOWN',
    };
}

# --- INT-G6: expected / observed / user_interpretation separation ---------------
# The user's interpretation is recorded but is never converted into observed
# fact or requirement (§5). Firewall: root-cause wording in any engine-derived
# field is rejected (§11).
sub check_g6 {
    my ($inp) = @_;
    if (defined $inp->{observed} && $inp->{observed} =~ /\S/) {
        if ($inp->{observed} =~ /root cause/i) {
            add_blocker('INT-G6', "root-cause wording detected in the observed field — Phase 11 outputs investigation targets, never root causes (firewall; diagnosis belongs to Phase 14)");
        } else {
            add_evidence(source => 'USER_TEXT', classification => 'USER_REPORTED', confidence => 'HIGH',
                location => 'observed_behavior', statement => $inp->{observed});
        }
    }
    if (defined $inp->{expected} && $inp->{expected} =~ /\S/) {
        add_evidence(source => 'USER_TEXT', classification => 'USER_REPORTED', confidence => 'HIGH',
            location => 'expected_behavior', statement => $inp->{expected});
    }
    if (defined $inp->{interpretation} && $inp->{interpretation} =~ /\S/) {
        add_evidence(source => 'USER_TEXT', classification => 'USER_REPORTED', confidence => 'HIGH',
            location => 'user_interpretation', statement => $inp->{interpretation});
    }
    my $has_expected = (defined $inp->{expected} && $inp->{expected} =~ /\S/) || (defined $inp->{user_report} && $inp->{user_report} =~ /\S/);
    my $has_observed = (defined $inp->{observed} && $inp->{observed} =~ /\S/) || (defined $inp->{user_report} && $inp->{user_report} =~ /\S/);
    return ($has_expected && $has_observed) ? 1 : 0;
}

# --- INT-G7: contradiction analysis ----------------------------------------------
# USER_REPORTED claim vs visual record: both preserved, never resolved (§8).
sub check_g7 {
    my ($inp, $imgs) = @_;
    return unless @$imgs && defined $inp->{observed} && $inp->{observed} =~ /\S/;
    my $report = $inp->{user_report} // '';
    # mechanical heuristic: an affirmative visible-marker claim in the report
    # (no local negation) against a visual no-marker observation.
    my $affirm  = $report =~ /\b(BUY|SELL)\s+(signal|marker|arrow)\s+(appeared|was there|is visible|showed)\b/i
               && $report !~ /\b(no|not|without)\s+(?:visible\s+)?(?:BUY|SELL)\b/i;
    my $obs_none = ($inp->{observed} // '') =~ /\bno visible (BUY|SELL)\b/i;
    return unless $affirm && $obs_none;
    my $cid = add_contradiction(
        'user report: a BUY/SELL signal appeared in the region (USER_REPORTED)',
        'observed behavior: no visible BUY/SELL marker detected in the inspected region (visual absence claim)',
    );
    add_warning('INT-G7', 'W-CONTRADICTION', "contradiction $cid recorded between user report and observed behavior; resolution NONE_PRESERVED (both claims preserved, never silently resolved)");
    return;
}

# --- INT-G8: sufficiency + downstream gate ----------------------------------------
# Sufficient for Phase 12 (all required): investigation target established
# (symbol and/or timeframe identified, or Phase 12 can obtain them from the
# exchange context — an image or a concrete event description qualifies),
# region/localization present (USER_POINTED or better), and the expected/
# observed distinction captured. Do not demand information Phase 12 can
# legitimately obtain later (§10).
my $TARGET_VOCAB = qr/\b(BUY|SELL|marker|arrow|signal|cross(?:ed)?(?:\s+over|\s+under)?|crossover|divergence)\b/i;

sub check_g8 {
    my ($inp, $imgs, $loc, $eo_ok) = @_;
    return 0 unless $eo_ok;
    my $desc_concrete = (defined $inp->{user_report} && $inp->{user_report} =~ $TARGET_VOCAB) ? 1 : 0;
    my $target_established = (defined $inp->{symbol} && $inp->{symbol} =~ /\S/)
                          || (defined $inp->{timeframe} && $inp->{timeframe} =~ /\S/)
                          || @$imgs
                          || $desc_concrete;
    return 0 unless $target_established;
    return 0 unless (defined $loc && defined $loc->{method} && $loc->{method} ne 'NOT_LOCALIZABLE');
    return 1;
}

# ---------------------------------------------------------------------------
# image observation ingestion (Stage 05) — structural, honest.
# Supplied per-image observations must carry schema enums; the image is never
# inspected implicitly. Without supplied observations, every visual field
# stays UNKNOWN/NOT_VISIBLE (never fabricated).
# ---------------------------------------------------------------------------
sub check_image_observations {
    my ($inp, $imgs) = @_;
    my $i = 0;
    for my $im (@$imgs) {
        $i++;
        my $img = $im->{img_id};
        my $obs = $inp->{image_observations}{ $img };
        if ($obs) {
            for my $o (@{ $obs }) {
                my $cls  = $o->{classification} // 'UNKNOWN';
                my $conf = $o->{confidence} // 'UNDETERMINED';
                if (!$CLASS_OK{$cls} || !$CONF_OK{$conf}) {
                    add_blocker('INT-G3', "image $img observation carries an invalid classification/confidence enum ('$cls'/'$conf') — the vocabulary is fixed");
                    next;
                }
                if (($o->{statement} // '') =~ /root cause/i) {
                    add_blocker('INT-G6', "root-cause wording detected in an image observation — Phase 11 outputs investigation targets, never root causes (firewall)");
                    next;
                }
                add_evidence(
                    source => 'CHART_IMAGE', classification => $cls, confidence => $conf,
                    location => ($o->{location} // "image $img"), statement => ($o->{statement} // ''),
                    source_image => $img,
                );
            }
        } else {
            add_limitation("image $img present but not visually inspected in this run — chart identity, price structure, volume, and signals remain UNKNOWN/NOT_VISIBLE (never fabricated)");
            add_evidence(source => 'CHART_IMAGE', classification => 'UNKNOWN', confidence => 'UNDETERMINED',
                location => "image $img", statement => 'image supplied; contents not established in this run', source_image => $img);
            add_warning('INT-G2', 'W-IMAGE-UNINSPECTED', "image $img was not visually inspected; evidence sufficiency for Phase 12 may be degraded (recorded, not hidden)");
        }
    }
    return;
}

# ---------------------------------------------------------------------------
# result finalization (stages 11–14)
# ---------------------------------------------------------------------------
sub _finalize {
    my ($r, $inp, $imgs, $loc, $eo_ok) = @_;
    $inp  //= { user_report => undef };
    $imgs //= [];
    $loc  //= { method => 'NOT_LOCALIZABLE', timestamp => 'UNKNOWN', timestamp_status => 'NOT_ESTABLISHED',
                bar_index => 'UNKNOWN', bar_index_status => 'NOT_ESTABLISHED', region => undef, precision => 'UNKNOWN' };

    # merge accumulator findings (deterministic order: explicit findings first,
    # then blockers, then warnings in insertion order)
    my @acc_blk = map { { check_id => $_->{check_id}, severity => 'blocker', code => 'B-INTAKE', message => $_->{message}, refs => [] } } @{ r_blks() };
    my @acc_wrn = map { { check_id => $_->{check_id}, severity => 'warning', code => $_->{code}, message => $_->{message}, refs => [] } } @{ r_warns() };
    my @findings = (@{ $r->{findings} || [] }, @acc_blk, @acc_wrn);
    my $i = 0;
    for my $f (@findings) { $i++; $f->{id} = sprintf('F-%03d', $i); }

    my @blockers = grep { ($_->{severity} // '') eq 'blocker' } @findings;
    my @warnings = grep { ($_->{severity} // '') eq 'warning' } @findings;

    my @checks;
    my @domains = (
        ['INT-G1', 'input_validation'],              ['INT-G2', 'image_ingestion'],
        ['INT-G3', 'visual_evidence_extraction'],    ['INT-G4', 'observation_normalization'],
        ['INT-G5', 'region_localization'],           ['INT-G6', 'expected_observed_separation'],
        ['INT-G7', 'contradiction_analysis'],        ['INT-G8', 'sufficiency_gate'],
    );
    for my $d (@domains) {
        my ($cid, $dom) = @$d;
        my @mine = grep { ($_->{check_id} // '') eq $cid } @findings;
        my $verdict = (grep { ($_->{severity} // '') eq 'blocker' } @mine) ? 'fail' : (@mine ? 'warn' : 'pass');
        push @checks, { check_id => $cid, domain => $dom, verdict => $verdict, findings => [map { $_->{id} } @mine] };
    }

    # --- sufficiency decision (Stage 14, downstream gate) -----------------------
    my $status;
    if ($r->{input_invalid}) {
        $status = 'INVALID_INPUT';
    } elsif (@blockers) {
        $status = 'BLOCKED';
    } elsif (!check_g8($inp, $imgs, $loc, $eo_ok)) {
        $status = 'INSUFFICIENT_VISUAL_EVIDENCE';
    } elsif (@warnings || @{ r_limits() } || @{ r_unknowns() } || @{ r_contra() }) {
        $status = 'READY_WITH_WARNINGS';
    } else {
        $status = 'READY';
    }
    my $open = ($status eq 'READY' || $status eq 'READY_WITH_WARNINGS') ? 1 : 0;

    # --- canonical identity body (procedure §9 — fixed field order) -------------
    my @body = (
        (defined $r->{user_report_bytes_sha256} ? $r->{user_report_bytes_sha256} : 'NULL'),
        (map { ($_->{image_sha256} // 'UNAVAILABLE') } @$imgs),
        join('|', map { (defined $inp->{$_} && length $inp->{$_}) ? $inp->{$_} : 'UNKNOWN' } qw(symbol exchange timeframe timezone implementation_id)),
        join('|', map { (defined $loc->{$_} && length($loc->{$_} // '')) ? $loc->{$_} : 'UNKNOWN' } qw(method timestamp bar_index region)),
        ((defined $inp->{expected} && length $inp->{expected})       ? $inp->{expected}       : 'UNKNOWN'),
        ((defined $inp->{observed} && length $inp->{observed})       ? $inp->{observed}       : 'UNKNOWN'),
        ((defined $inp->{interpretation} && length $inp->{interpretation}) ? $inp->{interpretation} : 'UNKNOWN'),
        (map { ($_->{evidence_id} // '') . ':' . ($_->{classification} // '') . ':' . ($_->{confidence} // '') } @{ r_evidence() }),
        scalar @{ r_contra() },
        scalar @{ r_limits() },
        '1.0',
    );
    my $iid = 'incident-' . substr(sha256_hex(encode('UTF-8', join("\n", @body))), 0, 12);
    my $result_hash = sha256_hex(encode('UTF-8', join("\n", @body, $iid)));

    # --- emitted fields (schema v1.0 — every field materialized, none fabricated) ---
    my $has_img_obs = grep { defined $_->{source_image} && ($_->{classification} // '') ne 'UNKNOWN' } @{ r_evidence() };
    my $target = sub {
        my ($k, $np_status) = @_;
        my $v = $inp->{$k};
        return (defined $v && $v =~ /\S/) ? ($v, 'USER_REPORTED') : ('UNKNOWN', $np_status);
    };
    my ($sym, $sym_st)       = $target->('symbol', 'UNKNOWN');
    my ($ex,  $ex_st)        = $target->('exchange', 'UNKNOWN');
    my ($tf,  $tf_st)        = $target->('timeframe', 'UNKNOWN');
    my ($tz,  $tz_st)        = $target->('timezone', 'NOT_PROVIDED');
    my $observed_source = ((defined $inp->{observed} && $inp->{observed} =~ /\S/) && $has_img_obs) ? 'MIXED'
                        : (defined $inp->{observed} && $inp->{observed} =~ /\S/) ? 'USER_TEXT'
                        : $has_img_obs ? 'CHART_IMAGE' : 'NONE';
    my $normalized = (defined $inp->{user_report} && $inp->{user_report} =~ /\S/)
        ? join(' ', grep { length } split /\s+/, $inp->{user_report})
        : undef;

    $i = 0;
    $r->{blockers} = [ map { $i++; { id => sprintf('B-%03d', $i), check_id => $_->{check_id}, code => $_->{code}, reason => $_->{message} } } @blockers ];
    $i = 0;
    $r->{warnings} = [ map { $i++; { id => sprintf('W-%03d', $i), code => $_->{code}, message => $_->{message} } } @warnings ];

    $r->{checks}              = \@checks;
    $r->{findings}            = \@findings;
    $r->{incident_id}         = $iid;
    $r->{incident_version}    = 'rev1';
    $r->{image_present}       = @$imgs ? 'true' : 'false';
    $r->{user_report_present} = (defined $inp->{user_report} && $inp->{user_report} =~ /\S/) ? 'true' : 'false';
    $r->{images}              = $imgs;
    $r->{localization}        = $loc;
    $r->{symbol}              = $sym;              $r->{symbol_status}     = $sym_st;
    $r->{exchange}            = $ex;               $r->{exchange_status}   = $ex_st;
    $r->{timeframe}           = $tf;               $r->{timeframe_status}  = $tf_st;
    $r->{timezone}            = $tz;               $r->{timezone_status}   = $tz_st;
    $r->{implementation_id}   = (defined $inp->{implementation_id} && $inp->{implementation_id} =~ /\S/) ? $inp->{implementation_id} : 'UNKNOWN';
    $r->{source_artifact}     = (defined $inp->{project_artifact} && $inp->{project_artifact} =~ /\S/) ? $inp->{project_artifact} : undef;
    $r->{project_artifact}    = $r->{source_artifact};
    $r->{expected}            = (defined $inp->{expected} && $inp->{expected} =~ /\S/) ? $inp->{expected} : undef;
    $r->{observed}            = (defined $inp->{observed} && $inp->{observed} =~ /\S/) ? $inp->{observed} : undef;
    $r->{observed_source}     = $observed_source;
    $r->{interpretation}      = (defined $inp->{interpretation} && $inp->{interpretation} =~ /\S/) ? $inp->{interpretation} : undef;
    $r->{normalized}          = $normalized;
    $r->{user_report}         = $inp->{user_report};
    $r->{phase11_status}      = $status;
    $r->{evidence_sufficiency}|= $open ? 'SUFFICIENT' : 'INSUFFICIENT';
    $r->{downstream_allowed}  = $open ? 'true' : 'false';
    $r->{next_stage}          = $open ? 'DATA_ACQUISITION_AND_ALIGNMENT' : 'HALT';
    $r->{result_hash}         = $result_hash;
    return $r;
}

# ---------------------------------------------------------------------------
# orchestration (stages 01–14)
# ---------------------------------------------------------------------------
sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return decode('UTF-8', $t); }

sub incident_text {
    my ($spec) = @_;
    ($EV, $CONTRA, $UNKN, $LIMITS, $LOC_TRACE, $WARNS, $BLKS) = (undef) x 7;
    ($ECOUNT, $CCOUNT, $UCOUNT, $LCOUNT) = (0, 0, 0, 0);

    my $bad = sub {
        my ($msg) = @_;
        return _finalize({
            input_invalid => 1,
            findings => [{ check_id => 'INT-G1', severity => 'blocker', code => 'B-INPUT', message => $msg, refs => [] }],
        });
    };
    return $bad->('input could not be parsed: ' . ($spec->{parse_error} // 'missing or empty')) if !$spec || !ref $spec || $spec->{parse_error};

    my $inp;
    $inp = eval { parse_input($spec) };
    return $bad->('input could not be parsed: ' . ($@ // 'unknown error')) unless $inp;

    # --- Stage 03: input validation -----------------------------------------------
    check_g1($inp);

    # --- Stage 04: image ingestion ---------------------------------------------------
    my $imgs = check_g2($inp);
    check_image_observations($inp, $imgs);

    # --- Stage 05: visual evidence extraction (vocabulary discipline) ----------------
    check_g3($inp);

    # --- Stage 06: user observation normalization (verbatim preserved) ----------------
    check_g4($inp);

    # --- Stage 07: region/event localization -------------------------------------------
    my $loc = check_g5($inp, $imgs);

    # --- Stage 08: expected vs observed separation --------------------------------------
    my $eo_ok = check_g6($inp);

    # --- Stage 10: contradiction analysis -------------------------------------------------
    check_g7($inp, $imgs);

    # target identity evidence (USER_REPORTED when supplied; UNKNOWN otherwise)
    for my $pair ([ symbol => 'symbol' ], [ exchange => 'exchange' ], [ timeframe => 'timeframe' ],
                 [ timezone => 'timezone' ], [ implementation_id => 'target artifact id' ]) {
        my ($k, $label) = @$pair;
        next unless defined $inp->{$k} && $inp->{$k} =~ /\S/;
        add_evidence(source => 'USER_TEXT', classification => 'USER_REPORTED', confidence => 'HIGH',
            location => "target.$k", statement => "$label: " . $inp->{$k});
    }

    # --- limitations for missing target identity (no fabrication; Phase 12 may resolve) ---
    add_limitation('timeframe: NOT_PROVIDED (user did not supply; Phase 12 may identify it from the exchange context)') unless defined $inp->{timeframe} && $inp->{timeframe} =~ /\S/;
    add_limitation('symbol: NOT_PROVIDED (user did not supply; Phase 12 may identify it from the exchange context)')     unless defined $inp->{symbol} && $inp->{symbol} =~ /\S/;

    return _finalize({
        user_report_bytes_sha256 => user_report_bytes_sha256($inp->{user_report}),
        supersedes               => (defined $inp->{supersedes} && $inp->{supersedes} =~ /\S/) ? $inp->{supersedes} : undef,
        findings                 => [],
    }, $inp, $imgs, $loc, $eo_ok);
}

# ---------------------------------------------------------------------------
# result emitter (fixed field order; mirrors the house YAML style)
# ---------------------------------------------------------------------------
sub _q  { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _qb { my $b = shift // ''; return ($b eq 'true') ? 'true' : 'false'; }
sub _ql { my ($l) = @_; return '[]' unless @{ $l || [] }; return '[' . join(', ', map { _q($_) } @$l) . ']'; }

sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, '# incident contract - generated by incident_intake.pl (schema v1.0; incident/visual_evidence_procedure.md)';
    push @o, 'schema_version: "1.0"', 'stage: incident_intake', 'predecessor: post_verification', 'successor: data_acquisition_and_alignment', '';
    push @o, 'incident:';
    push @o, '  incident_id: ' . _q($r->{incident_id});
    push @o, '  incident_version: ' . _q($r->{incident_version});
    push @o, '  supersedes: ' . (defined $r->{supersedes} && length $r->{supersedes} ? _q($r->{supersedes}) : 'null');
    push @o, '  sequence: null';
    push @o, '  created_from:';
    push @o, '    user_report: ' . _q($r->{user_report} // 'null');
    push @o, '    chart_image:';
    if (!@{ $r->{images} }) { push @o, '      []'; }
    else {
        for my $im (@{ $r->{images} }) {
            push @o, '      - { img_id: ' . _q($im->{img_id}) . ', path: ' . _q($im->{path}) . ', image_sha256: ' . _q($im->{image_sha256} // 'null') . ', fingerprint_status: ' . _q($im->{fingerprint_status}) . ' }';
        }
    }
    push @o, '    project_artifact: ' . _q($r->{project_artifact} // 'null');
    push @o, '  image_present: ' . _qb($r->{image_present});
    push @o, '  user_report_present: ' . _qb($r->{user_report_present});
    push @o, '  target:';
    push @o, '    symbol: ' . _q($r->{symbol}) . ' # ' . _q($r->{symbol_status});
    push @o, '    exchange: ' . _q($r->{exchange}) . ' # ' . _q($r->{exchange_status});
    push @o, '    timeframe: ' . _q($r->{timeframe}) . ' # ' . _q($r->{timeframe_status});
    push @o, '    timezone: ' . _q($r->{timezone}) . ' # ' . _q($r->{timezone_status});
    push @o, '    implementation_id: ' . _q($r->{implementation_id});
    push @o, '  source_artifact: ' . _q($r->{source_artifact} // 'null');
    push @o, '  localization:';
    push @o, '    method: ' . _q($r->{localization}{method});
    push @o, '    timestamp: ' . _q($r->{localization}{timestamp}) . ' # ' . _q($r->{localization}{timestamp_status});
    push @o, '    bar_index: ' . _q($r->{localization}{bar_index}) . ' # ' . _q($r->{localization}{bar_index_status});
    push @o, '    region: ' . _q($r->{localization}{region});
    push @o, '    precision: ' . _q($r->{localization}{precision});
    push @o, '  localization_trace:';
    if (!@{ r_loc_trace() }) { push @o, '    []'; }
    else {
        for my $lt (@{ r_loc_trace() }) {
            push @o, '    - { evidence_id: ' . _q($lt->{evidence_id}) . ', method: ' . _q($lt->{method}) . ', statement: ' . _q($lt->{statement}) . ' }';
        }
    }
    push @o, '  expected:';
    push @o, '    description: ' . _q($r->{expected} // 'null');
    push @o, '    source: USER_TEXT';
    push @o, '  observed:';
    push @o, '    description: ' . _q($r->{observed} // 'null');
    push @o, '    source: ' . _q($r->{observed_source});
    push @o, '  user_interpretation:';
    push @o, '    description: ' . _q($r->{interpretation} // 'null');
    push @o, '    source: USER_TEXT';
    push @o, '  normalized_user_observation: ' . _q($r->{normalized} // 'null');
    push @o, '  evidence:';
    if (!@{ r_evidence() }) { push @o, '    []'; }
    else {
        for my $ev (@{ r_evidence() }) {
            push @o, '    - { evidence_id: ' . _q($ev->{evidence_id})
                . ', source: ' . _q($ev->{source})
                . ', classification: ' . _q($ev->{classification})
                . ', confidence: ' . _q($ev->{confidence})
                . ', location: ' . _q($ev->{location})
                . ', statement: ' . _q($ev->{statement})
                . (defined $ev->{source_image} ? ', source_image: ' . _q($ev->{source_image}) : '')
                . ' }';
        }
    }
    push @o, '  contradictions:';
    if (!@{ r_contra() }) { push @o, '    []'; }
    else {
        for my $ct (@{ r_contra() }) {
            push @o, '    - { id: ' . _q($ct->{id}) . ', claim_a: ' . _q($ct->{claim_a}) . ', claim_b: ' . _q($ct->{claim_b}) . ', resolution: NONE_PRESERVED }';
        }
    }
    push @o, '  unknowns:';
    if (!@{ r_unknowns() }) { push @o, '    []'; }
    else { for my $u (@{ r_unknowns() }) { push @o, '    - { id: ' . _q($u->{id}) . ', description: ' . _q($u->{description}) . ' }'; } }
    push @o, '  limitations:';
    if (!@{ r_limits() }) { push @o, '    []'; }
    else { for my $l (@{ r_limits() }) { push @o, '    - { id: ' . _q($l->{id}) . ', description: ' . _q($l->{description}) . ' }'; } }
    push @o, '  phase11_status: ' . _q($r->{phase11_status});
    push @o, '  next_stage: ' . ($r->{next_stage} // 'null');
    push @o, '  downstream_allowed: ' . _qb($r->{downstream_allowed});
    if (!@{ $r->{blockers} }) { push @o, '  blockers: []'; }
    else {
        push @o, '  blockers:';
        for my $b (@{ $r->{blockers} }) { push @o, '    - { id: ' . _q($b->{id}) . ', check_id: ' . _q($b->{check_id}) . ', reason: ' . _q($b->{reason}) . ' }'; }
    }
    if (!@{ $r->{warnings} }) { push @o, '  warnings: []'; }
    else {
        push @o, '  warnings:';
        for my $w (@{ $r->{warnings} }) { push @o, '    - { id: ' . _q($w->{id}) . ', code: ' . _q($w->{code}) . ', message: ' . _q($w->{message}) . ' }'; }
    }
    push @o, '  evidence_sufficiency: ' . _q($r->{evidence_sufficiency});
    push @o, '  notes: []';
    push @o, '  result_hash: ' . _q($r->{result_hash});
    push @o, '  next_stage_note: ' . _q((($r->{next_stage} // '') eq 'DATA_ACQUISITION_AND_ALIGNMENT') ? 'Phase 12 (Data Acquisition & Alignment) may start' : 'pipeline halted - downstream progression forbidden');
    push @o, '';
    push @o, 'checks:';
    for my $ck (@{ $r->{checks} }) {
        push @o, '  - { check_id: ' . _q($ck->{check_id}) . ', domain: ' . _q($ck->{domain}) . ', verdict: ' . _q($ck->{verdict}) . ', findings: ' . _ql($ck->{findings}) . ' }';
    }
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# gate-check on a RESULT file: approved iff incident_id well-formed,
# phase11_status READY|READY_WITH_WARNINGS, blockers [], downstream_allowed
# true, next_stage DATA_ACQUISITION_AND_ALIGNMENT (procedure §13)
# ---------------------------------------------------------------------------
sub gate_check_text {
    my ($t) = @_;
    my ($iid) = $t =~ /^\s{2}incident_id:\s*'([^']*)'/m;
    my ($st)  = $t =~ /^\s{2}phase11_status:\s*'([^']*)'/m;
    my ($ns)  = $t =~ /^\s{2}next_stage:\s*(\S+)/m;
    my ($da)  = $t =~ /^\s{2}downstream_allowed:\s*(true|false)/m;
    my $blockers_empty = ($t =~ /^  blockers: \[\]/m) ? 1 : 0;
    return (0, 'incident_id missing or malformed') unless defined $iid && $iid =~ /^incident-[0-9a-f]{12}$/;
    return (0, "phase11_status is '$st' - downstream progression forbidden") unless defined $st && ($st eq 'READY' || $st eq 'READY_WITH_WARNINGS');
    return (0, 'blockers list is non-empty') unless $blockers_empty;
    return (0, "downstream_allowed is '$da'") unless defined $da && $da eq 'true';
    return (0, "next_stage is '$ns'") unless defined $ns && $ns eq 'DATA_ACQUISITION_AND_ALIGNMENT';
    return (1, "approved_incident_id = $iid");
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
sub default_upstream_path {
    (my $f = __FILE__) =~ s{\\}{/}g;
    return dirname($f) . '/../verification/phase10_post_verification_result.yaml';
}

sub upstream_validated {
    # Stage 01/02 (forensic audit / upstream validation): the Phase 10 REV 4
    # result must be present and read as validated. Read-only; never modified.
    my $path = default_upstream_path();
    return (0, 'missing') unless -f $path;
    my $t = eval { _slurp($path) };
    return (0, 'unreadable') unless defined $t;
    my ($verdict) = $t =~ /^\s{2}verdict:\s*'?([A-Za-z_]+)'?/m;
    my ($iid)     = $t =~ /^\s{2}implementation_id_under_verification:\s*'?([^'\s]+)'?/m;
    my ($gate)    = $t =~ /^\s{2}final_gate:\s*'?([A-Z_]+)'?/m;
    return (0, 'not validated') unless defined $verdict && $verdict eq 'validated';
    return (1, ($iid // 'artifact') . " (final_gate " . ($gate // '?') . ")");
}

sub main {
    my ($report_file, $report_text, $out_file, $gate, $incident_file) = (undef, undef, undef, 0, undef);
    my (@image_args, %kv);
    while (@ARGV) {
        my $a = shift @ARGV;
        if    ($a eq '--user-report')  { $report_file = shift @ARGV; }
        elsif ($a eq '--report-text')  { $report_text = shift @ARGV; }
        elsif ($a eq '--image')        { push @image_args, shift @ARGV; }
        elsif ($a eq '--out')          { $out_file = shift @ARGV; }
        elsif ($a eq '--incident')     { $incident_file = shift @ARGV; }
        elsif ($a eq '--supersedes')   { $kv{supersedes} = shift @ARGV; }
        elsif ($a eq '--gate-check')   { $gate = 1; }
        elsif ($a eq '--selftest')     { my $st = selftest(); exit $st; }
        elsif ($a =~ /^--(symbol|exchange|timeframe|timezone|implementation-id|expected|observed|interpretation|region|artifact)$/) {
            $kv{$1} = shift @ARGV;
        }
        elsif ($a eq '--image-obs')    { push @{ $kv{image_obs} }, shift @ARGV; }   # IMG-001|statement|classification|confidence
        else { die "unknown argument '$a'\n"; }
    }
    if ($gate) {
        die "usage with --gate-check: --incident FILE\n" unless defined $incident_file && $incident_file ne '';
        my $t = _slurp($incident_file);
        my ($ok, $msg) = gate_check_text($t);
        print "$msg\n";
        exit($ok ? 0 : 2);
    }
    my ($up_ok, $up_msg) = upstream_validated();
    die "upstream Phase 10 result not validated ($up_msg) - incident intake BLOCKED\n" unless $up_ok;

    my %spec;
    if (defined $report_file) {
        my $t = eval { _slurp($report_file) };
        die "cannot read --user-report '$report_file'\n" unless defined $t;
        $spec{user_report} = $t;
    } elsif (defined $report_text) {
        $spec{user_report} = $report_text;
    }
    $spec{images} = [];
    for my $p (@image_args) {
        my $sha = eval {
            open my $fh, '<:raw', $p or die $!;
            local $/; my $data = <$fh>; close $fh;
            sha256_hex($data);
        };
        push @{ $spec{images} }, { path => $p, sha256 => $sha };
    }
    for my $raw (@{ $kv{image_obs} || [] }) {
        my ($img, $stmt, $cls, $conf) = split /\|/, $raw, 4;
        push @{ $spec{image_observations}{ $img } }, { statement => $stmt, classification => $cls, confidence => $conf, location => $img };
    }
    my %kmap = (symbol => 'symbol', exchange => 'exchange', timeframe => 'timeframe', timezone => 'timezone',
                'implementation-id' => 'implementation_id', expected => 'expected', observed => 'observed',                 interpretation => 'interpretation', region => 'region', artifact => 'project_artifact',
                 supersedes => 'supersedes');
    for my $k (keys %kmap) { $spec{ $kmap{$k} } = $kv{$k} if defined $kv{$k}; }

    my $r = incident_text(\%spec);
    my $yaml = encode('UTF-8', result_to_yaml($r));
    if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh $yaml; close $fh; }
    else { print $yaml; }
    exit(($r->{phase11_status} eq 'READY' || $r->{phase11_status} eq 'READY_WITH_WARNINGS') ? 0 : 2);
}

# ---------------------------------------------------------------------------
# selftest — mandated acceptance set: INT-001..INT-010 + negative NG-001..NG-008
# (visual_evidence_procedure.md §14)
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };

    my $IMG_SHA = sha256_hex(encode('UTF-8', 'PNGDATA-fixture-one'));
    my $IMG2    = sha256_hex(encode('UTF-8', 'PNGDATA-fixture-two'));

    my $mk = sub {
        my (%o) = @_;
        my %s = (
            user_report   => $o{report},
            images        => $o{images} || [],
            symbol        => $o{symbol},
            exchange      => $o{exchange},
            timeframe     => $o{timeframe},
            implementation_id => $o{impl},
            expected      => $o{expected},
            observed      => $o{observed},
            interpretation => ($o{interp} // $o{interpretation}),
            region        => $o{region},
            supersedes    => $o{supersedes},
        );
        $s{image_observations} = { 'IMG-001' => $o{image_obs} } if $o{image_obs};
        return \%s;
    };

    my $run = sub { my ($s) = @_; return incident_text($s); };
    my $code_has = sub { my ($r, $code) = @_; return scalar grep { ($_->{code} // '') eq $code } @{ $r->{blockers} || [] }; };
    my $warn_has = sub { my ($r, $code) = @_; return scalar grep { ($_->{code} // '') eq $code } @{ $r->{warnings} || [] }; };

    # INT-001: valid image + clear observation -> READY
    {
        my $s = $mk->(
            report => 'Volume expanded here but no Buy signal appeared.',
            images => [ { path => 'chart1.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m',
            expected => 'BUY signal should have appeared',
            observed => 'No visible BUY marker detected in the inspected region',
            region => 'lower volume panel, highlighted zone',
            image_obs => [ { statement => 'green candle visible in the region', classification => 'OBSERVED', confidence => 'HIGH' } ],
        );
        my $r = $run->($s);
        $ok->(defined $r && $r->{phase11_status} eq 'READY', 'INT-001 valid image + clear observation -> READY');
        $ok->($r->{downstream_allowed} eq 'true' && $r->{next_stage} eq 'DATA_ACQUISITION_AND_ALIGNMENT', 'INT-001 downstream open');
        $ok->($r->{incident_id} =~ /^incident-[0-9a-f]{12}$/, 'INT-001 incident_id well-formed');
        my (@vs) = grep { (defined $_->{source_image} && $_->{source_image} eq 'IMG-001') } @{ r_evidence() };
        $ok->(scalar @vs && $vs[0]{classification} eq 'OBSERVED', 'INT-001 image observation classified OBSERVED');
    }

    # INT-002: missing symbol/timeframe -> READY_WITH_WARNINGS (Phase 12 can identify the target)
    {
        my $s = $mk->(
            report => 'The BUY marker is missing on the recent cross.',
            images => [ { path => 'chart2.png', sha256 => $IMG_SHA } ],
            expected => 'BUY marker visible', observed => 'No visible BUY marker detected',
            region => 'recent swing high',
        );
        my $r = $run->($s);
        $ok->($r->{phase11_status} eq 'READY_WITH_WARNINGS', 'INT-002 missing identity -> READY_WITH_WARNINGS');
        $ok->($r->{next_stage} eq 'DATA_ACQUISITION_AND_ALIGNMENT', 'INT-002 downstream still open');
        $ok->((grep { ($_->{description} // '') =~ /NOT_PROVIDED/ } @{ r_limits() }), 'INT-002 NOT_PROVIDED recorded, not fabricated');
        $ok->($r->{symbol} eq 'UNKNOWN' && $r->{symbol_status} eq 'UNKNOWN', 'INT-002 target stays UNKNOWN');
    }

    # INT-003: text-only incident -> READY_WITH_WARNINGS
    {
        my $s = $mk->(
            report => 'No BUY marker on the last cross although volume expanded.',
            expected => 'BUY should appear', observed => 'No visible BUY marker (user report only)',
            region => 'the cross below resistance',
        );
        my $r = $run->($s);
        $ok->($r->{phase11_status} eq 'READY_WITH_WARNINGS', 'INT-003 text-only -> READY_WITH_WARNINGS');
        $ok->($r->{image_present} eq 'false', 'INT-003 image_present false');
        $ok->(!scalar $warn_has->($r, 'W-IMAGE-UNINSPECTED'), 'INT-003 no phantom image warning');
        $ok->(scalar $warn_has->($r, 'W-NO-IMAGE'), 'INT-003 no-image warning recorded');
    }

    # INT-004: no identifiable region + vague description -> INSUFFICIENT_VISUAL_EVIDENCE
    {
        my $s = $mk->(report => 'Something looks wrong sometimes.');
        my $r = $run->($s);
        $ok->($r->{phase11_status} eq 'INSUFFICIENT_VISUAL_EVIDENCE', 'INT-004 vague no-region -> INSUFFICIENT_VISUAL_EVIDENCE');
        $ok->($r->{next_stage} eq 'HALT' && $r->{downstream_allowed} eq 'false', 'INT-004 HALT');
        $ok->($r->{evidence_sufficiency} eq 'INSUFFICIENT', 'INT-004 sufficiency recorded INSUFFICIENT');
    }

    # INT-005: contradiction preserved, never resolved
    {
        my $s = $mk->(
            report => 'The BUY signal appeared right there after the volume expansion.',
            images => [ { path => 'chart5.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m',
            expected => 'BUY marker visible',
            observed => 'No visible BUY marker detected in the inspected region',
            region => 'volume expansion zone',
        );
        my $r = $run->($s);
        $ok->(scalar @{ r_contra() } == 1, 'INT-005 contradiction recorded');
        $ok->((${ r_contra() }[0]{resolution} // '') eq 'NONE_PRESERVED', 'INT-005 resolution NONE_PRESERVED');
        $ok->($r->{phase11_status} eq 'READY_WITH_WARNINGS', 'INT-005 contradiction warns, does not block');
    }

    # INT-006: multiple incidents -> independent records (regions kept separate)
    {
        my $s = $mk->(
            report => "Anomaly one: no visible BUY marker in region A. Anomaly two: no visible SELL marker in region B.",
            images => [ { path => 'chart6.png', sha256 => $IMG_SHA } ],
            symbol => 'ETHUSDT', timeframe => '15m',
            expected => 'one BUY, one SELL', observed => 'No visible BUY marker detected; no visible SELL marker detected',
            region => 'region A and region B',
        );
        my $r = $run->($s);
        $ok->($r->{phase11_status} =~ /^READY/, 'INT-006 multi-anomaly report ingested');
        my $rep = (grep { ($_->{location} // '') eq 'user report (verbatim)' } @{ r_evidence() })[0];
        $ok->(defined $rep && $rep->{statement} =~ /region A/ && $rep->{statement} =~ /region B/, 'INT-006 both regions preserved in evidence');
    }

    # INT-007: identical input -> byte-identical output + identical id
    {
        my $s1 = $mk->(report => 'determinism probe', images => [ { path => 'c.png', sha256 => $IMG_SHA } ],
            symbol => 'X', timeframe => '1h', expected => 'e', observed => 'o', region => 'r');
        my $s2 = $mk->(report => 'determinism probe', images => [ { path => 'c.png', sha256 => $IMG_SHA } ],
            symbol => 'X', timeframe => '1h', expected => 'e', observed => 'o', region => 'r');
        my ($r1, $r2) = ($run->($s1), $run->($s2));
        $ok->($r1->{incident_id} eq $r2->{incident_id}, 'INT-007 incident_id stable');
        $ok->(result_to_yaml($r1) eq result_to_yaml($r2), 'INT-007 byte-identical output');
    }

    # INT-008: different image bytes -> different fingerprint + different id
    {
        my $sA = $mk->(report => 'fp probe', images => [ { path => 'a.png', sha256 => $IMG_SHA } ],
            symbol => 'X', timeframe => '1h', expected => 'e', observed => 'o', region => 'r');
        my $sB = $mk->(report => 'fp probe', images => [ { path => 'b.png', sha256 => $IMG2 } ],
            symbol => 'X', timeframe => '1h', expected => 'e', observed => 'o', region => 'r');
        my ($rA, $rB) = ($run->($sA), $run->($sB));
        $ok->($rA->{images}[0]{image_sha256} ne $rB->{images}[0]{image_sha256}, 'INT-008 fingerprints differ');
        $ok->($rA->{incident_id} ne $rB->{incident_id}, 'INT-008 ids differ');
    }

    # INT-009: missing optional fields -> explicit UNKNOWN/NOT_PROVIDED (no fabrication)
    {
        my $s = $mk->(report => 'No BUY marker on the recent swing high.', region => 'recent swing high',
            expected => 'BUY should show', observed => 'No visible BUY marker detected', images => [ { path => 'c9.png', sha256 => $IMG_SHA } ]);
        my $r = $run->($s);
        $ok->($r->{symbol} eq 'UNKNOWN' && $r->{timeframe} eq 'UNKNOWN', 'INT-009 target UNKNOWN not fabricated');
        $ok->($r->{localization}{bar_index} eq 'UNKNOWN' && $r->{localization}{timestamp} eq 'UNKNOWN', 'INT-009 bar/timestamp UNKNOWN');
        $ok->((grep { ($_->{description} // '') =~ /never invented/ } @{ r_unknowns() }), 'INT-009 unknowns recorded explicitly');
    }

    # INT-010: root-cause inference attempt -> rejected (firewall)
    {
        my $s = $mk->(report => 'The signal did not fire because the repaint mechanism is broken.',
            images => [ { path => 'c10.png', sha256 => $IMG_SHA } ], symbol => 'BTCUSDT', timeframe => '5m',
            expected => 'BUY', observed => 'No visible BUY marker', region => 'r');
        my $r = $run->($s);
        my $out = result_to_yaml($r);
        $ok->($out !~ /[Rr]oot cause/, 'INT-010 no root-cause wording in output');
        $ok->(scalar $warn_has->($r, 'W-ABSENCE-PHRASING'), 'INT-010 runtime claim re-phrased as visual absence');
    }

    # NG-001: visual evidence must not become automatic root cause
    {
        my $s = $mk->(report => 'The indicator failed because volume did not expand.', images => [ { path => 'n1.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m', expected => 'BUY', observed => 'No visible BUY marker', region => 'r');
        my $r = $run->($s);
        $ok->(result_to_yaml($r) !~ /[Rr]oot cause/, 'NG-001 no root-cause derivation');
        $ok->(scalar $warn_has->($r, 'W-ABSENCE-PHRASING'), 'NG-001 runtime claim flagged, not diagnosed');
    }

    # NG-002: unknown timestamp/bar must not be fabricated
    {
        my $s = $mk->(report => 'marker missing', images => [ { path => 'n2.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m', expected => 'BUY', observed => 'none visible', region => 'r');
        my $r = $run->($s);
        $ok->($r->{localization}{bar_index} eq 'UNKNOWN' && $r->{localization}{timestamp} eq 'UNKNOWN', 'NG-002 no fabricated bar/timestamp');
        $ok->($r->{localization}{precision} eq 'APPROXIMATE', 'NG-002 precision honest');
    }

    # NG-003: no visible marker must not become a definite runtime claim
    {
        my $s = $mk->(report => 'The signal did not fire at all.', images => [ { path => 'n3.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m', expected => 'BUY', observed => 'No visible BUY marker', region => 'r');
        my $r = $run->($s);
        $ok->(scalar $warn_has->($r, 'W-ABSENCE-PHRASING'), 'NG-003 runtime claim flagged');
        my ($oev) = grep { ($_->{location} // '') eq 'observed_behavior' } @{ r_evidence() };
        $ok->(defined $oev && $oev->{classification} eq 'USER_REPORTED', 'NG-003 observed stays USER_REPORTED, never runtime OBSERVED');
    }

    # NG-004: user interpretation must not become observed fact
    {
        my $s = $mk->(report => 'Volume expansion should have triggered the BUY.',
            images => [ { path => 'n4.png', sha256 => $IMG_SHA } ], symbol => 'BTCUSDT', timeframe => '5m',
            expected => 'BUY on volume expansion',
            observed => 'No visible BUY marker detected in the inspected region',
            interpretation => 'volume expansion and upward price movement should have triggered BUY',
            region => 'r');
        my $r = $run->($s);
        my ($ie) = grep { ($_->{location} // '') eq 'user_interpretation' } @{ r_evidence() };
        $ok->(defined $ie && $ie->{classification} eq 'USER_REPORTED', 'NG-004 interpretation is USER_REPORTED evidence');
        my (@iobs) = grep { ($_->{location} // '') eq 'user_interpretation' } @{ r_evidence() };
        my @nobs = grep { ($_->{classification} // "") eq "OBSERVED" } @iobs;
        $ok->(!@nobs, "NG-004 interpretation never OBSERVED");
     }

    # NG-005: skill knowledge is never evidence
    {
        my $s = $mk->(report => 'marker missing somewhere', images => [ { path => 'n5.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m', expected => 'BUY', observed => 'none visible', region => 'r');
        my $r = $run->($s);
        my (@srcs) = map { ($_->{source} // '') } @{ r_evidence() };
        my @skillsrc = grep { /SKILL/i } @srcs;
        $ok->(!@skillsrc, q{NG-005 no skill-sourced evidence});
        my @badsrc = grep { !/^(CHART_IMAGE|USER_TEXT|USER_MARKED_REGION|PROJECT_ARTIFACT|UNKNOWN)$/ } @srcs;
        $ok->(!@badsrc, q{NG-005 provenance enum respected});
     }

    # NG-006: market data retrieval is never a Phase 11 action
    {
        my $s = $mk->(report => 'check the OHLCV and fetch candle data to verify the missing BUY marker', images => [ { path => 'n6.png', sha256 => $IMG_SHA } ],
            symbol => 'BTCUSDT', timeframe => '5m', expected => 'BUY', observed => 'none visible', region => 'r');
        my $r = $run->($s);
        $ok->($r->{next_stage} eq 'DATA_ACQUISITION_AND_ALIGNMENT', 'NG-006 data acquisition stays Phase 12');
        $ok->((grep { ($_->{check_id} // '') =~ /^INT-G/ } @{ $r->{checks} }), 'NG-006 checks run without fetching anything');
    }

    # NG-007: invalid input -> INVALID_INPUT, exit-2 semantics
    {
        my $r = $run->({ parse_error => 'at least one of user_report / chart_image must be supplied' });
        $ok->($r->{phase11_status} eq 'INVALID_INPUT' && $r->{next_stage} eq 'HALT', 'NG-007 INVALID_INPUT halts');
        $ok->($r->{downstream_allowed} eq 'false', 'NG-007 downstream denied');
        $ok->($code_has->($r, 'B-INPUT'), 'NG-007 B-INPUT recorded');
    }

    # NG-008: repair/code-modification is never offered or performed by Phase 11
    {
        my $s = $mk->(report => 'Please repair the indicator and fix the code so it works.',
            images => [ { path => 'n8.png', sha256 => $IMG_SHA } ], symbol => 'BTCUSDT', timeframe => '5m',
            expected => 'BUY', observed => 'No visible BUY marker', region => 'r');
        my $r = $run->($s);
        my $out = result_to_yaml($r);
        my $engine_out = $out;
        $engine_out =~ s/^    user_report: .*$//m;   # verbatim user text is preserved, never filtered
        $engine_out =~ s/^  normalized_user_observation: .*$//m; # normalization of the same verbatim text
        $engine_out =~ s/^    - \{ evidence_id: .*statement: .*\}$//mg; # evidence entries quoting the verbatim report
        $ok->($engine_out !~ /repair the (indicator|code)|I will (fix|repair)|fix the code/i, 'NG-008 no repair action offered by the engine');
        $ok->($out =~ /^\s{4}user_report: '.*repair the indicator/m, 'NG-008 user report still preserved verbatim');
        $ok->($r->{phase11_status} =~ /^READY/, 'NG-008 intake completes without repairing anything');
    }

    # ===========================================================================
    # REV 2 - corrected-identity re-intake (AUSDT.P / KCEX): the previous
    # incident (BTCUSDT) must stay preserved; the new incident gets its own
    # deterministic id; nothing is inherited from the old target.
    # ===========================================================================
    my $OLD_IID   = 'incident-940ef2698dda';
    my $IMG_OLD   = '04daea13253a1e2ef3c23532d3b0fc21099665d8cefb1bcb6c3a6dc98d10178b';  # evidence screenshot sha256
    my $ARCHIVE   = dirname(__FILE__) . '/archive/phase11_incident_BTCUSDT_940ef2698dda.yaml';
    my $SCREENSHOT = dirname(__FILE__) . '/evidence/Screenshot 2026-09-11 074631.png';
    my $raw_sha = sub { my $f = shift; return '' unless -f $f; open my $fh, '<:raw', $f or return ''; local $/; my $d = <$fh>; close $fh; return sha256_hex($d); };
    my $corr = sub {
        my (%o) = @_;
        return $mk->(
            report    => $o{report} // 'Identity-corrected re-intake of the same evidence package: in the highlighted region a BUY signal should have appeared but no visible BUY marker is detected in the inspected region.',
            images    => [ { path => $SCREENSHOT, sha256 => $IMG_OLD } ],
            symbol    => $o{symbol} // 'AUSDT.P',
            exchange  => $o{exchange} // 'KCEX',
            timeframe => $o{timeframe} // '5m',
            expected  => $o{expected} // 'BUY signal should have appeared',
            observed  => $o{observed} // 'No visible BUY marker detected in the inspected region',
            region    => $o{region} // 'lower volume panel, highlighted zone',
            supersedes => $o{supersedes} // $OLD_IID,
        );
    };

    # INT-REV2-001/002: corrected target accepted verbatim, downstream open
    {
        my $r = $run->($corr->());
        $ok->($r->{phase11_status} =~ /^READY/, 'INT-REV2-001 corrected AUSDT.P target accepted');
        $ok->($r->{downstream_allowed} eq 'true' && $r->{next_stage} eq 'DATA_ACQUISITION_AND_ALIGNMENT', 'INT-REV2-001 downstream open for Phase 12');
        $ok->($r->{symbol} eq 'AUSDT.P' && $r->{symbol_status} eq 'USER_REPORTED', 'INT-REV2-001 AUSDT.P preserved verbatim');
        $ok->($r->{exchange} eq 'KCEX' && $r->{exchange_status} eq 'USER_REPORTED', 'INT-REV2-002 KCEX exchange preserved');
    }

    # INT-REV2-003/004: previous incident preserved; new id differs; supersedes link only
    {
        my $a0 = eval { _slurp($ARCHIVE) } // '';
        my $r = $run->($corr->());
        my $a1 = eval { _slurp($ARCHIVE) } // '';
        $ok->($a0 ne '' && $a0 eq $a1, 'INT-REV2-003 previous BTCUSDT incident preserved (archive byte-identical)');
        $ok->($r->{incident_id} ne $OLD_IID, 'INT-REV2-004 new incident_id differs from old incident_id');
        $ok->(($r->{supersedes} // '') eq $OLD_IID, 'INT-REV2-004 supersedes records the link, nothing mutated');
    }

    # INT-REV2-005: target identity does not inherit BTCUSDT (old target != new target)
    {
        my $old_text = eval { _slurp($ARCHIVE) } // '';
        my ($old_sym) = $old_text =~ /^    symbol: '([^']*)'/m;
        my $r = $run->($corr->());
        $ok->(defined $old_sym && $old_sym eq 'BTCUSDT', 'INT-REV2-005 old incident target read as BTCUSDT');
        $ok->($r->{symbol} ne $old_sym && $r->{symbol} eq 'AUSDT.P', 'INT-REV2-005 old target != new target; no inheritance');
        $ok->(result_to_yaml($r) !~ /BTCUSDT/, 'INT-REV2-005 corrected contract carries no BTCUSDT anywhere');
    }

    # INT-REV2-006/007/008: screenshot as CHART_IMAGE evidence; never OHLCV; no causal wording
    {
        my $r = $run->($corr->());
        my (@ce) = grep { ($_->{source} // '') eq 'CHART_IMAGE' } @{ r_evidence() };
        $ok->(scalar @ce >= 1 && (grep { ($_->{source_image} // '') eq 'IMG-001' } @ce) >= 1, 'INT-REV2-006 screenshot registered as CHART_IMAGE evidence (IMG-001)');
        my $out = result_to_yaml($r);
        $ok->($out !~ /^\s{4,}(open|high|low|close|volume):/m && $out !~ /\bOHLC(V)?\b/i, 'INT-REV2-007 screenshot not treated as authoritative OHLCV');
        $ok->($out !~ /root cause/i, 'INT-REV2-008 no causal/root-cause wording accepted in engine output');
    }

    # INT-REV2-009: localization uncertainty preserved (no invented bar/timestamp)
    {
        my $r = $run->($corr->());
        $ok->($r->{localization}{method} eq 'USER_POINTED' && $r->{localization}{precision} eq 'APPROXIMATE', 'INT-REV2-009 localization stays approximate (USER_POINTED)');
        $ok->($r->{localization}{bar_index} eq 'UNKNOWN' && $r->{localization}{timestamp} eq 'UNKNOWN', 'INT-REV2-009 bar/timestamp stay UNKNOWN');
    }

    # INT-REV2-010: deterministic three-run identity
    {
        my $spec = $corr->();
        my @ids  = map { $run->($spec)->{incident_id} } 1 .. 3;
        $ok->($ids[0] eq $ids[1] && $ids[1] eq $ids[2] && $ids[0] =~ /^incident-[0-9a-f]{12}$/, 'INT-REV2-010 deterministic three-run identity');
        my @ys  = map { result_to_yaml($run->($spec)) } 1 .. 2;
        $ok->($ys[0] eq $ys[1], 'INT-REV2-010 byte-identical contracts across runs');
    }

    # INT-REV2-011: Phase 1-10 artifacts unchanged (Pine d62af444..., Phase 10 still validated)
    {
        my $ph = $raw_sha->('implementation/phase9_pine.pine');
        $ok->($ph =~ /^d62af444/, 'INT-REV2-011 Phase 9 Pine hash unchanged (d62af444...)');
        my $p10 = eval { _slurp('verification/phase10_post_verification_result.yaml') } // '';
        $ok->($p10 =~ /^\s{2}verdict:\s*validated/m, 'INT-REV2-011 Phase 10 result still validated');
    }

    # INT-REV2-012: previous Phase 11 incident + evidence byte-unchanged
    {
        $ok->($raw_sha->($ARCHIVE) eq '2c6822dc6d063fd3170667ce8054658c2a6a64f1421c4c7a3f90d0d82bb390b4', 'INT-REV2-012 archived BTCUSDT incident byte-unchanged');
        $ok->($raw_sha->($SCREENSHOT) eq $IMG_OLD, 'INT-REV2-012 evidence screenshot byte-unchanged');
    }

    # NG-REV2-001: BTCUSDT silently substituted for AUSDT.P
    {
        my $r = $run->($corr->(report => 'Corrected re-intake: a BUY signal was expected in the region; none is visible.'));
        $ok->($r->{symbol} eq 'AUSDT.P', 'NG-REV2-001 target is AUSDT.P, never substituted');
        $ok->(result_to_yaml($r) !~ /BTCUSDT/, 'NG-REV2-001 no BTCUSDT substitution anywhere in the contract');
    }

    # NG-REV2-002: AUSDT.P silently changed to another symbol (normalization forbidden)
    {
        my $r = $run->($corr->());
        my $out = result_to_yaml($r);
        $ok->(index($out, q{'AUSDT.P'}) >= 0, 'NG-REV2-002 AUSDT.P preserved verbatim');
        $ok->($out !~ /AUSDT(?!\.P)/, 'NG-REV2-002 no normalization drops the .P suffix');
    }

    # NG-REV2-003: KCEX omitted must stay UNKNOWN (never inferred from unrelated evidence)
    {
        my $r = $run->($mk->(
            report    => 'Identity-corrected re-intake; no exchange supplied.',
            images    => [ { path => $SCREENSHOT, sha256 => $IMG_OLD } ],
            symbol    => 'AUSDT.P',
            timeframe => '5m',
            expected  => 'BUY signal should have appeared',
            observed  => 'No visible BUY marker detected in the inspected region',
            region    => 'lower volume panel, highlighted zone',
            supersedes => $OLD_IID,
        ));
        $ok->($r->{exchange} eq 'UNKNOWN' && $r->{exchange_status} eq 'UNKNOWN', 'NG-REV2-003 KCEX not inferred when omitted');
    }

    # NG-REV2-004: screenshot converted into OHLCV
    {
        my $r = $run->($corr->());
        my $out = result_to_yaml($r);
        $ok->($out !~ /\b(open|high|low|close|volume):\s*[0-9]/, 'NG-REV2-004 no OHLCV values derived from the screenshot');
        $ok->(!(grep { ($_->{classification} // '') eq 'OBSERVED' && ($_->{statement} // '') =~ /[0-9]{3,}/ } @{ r_evidence() }), 'NG-REV2-004 no numeric OHLC claims in evidence');
    }

    # NG-REV2-005: causal/root-cause claim inserted
    {
        my $r = $run->($corr->(observed => 'root cause: the volume condition blocked the marker'));
        $ok->($r->{phase11_status} eq 'BLOCKED', 'NG-REV2-005 causal/root-cause claim rejected (BLOCKED)');
        $ok->((grep { ($_->{code} // '') eq 'B-INTAKE' } @{ $r->{blockers} }) >= 1, 'NG-REV2-005 firewall blocker recorded');
    }

    # NG-REV2-006: previous incident overwritten
    {
        my $h0 = $raw_sha->($ARCHIVE);
        $run->($corr->());
        $run->($corr->(symbol => 'ETHUSDT.P'));
        my $h1 = $raw_sha->($ARCHIVE);
        $ok->($h0 ne '' && $h0 eq $h1, 'NG-REV2-006 archived incident not overwritten by any intake');
    }

    # NG-REV2-007: old incident_id reused
    {
        my $r = $run->($corr->());
        $ok->($r->{incident_id} ne $OLD_IID, 'NG-REV2-007 old incident_id never reused');
    }

    print "SELFTEST: $pass passed, $fail failed\n";
    print "All INT-001..010 + NG-001..008 + INT-REV2-001..012 + NG-REV2-001..007 acceptance cases pass (incident contract v1.0, REV 2 corrected identity).\n" if !$fail;
    return $fail ? 1 : 0;
}

main() unless caller;
1;
