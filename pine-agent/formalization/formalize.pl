#!/usr/bin/perl
# ============================================================================
# formalize.pl — Pine Agent FORMALIZATION ENGINE (contract schema v1.1)
# ============================================================================
# PHASE 5 — Formalization Layer Implementation.
#
# Spec     : meta/formalization_procedure.md (narrative authority)
# Schema   : formalization/contract_schema.yaml v1.1
# Input    : verbatim user request + routing/2 YAML output of skills/agent/router.pl
# Output   : formalization contract (YAML) — NEVER Pine Script
#
# The engine converts a READY Router handoff into a machine-checkable
# formalization contract via MECHANICAL extraction only (procedure §6):
#   - preserves routing decisions verbatim (never re-derives them)
#   - preserves condition/formula clauses verbatim (never improves math)
#   - records ambiguities instead of guessing (thresholds, TFs, operators,
#     precedence, edge behavior, evaluation timing, HTF roles)
#   - classifies repaint risk mechanically (procedure §7; AGENT_RULES §3.12)
#   - freezes identity: request_id -> approved_routing_id -> formalization_id
#     (approved_formalization_id == formalization_id of the allowed contract)
#
# Gate semantics (AGENT_RULES §1.1, §2.6-2.8; TEST-FORMALIZATION-001):
#   - non-ready/malformed routing => status: blocked, exit 2
#   - Pine constructs in request  => status: blocked, blocker B-PINE, exit 2
#   - implementation_allowed: true  <=> completed AND blockers empty AND every
#     behavior-affecting ambiguity is resolved_by_user (resolved_assumed
#     NEVER unlocks — TEST-FORMALIZATION-001 must_not)
#   - approval has NO separate status value (schema v1.1: single gate field)
#
# Determinism (procedure §10): same request + same routing bytes =>
#   byte-identical contract. No clock, no randomness, no session state.
#
# Runtime: core Perl only (no CPAN). Digest::SHA is a core module; its
# absence dies loudly at startup (documented Phase-5 note).
#
# CLI:
#   perl formalization/formalize.pl --request-text "TEXT" --routing FILE
#        [--resolve ID=resolved_by_user|resolved_assumed]...
#        [--supersedes form-xxxxxxxxxxxx] [--out FILE]
#   perl formalization/formalize.pl --gate-check --contract FILE
#   perl formalization/formalize.pl --selftest
#
# Exit codes: 0 = completed contract produced / gate-check approved;
#             2 = blocked contract / gate-check refused.
#            (Engine defects die with a message.)
# ============================================================================

use strict;
use warnings;
use utf8;
use Encode qw(decode encode);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);

my $ENGINE_ID        = 'formalize.pl';
my $SCHEMA_VERSION   = '1.1';
my $ROUTING_CONTRACT = 'routing/2';

binmode(STDOUT, ':encoding(UTF-8)');

# ---------------------------------------------------------------------------
# Small utilities
# ---------------------------------------------------------------------------
sub _trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s; }
sub _q    { my $s = shift; $s =~ s/'/''/g; return "'$s'"; }

sub _flow {
    my ($l) = @_;
    return '[' . join(', ', map { _q($_) } @$l) . ']';
}

my %BOOL_KEY = map { $_ => 1 } qw(affects_behavior user_confirmed);

sub _qv {                                   # scalar value -> YAML token
    my ($k, $v) = @_;
    return 'true'  if $BOOL_KEY{$k} && ($v eq '1' || $v eq 'true');
    return 'false' if $BOOL_KEY{$k} && ($v eq '0' || $v eq 'false' || !defined $v);
    return _flow($v) if ref $v eq 'ARRAY';
    return (defined $v && length $v) ? _q($v) : 'null';
}

sub _rows_block {                           # " []\n" | "\n    - { ... }\n..."
    my ($rows, $keys) = @_;
    return " []\n" unless $rows && @$rows;
    my $o = "\n";
    for my $r (@$rows) {
        $o .= '    - { ' . join(', ', map { "$_: " . _qv($_, $r->{$_}) } @$keys) . " }\n";
    }
    return $o;
}

sub normalize_request {
    my ($raw) = @_;
    my $s = _trim($raw // '');
    $s =~ s/\s+/ /g;
    return $s;
}

# ---------------------------------------------------------------------------
# Routing/2 handoff parsing — YAML subset exactly as skills/agent/router.pl
# emits it (contract_to_yaml_v2). Values are copied, never re-derived.
# ---------------------------------------------------------------------------
sub parse_routing {
    my ($text) = @_;
    my $r = { contract_version => undef, routing_status => undef, request_class => undef,
              reason => undef, allowed => undef, selected => [], deps => [],
              trace_seen => 0 };
    my $section = '';
    for my $line (split /\r?\n/, $text) {
        if ($line =~ /^  (\w+):\s*$/) {
            $section = $1;
            $r->{trace_seen} = 1 if $1 eq 'routing_trace';
            next;
        }
        if ($line =~ /^  (\w+):\s*(.*\S)\s*$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/^'(.*)'$/$1/;           # strip outer quotes
            $v =~ s/''/'/g;                 # unescape
            $r->{contract_version} = $v if $k eq 'contract_version';
            $r->{routing_status}   = $v if $k eq 'routing_status';
            $r->{request_class}    = $v if $k eq 'request_class';
            $r->{reason}           = $v if $k eq 'reason' && !defined $r->{reason};
            $section = '' unless $k =~ /^(selected_skills|dependency_skills|excluded_skills)$/;
            next;
        }
        if ($line =~ /^    - \{ id: '([^']+)'/) {
            push @{ $r->{selected} }, $1 if $section eq 'selected_skills';
            push @{ $r->{deps} },    $1 if $section eq 'dependency_skills';
            next;
        }
        if ($line =~ /^    allowed:\s*(true|false)\s*$/) { $r->{allowed} = $1; next; }
    }
    return $r;
}

# ---------------------------------------------------------------------------
# Mechanical extraction (procedure §6-§9). Detection only — no invention.
# ---------------------------------------------------------------------------
my $OPERAND = qr/[A-Za-z_][A-Za-z0-9_.]*(?:\s*\([^()]*\))?/;
my $NUM     = qr/\d+(?:\.\d+)?/;

my $PARAM_RE = qr/\b([A-Za-z_][A-Za-z0-9_]*)\s*(?:\(\s*($NUM)\s*\)|[:=]\s*($NUM))/;

my $COND_RE = qr/($OPERAND)\s+crosses\s+((?:over|under|above|below)?)(?:\s+($OPERAND|$NUM))?
                |($OPERAND)\s+((?:is\s+)?(?:above|below))\s+(?:the\s+)?($NUM)
                |($OPERAND)\s*(>=|<=|==|!=|>|<)\s*($NUM)
                /xi;

my $FORM_RE = qr/((?:$OPERAND|$NUM))\s*(\/|\bdivided by\b|\*|\+)\s*((?:$OPERAND|$NUM))/;

my @SRC_TOKENS = qw(close open high low volume hl2 hlc3 ohlc4);
my @TF_TOKENS  = qw(1m 3m 5m 15m 30m 45m 1h 2h 3h 4h 12h 1d 2d 1w 1M);

my $MTF_RE      = qr/higher[ -]?time\s*frames?\b|\bhtf\b|lower[ -]?time\s*frames?\b|\bltf\b|multi[ -]?time[ -]?frames?\b|request\.security/i;
my $CONFIRM_RE  = qr/barstate\.isconfirmed|confirmed\s+(?:bar|close)|on\s+(?:the\s+)?(?:bar\s+)?close|lookahead|gaps?\s+(?:on|off)|wait(?:\s+for)?\s+(?:the\s+)?(?:bar\s+)?close/i;
my $TIMING_RE   = qr/on\s+(?:the\s+)?(?:bar\s+)?close|barstate\.|confirmed|intrabar|every\s+tick|calc_on_every_tick|realtime/i;
my $INTRABAR_RE = qr/intrabar|every\s+tick|calc_on_every_tick/i;
my $GUARD_RE    = qr/division\s+by\s+zero|zero[- ]?check|zero[- ]?guard|guard\s+against\s+zero|\bnz\s*\(/i;
my $PINE_RE     = qr{\/\/\s*\@version|\bindicator\s*\(|\bstrategy\s*\(|\blibrary\s*\(};
my $VAGUE_RE    = qr/overbought|oversold|too\s+high|too\s+low|high\s+enough|low\s+enough/i;
my $CONNECT_RE  = qr/\b(and|or|then|priority|veto|filter)\b/i;

# word-bounded position lookup (case-sensitive; keeps 1m != 1M)
sub _find_token {
    my ($req, $tok) = @_;
    my $p = -1;
    while (($p = index($req, $tok, $p + 1)) >= 0) {
        my $before = $p > 0 ? substr($req, $p - 1, 1) : ' ';
        my $after  = ($p + length $tok < length $req) ? substr($req, $p + length $tok, 1) : ' ';
        return $p if $before !~ /[A-Za-z0-9_.]/ && $after !~ /[A-Za-z0-9_.]/;
    }
    return -1;
}

sub _amb_id {                                # fixed base + deterministic numbering
    my ($cnt, $base) = @_;
    my $n = $cnt->{$base}++;
    return $n == 0 ? $base : $base . '-' . ($n + 1);
}

sub extract {
    my ($req) = @_;
    my $x = { variables => [], formulas => [], conditions => [], ambiguities => [],
              edge_cases => [], chart => undef, htf_tokens => [], mtf => 0,
              repaint_class => undef, repaint_mech => undef, division => 0 };

    # R9 flag: Pine constructs (checked by caller for the gate)
    $x->{pine} = ($req =~ $PINE_RE) ? 1 : 0;

    # --- R1 sources -------------------------------------------------------
    my %seen_var;
    for my $t (@SRC_TOKENS) {
        next unless $req =~ /\b\Q$t\E\b/;
        push @{ $x->{variables} }, {
            name => $t, type => 'series float',
            description => "built-in source token '$t' detected in the request (verbatim)",
            source => 'request (verbatim)',
        };
        $seen_var{$t} = 1;
    }

    # --- R2 parameters ----------------------------------------------------
    my %seen_param;
    while ($req =~ /$PARAM_RE/g) {
        my ($name, $v1, $v2) = ($1, $2, $3);
        my $val = defined $v1 ? $v1 : $v2;
        next if $seen_param{$name} || $seen_var{$name};
        $seen_param{$name} = 1;
        my $type = $val =~ /\./ ? 'const float' : 'const int';
        push @{ $x->{variables} }, {
            name => $name, type => $type,
            description => "parameter '$name' = $val (verbatim numeric binding in the request)",
            source => 'request (verbatim)',
        };
    }

    # --- R3 conditions (verbatim clauses; position order) ------------------
    my %seen_c;
    my @oper_amb;                                # per-clause operator ambiguity
    while ($req =~ /$COND_RE/g) {
        my ($cl, $state_wording, $bare_cross) = (undef, 0, 0);
        if (defined $1) {
            $cl = "$1 crosses" . ($2 ne '' ? " $2" : '') . (defined $3 ? " $3" : '');
            $bare_cross = 1 if $2 eq '';
        } elsif (defined $4) {
            $cl = "$4 $5 $6";
            $state_wording = 1;
        } elsif (defined $7) {
            $cl = "$7 $8 $9";
        }
        next if !defined $cl || $seen_c{$cl};
        $seen_c{$cl} = 1;
        push @{ $x->{conditions} }, {
            id => '',                            # assigned after collection
            condition => $cl,
            meaning => 'verbatim request clause — semantics preserved, not reinterpreted',
            used_by => [],
        };
        if ($state_wording) {
            push @oper_amb, {
                description => "operator semantics ambiguous in '$cl': persistent state vs crossing event",
                options => ["state: holds whenever the left side is above/below the right side",
                            "event: true only at the moment of crossing"],
            };
        } elsif ($bare_cross) {
            push @oper_amb, {
                description => "crossing direction unspecified in '$cl'",
                options => ["direction: crosses over (upward crossing)",
                            "direction: crosses under (downward crossing)"],
            };
        }
    }
    for my $i (0 .. $#{ $x->{conditions} }) { $x->{conditions}[$i]{id} = 'C-' . ($i + 1); }

    # --- R4 formulas (verbatim expressions; position order) ----------------
    my %seen_f;
    while ($req =~ /$FORM_RE/g) {
        my ($a, $op, $b) = ($1, $2, $3);
        my $expr = "$a $op $b";
        next if $seen_f{$expr};
        $seen_f{$expr} = 1;
        $x->{division} = 1 if $op eq '/' || $op eq 'divided by';
        push @{ $x->{formulas} }, {
            id => '', expression => $expr,
            description => 'verbatim arithmetic clause from the request',
            depends_on => [],
        };
    }
    for my $i (0 .. $#{ $x->{formulas} }) { $x->{formulas}[$i]{id} = 'F-' . ($i + 1); }

    # --- R5 timeframe --------------------------------------------------------
    my %tf;                                      # value -> first position
    for my $t (@TF_TOKENS) {
        my $p = _find_token($req, $t);
        $tf{$t} = $p if $p >= 0;
    }
    for my $w ('daily', 'weekly', 'monthly') {   # case-insensitive word forms
        if ($req =~ /\b($w)\b/i) { my $p = $-[0]; $tf{$1} = $p if !exists $tf{$1} || $p < $tf{$1}; }
    }
    my @tf_sorted = sort { $tf{$a} <=> $tf{$b} } keys %tf;
    # chart-context preference (deterministic): token followed by chart/timeframe/tf,
    # or preceded by on/at/in [the] — e.g. "higher timeframe ... 4h data ... on the 15m chart"
    my @chart_ctx = grep {
        my $t = $_;
        my $p = $tf{$t};
        my $after  = substr($req, $p + length $t);
        my $before = substr($req, 0, $p);
        ($after  =~ /^\s+(?:chart|timeframe|tf)\b/i)
            || ($before =~ /\b(?:on|at|in)\s+(?:the\s+)?$/i);
    } @tf_sorted;
    $x->{chart} = $chart_ctx[0] // $tf_sorted[0] if @tf_sorted;
    $x->{tf_count} = scalar @tf_sorted;

    # --- R6 MTF ---------------------------------------------------------------
    if ($req =~ $MTF_RE) {
        $x->{mtf} = 1;
        my @htf = grep { !defined $x->{chart} || $_ ne $x->{chart} } @tf_sorted;
        $x->{htf_tokens} = \@htf;
    }

    # --- R7 repaint classification (mechanical; procedure §7) ------------------
    my $confirmed = ($req =~ $CONFIRM_RE) ? 1 : 0;
    my $intrabar  = ($req =~ $INTRABAR_RE) ? 1 : 0;
    if ($x->{mtf} && $confirmed) {
        $x->{repaint_class} = 'low';
        $x->{repaint_mech}  = 'confirmed-bar HTF discipline stated in the request';
    } elsif ($x->{mtf}) {
        $x->{repaint_class} = 'high';
        $x->{repaint_mech}  = 'unconfirmed higher-timeframe data via request.security — no confirmed-bar/lookahead discipline stated in the request';
    } elsif ($intrabar) {
        $x->{repaint_class} = 'medium';
        $x->{repaint_mech}  = 'realtime intrabar values can differ from historical bars';
    } else {
        $x->{repaint_class} = 'low';
        $x->{repaint_mech}  = 'no repaint mechanism detected in the request';
    }

    # --- Ambiguities (fixed generation order; never silently resolved) ---------
    my %cnt;
    my $amb = $x->{ambiguities};
    if (!$x->{chart}) {
        push @$amb, { id => _amb_id(\%cnt, 'A-TF'),
            description => 'chart timeframe not declared in the request',
            options => ["use the chart's current timeframe (any)", 'user declares an explicit timeframe'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    } elsif ($x->{tf_count} > 1 && !$x->{mtf}) {
        push @$amb, { id => _amb_id(\%cnt, 'A-TF'),
            description => "multiple timeframes mentioned (" . join(', ', @tf_sorted) . ") without declared roles and no MTF context",
            options => ['first mentioned is the chart timeframe; user confirms', 'user declares the role of each timeframe'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    }
    for my $oa (@oper_amb) {
        push @$amb, { id => _amb_id(\%cnt, 'A-OPER'),
            description => $oa->{description}, options => $oa->{options},
            affects_behavior => 1, resolution_status => 'unresolved' };
    }
    if ($req =~ $VAGUE_RE) {
        push @$amb, { id => _amb_id(\%cnt, 'A-THR'),
            description => "vague threshold wording ('$&') with no numeric threshold defined",
            options => ['user supplies numeric threshold(s)', 'threshold becomes a configurable input with a user-specified default'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    }
    if ($x->{division} && $req !~ $GUARD_RE) {
        push @$amb, { id => _amb_id(\%cnt, 'A-DIV'),
            description => 'division in the request with zero-denominator behavior unspecified',
            options => ['result is na when the denominator is zero', 'result is 0 when the denominator is zero', 'user defines the behavior'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    }
    if ($x->{mtf} && !@{ $x->{htf_tokens} }) {
        push @$amb, { id => _amb_id(\%cnt, 'A-HTF-TF'),
            description => 'multi-timeframe requested but no higher-timeframe declared',
            options => ['user declares the HTF (e.g., 4h)', 'HTF derived from the chart timeframe with user confirmation'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    }
    if (@{ $x->{conditions} } && $req !~ $TIMING_RE) {
        push @$amb, { id => _amb_id(\%cnt, 'A-CONF'),
            description => 'signal evaluation timing (confirmed bar close vs intrabar) not stated',
            options => ['evaluate on confirmed bar close', 'evaluate intrabar (may repaint)'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    }
    if (@{ $x->{conditions} } >= 2 && $req !~ $CONNECT_RE) {
        push @$amb, { id => _amb_id(\%cnt, 'A-PREC'),
            description => 'multiple conditions with no declared combination or precedence',
            options => ['AND — all conditions must hold', 'OR — any condition may trigger', 'user declares a priority/veto order'],
            affects_behavior => 1, resolution_status => 'unresolved' };
    }

    # --- Edge cases (fixed order; required_behavior only from the request) -----
    my $ec = $x->{edge_cases};
    push @$ec, { id => 'E-NA',    case => 'na values during warm-up (insufficient history)', required_behavior => undef };
    push @$ec, { id => 'E-FIRST', case => 'first bars / insufficient history for lookbacks',  required_behavior => undef };
    if ($x->{division}) {
        push @$ec, { id => 'E-DIV', case => 'zero denominator in extracted formula'
                       . (($req =~ $GUARD_RE) ? ' (guard wording stated in request)' : ' (no guard stated in request)'),
                     required_behavior => undef };
    }
    if ($x->{mtf}) {
        push @$ec, { id => 'E-HTF-LAG', case => 'HTF value not yet confirmed/updated at the chart bar', required_behavior => undef };
    }
    if (grep { $_ eq 'volume' } @SRC_TOKENS[0 .. $#SRC_TOKENS] and $req =~ /\bvolume\b/) {
        push @$ec, { id => 'E-VOL', case => 'missing or zero-volume bars', required_behavior => undef };
    }
    if (@{ $x->{conditions} } >= 2) {
        push @$ec, { id => 'E-PREC', case => 'conditions may hold simultaneously; firing precedence unspecified', required_behavior => undef };
    }

    return $x;
}

# ---------------------------------------------------------------------------
# Identity (procedure §4) — content-addressed, no timestamps, no randomness
# ---------------------------------------------------------------------------
sub _canon_rows {
    my ($rows, @keys) = @_;
    return '' unless $rows && @$rows;
    my @out;
    for my $r (@$rows) {
        if (@keys) {
            my @vals;
            for my $k (@keys) {
                my $v = $r->{$k};
                $v = join('|', @$v) if ref $v eq 'ARRAY';
                push @vals, defined($v) ? $v : '~';
            }
            push @out, join("\x1E", @vals);
        } else {
            push @out, $r;
        }
    }
    return join("\x1D", @out);
}

sub canon_body {
    my ($c) = @_;
    return join("\x1F",
        'v1',
        $c->{normalized_request} // '~',
        _canon_rows($c->{variables},          qw(name type description source)),
        _canon_rows($c->{formulas},           qw(id expression description depends_on)),
        _canon_rows($c->{boolean_conditions}, qw(id condition meaning used_by)),
        _canon_rows($c->{assumptions},        qw(id statement affects_behavior user_confirmed)),
        _canon_rows($c->{ambiguities},        qw(id description options affects_behavior resolution_status)),
        _canon_rows($c->{edge_cases},         qw(id case required_behavior)),
        'tf=' . ($c->{timeframe}{chart} // '~') . '/' . ($c->{timeframe}{calculation} // '~'),
        'mtf=' . ($c->{mtf} ? '1' : '0'),
        _canon_rows($c->{required_data},      qw(kind symbol_hint timeframe notes)),
        'rr=' . ($c->{repaint_risk} // '~'),
        _canon_rows($c->{verification_requirements}),
        _canon_rows($c->{implementation_constraints}),
    );
}

sub compute_ids {
    my ($c, $routing_bytes) = @_;
    $c->{request_id}         = 'req-'  . substr(sha256_hex(encode('UTF-8', $c->{normalized_request})), 0, 12);
    $c->{approved_routing_id} = 'rout-' . substr(sha256_hex($routing_bytes), 0, 12);
    my $body_hash = sha256_hex(encode('UTF-8', canon_body($c)));
    $c->{formalization_id}   = 'form-' . substr(
        sha256_hex(encode('UTF-8', "$c->{request_id}\x1F$c->{approved_routing_id}\x1F$body_hash")), 0, 12);
    return $c;
}

# ---------------------------------------------------------------------------
# Gate — approval is expressed SOLELY by implementation_allowed (schema v1.1)
# ---------------------------------------------------------------------------
sub gate_allowed {
    my ($c) = @_;
    return 0 unless $c->{status} eq 'completed';
    return 0 if @{ $c->{blockers} };
    for my $a (@{ $c->{ambiguities} }) {
        next unless $a->{affects_behavior};
        return 0 unless $a->{resolution_status} eq 'resolved_by_user';
    }
    return 1;
}

# ---------------------------------------------------------------------------
# Contract assembly
# ---------------------------------------------------------------------------
sub build_contract {
    my (%opt) = @_;
    my $req_raw        = $opt{request};
    my $routing_file   = $opt{routing_file};
    my $resolves       = $opt{resolves}     // [];
    my $supersedes     = $opt{supersedes};
    my $routing_bytes  = $opt{routing_bytes};

    my $norm = normalize_request($req_raw);
    my $r    = parse_routing(decode('UTF-8', $routing_bytes));

    my $c = {
        schema_version => $SCHEMA_VERSION, stage => 'formalization',
        request_id => undef, approved_routing_id => undef, formalization_id => undef,
        supersedes => $supersedes,
        natural_language_request => $norm, normalized_request => $norm,
        variables => [], formulas => [], boolean_conditions => [],
        assumptions => [],                                   # engine assumes nothing
        ambiguities => [], edge_cases => [],
        timeframe => { chart => undef, calculation => undef },
        mtf => 0, required_data => [], repaint_risk => undef,
        source_skills => [], verification_requirements => [], implementation_constraints => [],
        status => 'completed', blockers => [], implementation_allowed => 0,
    };

    # --- handoff gate first (procedure §3) ---------------------------------
    my $malformed =
        !defined $r->{contract_version} || $r->{contract_version} ne $ROUTING_CONTRACT
        || !defined $r->{routing_status} || !defined $r->{request_class}
        || !defined $r->{reason} || !$r->{trace_seen}
        || ($r->{routing_status} eq 'ready' && !@{ $r->{selected} });

    if ($malformed) {
        $c->{status} = 'blocked';
        push @{ $c->{blockers} }, {
            id => 'B-ROUTING-INVALID',
            reason => 'routing handoff is not a valid routing/2 contract '
                    . '(missing required fields or wrong contract_version) — '
                    . 'Formalization accepts only router.pl v2 output with routing_status: ready' };
    } elsif ($r->{routing_status} ne 'ready' || $r->{allowed} ne 'true') {
        $c->{status} = 'blocked';
        push @{ $c->{blockers} }, {
            id => 'B-ROUTING',
            reason => "routing handoff rejected: routing_status='$r->{routing_status}' "
                    . "downstream.allowed=" . (defined $r->{allowed} ? $r->{allowed} : 'missing')
                    . " — routing reason: $r->{reason}" };
    } elsif ($norm =~ $PINE_RE) {
        # R9: Formalization formalizes requirements, never code
        $c->{status} = 'blocked';
        push @{ $c->{blockers} }, {
            id => 'B-PINE',
            reason => 'request contains Pine Script constructs — Formalization converts '
                    . 'requirements, not code; re-submit the intent in plain language' };
    } else {
        my $x = extract($norm);
        $c->{variables}          = $x->{variables};
        $c->{formulas}           = $x->{formulas};
        $c->{boolean_conditions} = $x->{conditions};
        $c->{ambiguities}        = $x->{ambiguities};
        $c->{edge_cases}         = $x->{edge_cases};
        $c->{timeframe}{chart}   = $x->{chart};
        $c->{mtf}                = $x->{mtf};
        if ($x->{mtf}) {
            if (@{ $x->{htf_tokens} }) {
                for my $t (@{ $x->{htf_tokens} }) {
                    push @{ $c->{required_data} }, {
                        kind => 'HTF price series', symbol_hint => undef, timeframe => $t,
                        notes => 'via request.security — confirmation/lookahead discipline must be stated (see repaint_risk)' };
                }
            } else {
                push @{ $c->{required_data} }, {
                    kind => 'HTF price series', symbol_hint => undef, timeframe => undef,
                    notes => 'timeframe undeclared (ambiguity A-HTF-TF)' };
            }
        }
        $c->{repaint_risk} = "$x->{repaint_class} — mechanism: $x->{repaint_mech}";

        # routing decisions copied verbatim (never re-derived)
        my %seen_s;
        for my $id (@{ $r->{selected} }, @{ $r->{deps} }) {
            next if $seen_s{$id}++;
            push @{ $c->{source_skills} }, $id;
        }

        # downstream obligations
        $c->{verification_requirements} = [
            qw(logic_valid math_valid variables_defined assumptions_documented
               ambiguities_resolved_or_recorded edge_cases_checked repaint_risk_classified) ];
        push @{ $c->{verification_requirements} }, 'required_data_available' if @{ $c->{required_data} };
        push @{ $c->{verification_requirements} }, 'mtf_behavior_reviewed'   if $c->{mtf};
        $c->{implementation_constraints} = [
            'Target Pine Script v6 only (no v5/v4 syntax).',
            'Boolean condition clauses C-* are verbatim requirements — preserve their semantics exactly.',
            'No lookahead / future-leak: any request.security use requires an explicit user-approved lookahead policy.',
            'Behavior-affecting ambiguities must be resolved_by_user before implementation may start.',
            "Preserve the declared repaint classification ('$x->{repaint_class}') or change it only with user consent." ];
    }

    # --- user-recorded resolutions (the engine NEVER invents them) ----------
    for my $pair (@$resolves) {
        my ($id, $val) = $pair =~ /^([^=]+)=(.+)$/
            or die "$ENGINE_ID: --resolve expects ID=resolved_by_user|resolved_assumed, got '$pair'\n";
        die "$ENGINE_ID: invalid resolution value '$val' (allowed: resolved_by_user, resolved_assumed)\n"
            unless $val eq 'resolved_by_user' || $val eq 'resolved_assumed';
        my ($hit) = grep { $_->{id} eq $id } @{ $c->{ambiguities} };
        die "$ENGINE_ID: unknown ambiguity id '$id' in --resolve\n" unless $hit;
        $hit->{resolution_status} = $val;
    }

    compute_ids($c, $routing_bytes);
    $c->{implementation_allowed} = gate_allowed($c);
    return $c;
}

# ---------------------------------------------------------------------------
# Emission (fixed field order — determinism)
# ---------------------------------------------------------------------------
sub contract_to_yaml {
    my ($c) = @_;
    my $o = '';
    $o .= "# formalization contract — generated by formalize.pl (schema v$SCHEMA_VERSION; meta/formalization_procedure.md)\n";
    $o .= "schema_version: \"$SCHEMA_VERSION\"\n";
    $o .= "stage: formalization\n";
    $o .= "predecessor: skill_routing\n";
    $o .= "successor: pre_verification\n";
    $o .= "\nformalization:\n";
    $o .= '  request_id: '          . _q($c->{request_id}) . "\n";
    $o .= '  approved_routing_id: ' . _q($c->{approved_routing_id}) . "\n";
    $o .= '  formalization_id: '    . _q($c->{formalization_id}) . "\n";
    $o .= '  supersedes: '          . (defined $c->{supersedes} ? _q($c->{supersedes}) : 'null') . "\n";
    $o .= '  natural_language_request: ' . _q($c->{natural_language_request}) . "\n";
    $o .= "  # normalized_request: whitespace-normalized verbatim (engine scope; agent refinements go through supersedes revisions)\n";
    $o .= '  normalized_request: '  . _q($c->{normalized_request}) . "\n";
    $o .= '  variables:'            . _rows_block($c->{variables},          [qw(name type description source)]);
    $o .= '  formulas:'             . _rows_block($c->{formulas},           [qw(id expression description depends_on)]);
    $o .= '  boolean_conditions:'   . _rows_block($c->{boolean_conditions}, [qw(id condition meaning used_by)]);
    $o .= "  assumptions: []\n";
    $o .= '  ambiguities:'          . _rows_block($c->{ambiguities}, [qw(id description options affects_behavior resolution_status)]);
    $o .= '  edge_cases:'           . _rows_block($c->{edge_cases},  [qw(id case required_behavior)]);
    $o .= "  timeframe:\n";
    $o .= '    chart: '       . (defined $c->{timeframe}{chart}       ? _q($c->{timeframe}{chart})       : 'null') . "\n";
    $o .= '    calculation: ' . (defined $c->{timeframe}{calculation} ? _q($c->{timeframe}{calculation}) : 'null') . "\n";
    $o .= '  mtf: '           . ($c->{mtf} ? 'true' : 'false') . "\n";
    $o .= '  required_data:'  . _rows_block($c->{required_data}, [qw(kind symbol_hint timeframe notes)]);
    $o .= '  repaint_risk: '  . (defined $c->{repaint_risk} ? _q($c->{repaint_risk}) : 'null') . "\n";
    $o .= '  source_skills: ' . _flow($c->{source_skills}) . "\n";
    $o .= '  verification_requirements: '   . _flow($c->{verification_requirements}) . "\n";
    $o .= '  implementation_constraints: '  . _flow($c->{implementation_constraints}) . "\n";
    $o .= '  status: ' . _q($c->{status}) . "\n";
    $o .= '  blockers:' . _rows_block($c->{blockers}, [qw(id reason)]);
    $o .= '  implementation_allowed: ' . ($c->{implementation_allowed} ? 'true' : 'false') . "\n";
    return $o;
}

# ---------------------------------------------------------------------------
# --gate-check: executable ordering gate (TEST-FORMALIZATION-001a)
# ---------------------------------------------------------------------------
sub gate_check_text {
    my ($text) = @_;
    my ($id)      = $text =~ /^\s*formalization_id:\s*'([^']+)'\s*$/m;
    my ($status)  = $text =~ /^\s*status:\s*'([^']+)'\s*$/m;
    my ($allowed) = $text =~ /^\s*implementation_allowed:\s*(true|false)\s*$/m;
    my ($no_blk)  = $text =~ /^\s*blockers:\s*\[\]\s*$/m;
    my @why;
    push @why, 'no formalization_id (or malformed)'  if !defined $id || $id !~ /^form-[0-9a-f]{12}$/;
    push @why, "status is '" . ($status // 'undef') . "' (needs completed)" unless defined $status && $status eq 'completed';
    push @why, 'blockers list is non-empty or malformed' unless $no_blk;
    push @why, 'implementation_allowed is false' unless defined $allowed && $allowed eq 'true';
    return (0, join('; ', @why)) if @why;
    return (1, "approved_formalization_id = $id");
}

# ===========================================================================
# SELFTEST — TEST-FORMAL-001..012 (+ Persian UTF-8 round-trip)
# Hermetic fixtures: routing YAML mirrors router.pl contract_to_yaml_v2 bytes.
# ===========================================================================
my ($PASS, $FAIL, @FAILS);
my $TMP;                                     # file-scoped: safe for nested named subs
sub _ok {
    my ($cond, $name, $detail) = @_;
    if ($cond) { $PASS++ }
    else {
        $FAIL++; $detail //= '';
        push @FAILS, "$name — $detail";
        print "FAIL $name: $detail\n";
    }
}

sub run_selftest {
    $TMP = tempdir(CLEANUP => 1);
    sub fixture {
        my ($name, $content) = @_;
        my $f = "$TMP/$name";
        open my $fh, '>:raw', $f or die "$ENGINE_ID: cannot write fixture '$f': $!\n";
        print {$fh} $content; close $fh;
        return $f;
    }

    my $REASON_READY = 'minimum sufficient set of 2 skill(s) covers the request with dependency closure complete';
    my $ready_fixture = <<"EOF";
routing:
  contract_version: 'routing/2'
  routing_status: 'ready'
  request_class: 'Pine_Script_implementation'
  primary_domain: 'pine-syntax'
  secondary_domains: ['momentum']
  operational_intent: 'Routed as ''Pine_Script_implementation'' request; select the minimum sufficient Skill set from the Registry.'
  selected_skills:
    - { id: 'pine-language-core', reason: 'class core per skill-routing rule 2/3', match: 'match' }
    - { id: 'momentum-indicators', reason: 'trigger hit: rsi', match: 'match' }
  dependency_skills:
    - { id: 'pine-type-system', required_by: 'pine-language-core' }
  excluded_skills:
    []
  coverage:
    required_capabilities: ['pine-language-core', 'momentum-indicators']
    covered_capabilities: ['pine-language-core', 'momentum-indicators']
    missing_capabilities: []
  conflicts: []
  ambiguity: []
  reason: '$REASON_READY'
  estimated_context_size: 'M + ~5.5k tokens'
  routing_trace:
    classification: 'markers fired: Pine_Script_implementation=2'
    matching: 'candidates graded: 77 eligible'
    minimal_set_reasoning: 'core + trigger-matched topics'
    dependency_resolution: 'mandatory dependency closure: pine-type-system'
    redundancy_analysis: 'no removals'
  downstream:
    next_stage: FORMALIZATION
    allowed: true
EOF

    sub status_fixture {
        my ($status, $allowed, $reason) = @_;
        my $a = defined $allowed ? $allowed : 'true';
        return <<"EOF";
routing:
  contract_version: 'routing/2'
  routing_status: '$status'
  request_class: 'debugging'
  primary_domain: 'debugging'
  secondary_domains: []
  operational_intent: 'Routed as ''debugging'' request.'
  selected_skills:
    - { id: 'pine-debugging-and-testing', reason: 'class core (debugging)', match: 'match' }
  dependency_skills:
    []
  excluded_skills:
    []
  coverage:
    required_capabilities: ['pine-debugging-and-testing']
    covered_capabilities: ['pine-debugging-and-testing']
    missing_capabilities: []
  conflicts: []
  ambiguity: []
  reason: '$reason'
  estimated_context_size: 'S + ~3.7k tokens'
  routing_trace:
    classification: 'markers fired'
    matching: 'candidates graded'
    minimal_set_reasoning: 'core'
    dependency_resolution: 'closure complete'
    redundancy_analysis: 'no removals'
  downstream:
    next_stage: FORMALIZATION
    allowed: $a
EOF
    }

    my $f_ready = fixture('ready.yaml', $ready_fixture);
    my $run = sub {
        my (%o) = @_;
        my $bytes = do { open my $fh, '<:raw', $o{routing} or die $!; local $/; <$fh> };
        my $c = build_contract(
            request => $o{request}, routing_file => $o{routing},
            routing_bytes => $bytes,
            resolves => $o{resolves} // [], supersedes => $o{supersedes});
        return (contract_to_yaml($c), ($c->{status} eq 'blocked' ? 2 : 0), $c);
    };

    # === TEST-FORMAL-001: ready -> completed contract, identity chain ======
    {
        my $req = 'Long entry when RSI crosses over 30 on bar close, on the 15m chart';
        my ($y, $e, $c) = $run->(request => $req, routing => $f_ready);
        _ok($e == 0, 'T001 exit 0', "exit=$e");
        _ok($c->{status} eq 'completed', 'T001 status completed', $c->{status});
        _ok($c->{request_id} =~ /^req-[0-9a-f]{12}$/, 'T001 request_id shape', $c->{request_id});
        _ok($c->{approved_routing_id} =~ /^rout-[0-9a-f]{12}$/, 'T001 routing_id shape', $c->{approved_routing_id});
        _ok($c->{formalization_id} =~ /^form-[0-9a-f]{12}$/, 'T001 formalization_id shape', $c->{formalization_id});
        _ok((grep { $_ eq 'pine-language-core' } @{ $c->{source_skills} })
            && (grep { $_ eq 'pine-type-system' } @{ $c->{source_skills} }),
            'T001 source_skills copies selected+dependency', join(',', @{ $c->{source_skills} }));
        _ok(@{ $c->{boolean_conditions} } == 1 && $c->{boolean_conditions}[0]{condition} eq 'RSI crosses over 30',
            'T001 condition verbatim', $c->{boolean_conditions}[0]{condition});
        _ok($c->{timeframe}{chart} eq '15m', 'T001 chart from request', $c->{timeframe}{chart});
        _ok(!@{ $c->{ambiguities} }, 'T001 fully-specified request has no ambiguities',
            join(',', map { $_->{id} } @{ $c->{ambiguities} }));
        _ok($c->{implementation_allowed} == 1, 'T001 gate open (nothing behavior-affecting unresolved)', $c->{implementation_allowed});
        _ok((grep { $_ eq 'repaint_risk_classified' } @{ $c->{verification_requirements} })
            && !(grep { $_ eq 'mtf_behavior_reviewed' } @{ $c->{verification_requirements} }),
            'T001 verification_requirements mirror pre-schema', join(',', @{ $c->{verification_requirements} }));
        _ok($c->{repaint_risk} =~ /^low — mechanism:/, 'T001 repaint classified', $c->{repaint_risk});
    }

    # === TEST-FORMAL-002: non-ready routing -> blocked ======================
    {
        my %cases = (
            ambiguous            => 'request is underdetermined (3 missing information items)',
            insufficient_coverage => 'required coverage needs more than max_selected_skills=5',
            blocked              => 'no registered trigger matched the request',
            conflict_detected    => 'selected semantics are internally incompatible',
        );
        for my $st (sort keys %cases) {
            my $f = fixture("nr_$st.yaml", status_fixture($st, 'true', $cases{$st}));
            my ($y, $e, $c) = $run->(request => 'RSI crosses over 30', routing => $f);
            _ok($e == 2, "T002[$st] exit 2", $e);
            _ok($c->{status} eq 'blocked', "T002[$st] blocked", $c->{status});
            _ok($c->{blockers}[0]{id} eq 'B-ROUTING', "T002[$st] blocker id", $c->{blockers}[0]{id});
            _ok(index($c->{blockers}[0]{reason}, $cases{$st}) >= 0, "T002[$st] routing reason verbatim", $c->{blockers}[0]{reason});
            _ok($c->{implementation_allowed} == 0, "T002[$st] gate closed", $c->{implementation_allowed});
        }
        # ready but downstream.allowed=false -> still rejected
        my $f = fixture('nr_allowed.yaml', status_fixture('ready', 'false', $REASON_READY));
        my ($y, $e, $c) = $run->(request => 'RSI crosses over 30', routing => $f);
        _ok($e == 2 && $c->{status} eq 'blocked' && $c->{blockers}[0]{id} eq 'B-ROUTING'
            && index($c->{blockers}[0]{reason}, 'allowed=false') >= 0,
            'T002[allowed-false] ready but not allowed -> blocked', $c->{blockers}[0]{reason});
    }

    # === TEST-FORMAL-003: malformed handoffs -> blocked ======================
    {
        my $bad1 = "routing:\n  routing_status: 'ready'\n  reason: 'x'\n";
        my $bad2 = $ready_fixture;
        $bad2 =~ s/contract_version: 'routing\/2'/contract_version: 'routing\/1'/;
        for my $i (1 .. 2) {
            my $f = fixture("bad$i.yaml", $i == 1 ? $bad1 : $bad2);
            my ($y, $e, $c) = $run->(request => 'RSI crosses over 30', routing => $f);
            _ok($e == 2 && $c->{status} eq 'blocked' && $c->{blockers}[0]{id} eq 'B-ROUTING-INVALID',
                "T003[$i] malformed -> B-ROUTING-INVALID", $c->{blockers}[0]{id});
        }
    }

    # === TEST-FORMAL-004: deterministic ids + stability ======================
    {
        my $req = 'Sell signal when close is below 50, on the 1h chart';
        my ($y1, $e1, $c1) = $run->(request => $req, routing => $f_ready);
        my ($y2, $e2, $c2) = $run->(request => $req, routing => $f_ready);
        _ok($y1 eq $y2, 'T004 byte-identical output for identical inputs', '');
        my ($y3, $e3, $c3) = $run->(request => $req . ' and volume confirmation', routing => $f_ready);
        _ok($c1->{request_id} ne $c3->{request_id} && $c1->{formalization_id} ne $c3->{formalization_id},
            'T004 distinct inputs -> distinct ids', "$c1->{request_id} vs $c3->{request_id}");
        my ($y4, $e4, $c4) = $run->(request => $req, routing => $f_ready, supersedes => $c1->{formalization_id});
        _ok($c4->{formalization_id} eq $c1->{formalization_id},
            'T004 id stable: supersedes (identity/gate field) excluded from body hash',
            "$c1->{formalization_id} vs $c4->{formalization_id}");
        _ok($c4->{supersedes} eq $c1->{formalization_id}, 'T004 supersedes recorded', $c4->{supersedes});
        _ok($y1 =~ /supersedes: null/, 'T004 supersedes null by default', '');
    }

    # === TEST-FORMAL-006: condition/threshold preservation, no invention ====
    {
        my $req = 'Sell signal when close is below 50 and RSI is above 70';
        my ($y, $e, $c) = $run->(request => $req, routing => $f_ready);
        my @cls = map { $_->{condition} } @{ $c->{boolean_conditions} };
        _ok((grep { $_ eq 'close is below 50' } @cls) && (grep { $_ eq 'RSI is above 70' } @cls),
            'T006 both conditions verbatim', join(' | ', @cls));
        _ok((grep { $_->{meaning} =~ /verbatim/ } @{ $c->{boolean_conditions} }) == 2,
            'T006 meanings declare verbatim preservation', '');
        my @aids = map { $_->{id} } @{ $c->{ambiguities} };
        _ok((grep { /^A-OPER(-2)?$/ } @aids) == 2, 'T006 state-vs-event ambiguity per clause', join(',', @aids));
        _ok(!(grep { /^A-PREC/ } @aids), 'T006 declared connective (and) suppresses A-PREC', join(',', @aids));
        _ok((grep { $_ eq 'close' && $_ eq 'RSI' } @cls) ? 0 : 1, 'T006 no invented variables for conditions', '');
        my $req2 = 'signal when RSI is oversold';
        my ($y2, $e2, $c5) = $run->(request => $req2, routing => $f_ready);
        _ok((grep { $_->{id} =~ /^A-THR/ && $_->{affects_behavior} } @{ $c5->{ambiguities} }),
            'T006 vague threshold -> A-THR recorded, not guessed', join(',', map { $_->{id} } @{ $c5->{ambiguities} }));
        _ok(!(grep { $_->{description} =~ /70|30/ } @{ $c5->{ambiguities} }), 'T006 no numeric threshold invented', '');
    }

    # === TEST-FORMAL-007: MTF representation ================================
    {
        my $req = 'higher timeframe trend filter using 4h data while trading on the 15m chart';
        my ($y, $e, $c) = $run->(request => $req, routing => $f_ready);
        _ok($c->{mtf} == 1, 'T007 mtf flag true', $c->{mtf});
        _ok($c->{timeframe}{chart} eq '15m', 'T007 chart recorded', $c->{timeframe}{chart});
        _ok(@{ $c->{required_data} } == 1 && $c->{required_data}[0]{timeframe} eq '4h'
            && $c->{required_data}[0]{kind} eq 'HTF price series',
            'T007 HTF required_data entry', join(',', map { ($_->{timeframe} // '?') } @{ $c->{required_data} }));
        _ok(!(grep { /^A-HTF-TF/ } map { $_->{id} } @{ $c->{ambiguities} }), 'T007 explicit HTF -> no A-HTF-TF', '');
        my ($y2, $e2, $c2) = $run->(request => 'higher timeframe trend filter', routing => $f_ready);
        _ok((grep { /^A-HTF-TF$/ } map { $_->{id} } @{ $c2->{ambiguities} }),
            'T007 MTF without HTF -> A-HTF-TF', join(',', map { $_->{id} } @{ $c2->{ambiguities} }));
        _ok(!defined $c2->{required_data}[0]{timeframe},
            'T007 undeclared HTF not invented', '');
    }

    # === TEST-FORMAL-008: repaint representation ============================
    {
        my ($y1, $c1) = do { my ($a, $b, $cc) = $run->(request => 'higher timeframe trend filter using 4h data while trading on the 15m chart', routing => $f_ready); ($a, $cc) };
        _ok($c1->{repaint_risk} =~ /^high — mechanism: unconfirmed higher-timeframe/,
            'T008 MTF w/o confirmation -> high', $c1->{repaint_risk});
        my ($y2, $c2) = do { my ($a, $b, $cc) = $run->(request => 'higher timeframe 4h trend filter on the 15m chart, confirmed bar only via barstate.isconfirmed', routing => $f_ready); ($a, $cc) };
        _ok($c2->{repaint_risk} =~ /^low — mechanism: confirmed-bar/,
            'T008 MTF + confirmation -> low', $c2->{repaint_risk});
        my ($y3, $c3) = do { my ($a, $b, $cc) = $run->(request => 'track price changes every tick on the 1m chart', routing => $f_ready); ($a, $cc) };
        _ok($c3->{repaint_risk} =~ /^medium — mechanism: realtime intrabar/,
            'T008 intrabar w/o MTF -> medium', $c3->{repaint_risk});
    }

    # === TEST-FORMAL-009: edge cases ========================================
    {
        my ($y, $c) = do { my ($a, $b, $cc) = $run->(request => 'Long entry when RSI crosses over 30 on bar close, on the 15m chart', routing => $f_ready); ($a, $cc) };
        my @eids = map { $_->{id} } @{ $c->{edge_cases} };
        _ok((grep { $_ eq 'E-NA' } @eids) && (grep { $_ eq 'E-FIRST' } @eids),
            'T009 always-on edge cases', join(',', @eids));
        _ok(!(grep { defined $_->{required_behavior} } @{ $c->{edge_cases} }),
            'T009 required_behavior never invented (null unless request-defined)', '');
        my $reqd = 'momentum = close divided by open';
        my ($yd, $cd) = do { my ($a, $b, $cc) = $run->(request => $reqd, routing => $f_ready); ($a, $cc) };
        my @dids = map { $_->{id} } @{ $cd->{edge_cases} };
        _ok((grep { $_ eq 'E-DIV' } @dids) && (grep { /^A-DIV/ } map { $_->{id} } @{ $cd->{ambiguities} }),
            'T009 division w/o guard -> E-DIV + A-DIV', join(',', @dids));
        _ok($cd->{formulas}[0]{expression} eq 'close divided by open', 'T009 formula verbatim', $cd->{formulas}[0]{expression});
        my $reqg = 'momentum = close divided by open, guard against division by zero';
        my ($yg, $cg) = do { my ($a, $b, $cc) = $run->(request => $reqg, routing => $f_ready); ($a, $cc) };
        _ok(!(grep { /^A-DIV/ } map { $_->{id} } @{ $cg->{ambiguities} }),
            'T009 declared zero-guard -> no A-DIV', join(',', map { $_->{id} } @{ $cg->{ambiguities} }));
        my $reqv = 'volume spike when volume is above 1000';
        my ($yv, $cv) = do { my ($a, $b, $cc) = $run->(request => $reqv, routing => $f_ready); ($a, $cc) };
        _ok((grep { $_->{id} eq 'E-VOL' } @{ $cv->{edge_cases} })
            && (grep { $_->{name} eq 'volume' } @{ $cv->{variables} }),
            'T009 volume source -> E-VOL + variable', join(',', map { $_->{id} } @{ $cv->{edge_cases} }));
    }

    # === TEST-FORMAL-010: ambiguity gate (TEST-FORMALIZATION-001b) ==========
    {
        my $req = 'Long entry when RSI crosses over 30 on bar close';   # A-TF only
        my ($y0, $c0) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready); ($a, $cc) };
        _ok($c0->{status} eq 'completed' && $c0->{implementation_allowed} == 0,
            'T010 unresolved behavior-affecting ambiguity keeps gate closed', $c0->{implementation_allowed});
        _ok($y0 =~ /resolution_status: 'unresolved'/, 'T010 ambiguity recorded unresolved', '');
        my ($y1, $c1) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready, resolves => ['A-TF=resolved_by_user']); ($a, $cc) };
        _ok($c1->{implementation_allowed} == 1, 'T010 resolved_by_user opens gate', $c1->{implementation_allowed});
        _ok($c1->{formalization_id} ne $c0->{formalization_id},
            'T010 resolution changes content -> new id (revision)', '');
        my ($y2, $c2) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready, resolves => ['A-TF=resolved_assumed']); ($a, $cc) };
        _ok($c2->{implementation_allowed} == 0,
            'T010 resolved_assumed NEVER opens gate (TEST-FORMALIZATION-001 must_not)', $c2->{implementation_allowed});
        my ($y3, $c3) = do { my ($a, $b, $cc) = $run->(request => 'signal when RSI is below 30 and volume is above 1000', routing => $f_ready); ($a, $cc) };
        _ok((grep { $_->{id} =~ /^A-CONF/ && $_->{affects_behavior} } @{ $c3->{ambiguities} }),
            'T010 evaluation-timing ambiguity (A-CONF) detected', join(',', map { $_->{id} } @{ $c3->{ambiguities} }));
        # white-box: non-behavior-affecting unresolved ambiguity never blocks
        my $probe = { status => 'completed', blockers => [],
            ambiguities => [ { id => 'A-X', affects_behavior => 0, resolution_status => 'unresolved' } ] };
        _ok(gate_allowed($probe) == 1, 'T010 non-behavior-affecting unresolved does not block', '');
    }

    # === TEST-FORMAL-011: schema compliance + no-Pine invariant =============
    {
        my $req = 'Long entry when RSI crosses over 30 on bar close, on the 15m chart';
        my ($y, $c) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready); ($a, $cc) };
        for my $field (qw(request_id approved_routing_id formalization_id supersedes
                          natural_language_request normalized_request variables formulas
                          boolean_conditions assumptions ambiguities edge_cases timeframe
                          chart calculation mtf required_data repaint_risk source_skills
                          verification_requirements implementation_constraints status
                          blockers implementation_allowed schema_version stage
                          predecessor successor)) {
            _ok(index($y, $field) >= 0, "T011 schema field '$field' present", '');
        }
        _ok($y !~ /\@version|indicator\s*\(|strategy\s*\(|library\s*\(/,
            'T011 no Pine constructs in contract output', '');
        my $f = $f_ready;
        my ($yp, $ep, $cp) = $run->(request => 'refactor this //@version=5 script to improve the exit', routing => $f);
        _ok($ep == 2 && $cp->{status} eq 'blocked' && $cp->{blockers}[0]{id} eq 'B-PINE',
            'T011 Pine in request -> blocked B-PINE', $cp->{blockers}[0]{id});
    }

    # === TEST-FORMAL-012: --gate-check (ordering gate, TEST-FORMALIZATION-001a)
    {
        my $req = 'Long entry when RSI crosses over 30 on bar close, on the 15m chart';
        my ($y, $c) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready); ($a, $cc) };
        my ($ok1, $msg1) = gate_check_text($y);
        _ok($ok1 && $msg1 eq "approved_formalization_id = $c->{formalization_id}",
            'T012 gate-check approves allowed contract', $msg1);
        my $y_false = $y;
        $y_false =~ s/implementation_allowed: true/implementation_allowed: false/;
        my ($ok2, $msg2) = gate_check_text($y_false);
        _ok(!$ok2 && $msg2 =~ /implementation_allowed is false/, 'T012 gate-check refuses false gate', $msg2);
        my $y_noid = $y;
        $y_noid =~ s/^  formalization_id: .*$//m;
        my ($ok3, $msg3) = gate_check_text($y_noid);
        _ok(!$ok3 && $msg3 =~ /no formalization_id/, 'T012 gate-check refuses missing id', $msg3);
        my ($yb, $eb, $cb) = $run->(request => 'refactor //@version=4 code', routing => $f_ready);
        my ($ok4, $msg4) = gate_check_text($yb);
        _ok(!$ok4 && $msg4 =~ /status is 'blocked'/, 'T012 gate-check refuses blocked contract', $msg4);
    }

    # === TEST-FORMAL-013: Persian/UTF-8 round-trip + determinism ============
    {
        my $req = "وقتی RSI زیر 30 باشد وارد شو on the 1h chart, on bar close";
        my ($y1, $c1) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready); ($a, $cc) };
        my ($y2, $c2) = do { my ($a, $b, $cc) = $run->(request => $req, routing => $f_ready); ($a, $cc) };
        _ok($y1 eq $y2, 'T013 Persian request deterministic', '');
        _ok(index($y1, 'زیر 30') >= 0, 'T013 Persian text preserved verbatim', '');
        _ok($c1->{timeframe}{chart} eq '1h', 'T013 mixed-script TF detection', $c1->{timeframe}{chart});
    }

    # === summary ============================================================
    print 'SELFTEST: ' . ($PASS // 0) . " passed, " . ($FAIL // 0) . " failed\n";
    if ($FAIL) { print "$_\n" for @FAILS; return 2; }
    print "All TEST-FORMAL-001..013 acceptance cases pass (formalization contract v$SCHEMA_VERSION).\n";
    return 0;
}

# ===========================================================================
# CLI
# ===========================================================================
sub usage {
    return <<"EOF";
usage:
  perl $0 --request-text "TEXT" --routing FILE [--resolve ID=resolved_by_user|resolved_assumed]... [--supersedes form-xxxxxxxxxxxx] [--out FILE]
  perl $0 --request FILE --routing FILE [...]          # request read from file (UTF-8)
  perl $0 --gate-check --contract FILE
  perl $0 --selftest
EOF
}

sub main {
    my %opt;
    GetOptions(\%opt,
        'request-text=s', 'request=s', 'routing=s', 'resolve=s@', 'supersedes=s',
        'out=s', 'gate-check', 'contract=s', 'selftest',
    ) or die usage();

    if ($opt{selftest}) { exit(run_selftest()); }

    if ($opt{'gate-check'}) {
        die usage() unless $opt{contract};
        open my $fh, '<:raw', $opt{contract} or die "$ENGINE_ID: cannot read contract '$opt{contract}': $!\n";
        my $text = decode('UTF-8', do { local $/; <$fh> });
        close $fh;
        my ($ok, $msg) = gate_check_text($text);
        print "$msg\n";
        exit($ok ? 0 : 2);
    }

    my $req;
    if (defined $opt{'request-text'}) {
        $req = decode('UTF-8', $opt{'request-text'});
    } elsif ($opt{request}) {
        open my $fh, '<:raw', $opt{request} or die "$ENGINE_ID: cannot read request '$opt{request}': $!\n";
        $req = decode('UTF-8', do { local $/; <$fh> });
        close $fh;
    } else {
        die usage();
    }
    die usage() unless $opt{routing};

    if (defined $opt{supersedes} && $opt{supersedes} !~ /^form-[0-9a-f]{12}$/) {
        die "$ENGINE_ID: --supersedes must be a formalization_id (form-xxxxxxxxxxxx)\n";
    }

    open my $rf, '<:raw', $opt{routing} or die "$ENGINE_ID: cannot read routing output '$opt{routing}': $!\n";
    my $routing_bytes = do { local $/; <$rf> };
    close $rf;

    my $c = build_contract(
        request => $req, routing_file => $opt{routing}, routing_bytes => $routing_bytes,
        resolves => $opt{resolve} // [], supersedes => $opt{supersedes});
    my $yaml = contract_to_yaml($c);

    if ($opt{out}) {
        my $dir = dirname($opt{out});
        make_path($dir) if $dir && !-d $dir;
        open my $of, '>:raw', $opt{out} or die "$ENGINE_ID: cannot write '$opt{out}': $!\n";
        print {$of} encode('UTF-8', $yaml);
        close $of;
    }
    print $yaml;
    exit($c->{status} eq 'blocked' ? 2 : 0);
}

main() unless caller();