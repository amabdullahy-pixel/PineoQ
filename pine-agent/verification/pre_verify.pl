#!/usr/bin/perl
# ============================================================================
# pre_verify.pl — Pre-Verification decision engine (pine-agent Phase 6)
# ============================================================================
# Core Perl 5, zero non-core dependencies (Digest::SHA, Encode, File::Temp
# are core). Runtime contract identical to router.pl / formalize.pl.
#
# Input : one formalization contract (YAML exactly as formalize.pl emits it).
# Output: pre-verification result contract (schema v1.1) + exit code.
#   exit 0  result PASS | PASS_WITH_WARNINGS  (--gate-check approved)
#   exit 2  result BLOCKED | INVALID_INPUT    (--gate-check refused)
#
# Determinism: no clock, no randomness, no environment values.
# verification_id = "pre-" + first 12 hex of sha256 over the canonical body
# (see meta/pre_verification_procedure.md §5).
#
# NO-PINE RULE: this engine verifies a specification. It never emits Pine.
# ============================================================================
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode);

# ---------------------------------------------------------------------------
# tiny YAML-subset parser for the exact bytes formalize.pl emits
# ---------------------------------------------------------------------------
sub _unq { my $s = shift; return undef if !defined $s; $s =~ s/^'//; $s =~ s/'$//; $s =~ s/''/'/g; return $s; }

sub _parse_flow_map {
    my ($s) = @_;   # content inside { }
    my %out; my $pos = 0;
    while ($s =~ /\G\s*,?\s*(\w+):\s*('(?:[^']|'')*'|[\w.\-]+)/gc) {
        my ($k, $v) = ($1, $2);
        $out{$k} = ($v eq 'null') ? undef : _unq($v);
        $pos = pos($s);
    }
    return \%out;
}

sub _parse_flow_list {
    my ($s) = @_;   # content inside [ ]
    my @out;
    while ($s =~ /\G\s*,?\s*('(?:[^']|'')*'|[\w.\-]+)/gc) { push @out, _unq($1); }
    return \@out;
}

sub parse_contract {
    my ($text) = @_;
    die "unparseable: empty input\n" if !defined $text || $text !~ /\S/;
    my %c;
    my ($cur_list, $in_tf, $in_f);
    for my $line (split /\r?\n/, $text) {
        next if $line =~ /^\s*#/ || $line !~ /\S/;
        if ($line =~ /^(\w+):\s*(.*)$/) {                       # top-level
            my ($k, $v) = ($1, $2);
            if ($k eq 'schema_version') { $c{schema_version} = _unq($v) // $v; next; }
            if ($k eq 'stage')          { $c{stage} = _unq($v) // $v; next; }
        }
        if ($line =~ /^  (\w+):\s*(.*)$/) {                     # pre_verification: block
            my ($k, $v) = ($1, $2);
            if ($k eq 'pre_verification') { $in_f = 1; next; }
        }
        next unless $in_f;
        if ($line =~ /^    (\w+):\s*(.*)$/) {                   # 4-space scalars (timeframe/mtf/repaint/traceability)
            my ($k, $v) = ($1, $2);
            if ($in_tf)  { $c{tf}{$k} = _unq($v); next; }
            if ($in_f && $k eq 'applicable')  { $c{mtf_flag} = ($v eq 'true') ? 1 : 0; next; }
            if ($in_f && $k eq 'validated')   { next; }
            if ($in_f && $k eq 'classification') { $c{repaint_class} = _unq($v); next; }
            if ($in_f && $k eq 'mechanism')      { $c{repaint_mech} = _unq($v); next; }
            if ($in_f && $k eq 'source_skills') {
                $c{source_skills} = ($v =~ /^\[(.*)\]\s*$/) ? _parse_flow_list($1) : [];
                $in_f = 1; next;
            }
            next;
        }
        if ($line =~ /^    - (.*)$/) { $cur_list = undef; push @$cur_list, $1 if 0; next; } # unused depth
    }
    # --- second pass: robust targeted extraction (format-tolerant, order-fixed) ---
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
        if ($t =~ /^\s{2}\Q$key\E:\s*\[(.+)\]\s*$/m) {          # flow list of maps
            my $inner = $1;
            while ($inner =~ /\{\s*([^}]*)\}/g) { push @out, _parse_flow_map($1); }
            return \@out;
        }
        if ($t =~ /^\s{2}\Q$key\E:\s*$/m) {
            my $body = $t;
            $body =~ s/^\s{2}\Q$key\E:.*\n//m;
            my $indent_block = '';
            my $capture = 0;
            for my $line (split /\r?\n/, $t) {
                if ($line =~ /^\s{2}\Q$key\E:\s*$/) { $capture = 1; next; }
                next unless $capture;
                last if $line =~ /^\S/ || $line =~ /^\s{2}\w+:/;
                $indent_block .= "$line\n" if $line =~ /^\s{4,}- |^\s{6}\w/;
            }
            my $entry;
            for my $line (split /\r?\n/, $indent_block) {
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
        return _parse_flow_list($1) if $v =~ /^\[(.+)\]$/;
        return [];
    };
    $c{request_id}              = $get_scalar->('request_id', $text);
    $c{approved_routing_id}     = $get_scalar->('approved_routing_id', $text);
    $c{formalization_id}        = $get_scalar->('formalization_id', $text);
    $c{request_text}            = $get_scalar->('natural_language_request', $text) // $get_scalar->('normalized_request', $text);
    $c{status}                  = $get_scalar->('status', $text);
    $c{implementation_allowed}  = $get_scalar->('implementation_allowed', $text);
    $c{mtf_flag}                = $get_scalar->('mtf', $text) ? 1 : 0;
    $c{repaint_raw}             = $get_scalar->('repaint_risk', $text);
    my $ch_raw = ($text =~ /^\s{4}chart:[ \t]*(.*)$/m) ? $1 : undef;
    $c{tf_chart}                = (!defined $ch_raw || $ch_raw eq 'null' || $ch_raw eq '') ? undef : _unq($ch_raw);
    $c{variables}               = $get_list_of_maps->('variables', $text);
    $c{formulas}                = $get_list_of_maps->('formulas', $text);
    $c{conditions}              = $get_list_of_maps->('boolean_conditions', $text);
    $c{assumptions}             = $get_list_of_maps->('assumptions', $text);
    $c{ambiguities}             = $get_list_of_maps->('ambiguities', $text);
    $c{edge_cases}              = $get_list_of_maps->('edge_cases', $text);
    $c{required_data}           = $get_list_of_maps->('required_data', $text);
    $c{blockers_flat}           = $get_list_of_maps->('blockers', $text);
    $c{source_skills}           = $get_flow_list->('source_skills', $text);
    $c{verification_requirements} = $get_flow_list->('verification_requirements', $text);
    $c{implementation_constraints} = $get_flow_list->('implementation_constraints', $text);
    die "unparseable: no formalization block\n" unless defined $c{request_id} || $text =~ /formalization/;
    return \%c;
}

# ---------------------------------------------------------------------------
# mechanical helpers
# ---------------------------------------------------------------------------
my @BUILTIN_SRC = qw(close open high low volume hl2 hlc3 ohlc4);
my %DIRECTION = (
    'is above' => 'above', 'above' => 'above', '>' => 'above', '>=' => 'above', 'crosses over' => 'cross_up',
    'is below' => 'below', 'below' => 'below', '<' => 'below', '<=' => 'below', 'crosses under' => 'cross_down',
);
sub parse_clause {
    my ($clause) = @_;
    return undef if !defined $clause;
    my $c = lc $clause;
    for my $op (sort { length($b) <=> length($a) } keys %DIRECTION) {
        my $esc = quotemeta $op;
        if ($c =~ /^(.*?)\s*$esc\s+(.*)$/) {
            my ($subj, $thr) = ($1, $2);
            $subj =~ s/[[:punct:]]+$//;
            return { subject => $subj, op => $op, dir => $DIRECTION{$op}, threshold => $thr };
        }
    }
    return undef;
}
sub clause_vague { my $t = lc(shift // ''); return $t =~ /(oversold|overbought|too high|too low|significan|sharp|approximately|near the)/; }
sub has_timing   { my $t = lc(shift // ''); return $t =~ /(on bar close|on close|bar close|at the open|intrabar|every tick|realtime|confirmed)/; }
sub has_guard    { my $t = lc(shift // ''); return $t =~ /(division by zero|zero check|zero guard)/; }

# ---------------------------------------------------------------------------
# the 14 checks — each returns list of findings
# finding = { check_id, severity, code, message, refs[] }
# ---------------------------------------------------------------------------
my @DOMAINS = (
    ['PC01', 'identity_traceability'],   ['PC02', 'formalization_gate'],
    ['PC03', 'variable_completeness'],   ['PC04', 'formula_math_dependency'],
    ['PC05', 'boolean_consistency'],     ['PC06', 'assumption_validity'],
    ['PC07', 'ambiguity_resolution'],    ['PC08', 'edge_case_coverage'],
    ['PC09', 'mtf_consistency'],         ['PC10', 'repaint_identification'],
    ['PC11', 'required_data'],           ['PC12', 'contradictions'],
    ['PC13', 'implicit_assumptions'],    ['PC14', 'traceability_integrity'],
);

sub run_checks {
    my ($c) = @_;
    my @F;
    my $add = sub { my ($cid, $sev, $code, $msg, @refs) = @_; push @F, { check_id => $cid, severity => $sev, code => $code, message => $msg, refs => \@refs }; };

    # --- PC01 identity chain --------------------------------------------------
    my $ok_id = sub { return defined $_[0] && $_[0] =~ /^(req|rout|form)-[0-9a-f]{12}$/ };
    {
        my @bad;
        push @bad, 'request_id'          unless $ok_id->($c->{request_id});
        push @bad, 'approved_routing_id' unless $ok_id->($c->{approved_routing_id});
        push @bad, 'formalization_id'    unless $ok_id->($c->{formalization_id});
        if (@bad) { $add->('PC01', 'blocker', 'B-CHAIN', 'formalization identity chain malformed or missing: ' . join(', ', @bad), @bad); }
    }
    # --- PC02 formalization approval gate --------------------------------------
    {
        if (($c->{status} // '') ne 'completed') {
            $add->('PC02', 'blocker', 'B-GATE', "formalization status is '" . ($c->{status} // 'null') . "' — completed required", 'status');
        }
        my @blk = grep { $_ && (ref $_ eq 'HASH' ? 1 : 1) } @{ $c->{blockers_flat} || [] };
        if (@{ $c->{blockers_flat} || [] }) {
            $add->('PC02', 'blocker', 'B-GATE', 'formalization carries upstream blockers — downstream use refused', 'blockers');
        }
        if (!$c->{implementation_allowed}) {
            $add->('PC02', 'blocker', 'B-GATE', 'formalization implementation_allowed is false — downstream use refused', 'implementation_allowed');
        }
    }
    # --- PC03 variable completeness ---------------------------------------------
    my %vnames = map { ($_->{name} // '') => 1 } @{ $c->{variables} || [] };
    my %fids   = map { ($_->{id}   // '') => 1 } @{ $c->{formulas}   || [] };
    my %known  = (%vnames, %fids, map { $_ => 1 } @BUILTIN_SRC);
    my @subjects;
    for my $cond (@{ $c->{conditions} || [] }) {
        my $p = parse_clause($cond->{condition});
        next unless $p;
        push @subjects, $p->{subject};
        if (!$known{ $p->{subject} }) {
            $add->('PC03', 'blocker', 'B-VAR-MISSING', "referenced name '" . $p->{subject} . "' has no variables/formulas entry", $cond->{id} // 'C-?', $p->{subject});
        }
    }
    # --- PC04 formula math + dependency consistency ------------------------------
    for my $f (@{ $c->{formulas} || [] }) {
        for my $dep (split /\s*,\s*/, ($f->{depends_on} // '')) {
            next unless length $dep;
            if (!$fids{$dep}) {
                $add->('PC04', 'blocker', 'B-DEP', "formula '" . ($f->{id} // '?') . "' depends_on unknown formula '" . $dep . "'", $f->{id} // 'F-?', $dep);
            }
        }
        my $expr = lc($f->{expression} // '');
        for my $tok ($expr =~ /\b([a-z][a-z0-9_]*)\b/g) {
            next if $tok =~ /^(divided|by|plus|minus|times|of)$/;
            if (!$known{$tok}) {
                $add->('PC04', 'blocker', 'B-OPERAND', "formula '" . ($f->{id} // '?') . "' uses undefined operand '" . $tok . "'", $f->{id} // 'F-?', $tok);
            }
        }
    }
    # --- PC05 boolean-condition consistency --------------------------------------
    for my $cond (@{ $c->{conditions} || [] }) {
        my $id = $cond->{id} // '';
        if ($id !~ /^C-[0-9A-Za-z]+$/) {
            $add->('PC05', 'blocker', 'B-COND-ID', "boolean condition id '" . $id . "' is malformed", $id);
        }
        if (!parse_clause($cond->{condition})) {
            $add->('PC05', 'warning', 'W-COND-FREEFORM', "condition '" . $id . "' is not a mechanical comparison clause — semantics need agent review", $id);
        }
    }
    # --- PC06 assumption validity --------------------------------------------------
    for my $a (@{ $c->{assumptions} || [] }) {
        my $aff = ($a->{affects_behavior} // 'false') eq 'true' ? 1 : 0;
        my $cfm = ($a->{user_confirmed}  // 'false') eq 'true' ? 1 : 0;
        if ($aff && !$cfm) {
            $add->('PC06', 'warning', 'W-ASSUMP-UNCONFIRMED', "behavior-affecting assumption '" . ($a->{id} // '?') . "' is not user-confirmed", $a->{id} // 'A-?');
        }
    }
    # --- PC07 ambiguity resolution state --------------------------------------------
    for my $amb (@{ $c->{ambiguities} || [] }) {
        my $aff = ($amb->{affects_behavior} // 'false') eq 'true' ? 1 : 0;
        my $st  = $amb->{resolution_status} // 'unresolved';
        next unless $aff;
        if ($st eq 'unresolved') {
            $add->('PC07', 'blocker', 'B-AMB-UNRESOLVED', "behavior-affecting ambiguity '" . ($amb->{id} // '?') . "' is unresolved", $amb->{id} // 'A-?');
        } elsif ($st eq 'resolved_assumed') {
            $add->('PC07', 'blocker', 'B-AMB-ASSUMED', "behavior-affecting ambiguity '" . ($amb->{id} // '?') . "' is resolved_assumed — assumed resolutions never unlock downstream (TEST-FORMALIZATION-001 must_not)", $amb->{id} // 'A-?');
        }
    }
    # --- PC08 edge-case coverage ------------------------------------------------------
    {
        my $div = grep { lc($_->{expression} // '') =~ m{(/|divided by)} } @{ $c->{formulas} || [] };
        my %ec  = map { ($_->{id} // '') => 1 } @{ $c->{edge_cases} || [] };
        if ($div && !$ec{'E-DIV'} && !has_guard($c->{request_text} // '')) {
            $add->('PC08', 'blocker', 'B-EC-DIV', 'division present but no E-DIV edge case and no zero-guard wording — contract self-inconsistent', 'edge_cases');
        }
        my $nc = scalar @{ $c->{conditions} || [] };
        if ($nc >= 2 && !$ec{'E-PREC'} && !grep { ($_->{id} // '') eq 'A-PREC' } @{ $c->{ambiguities} || [] }) {
            $add->('PC08', 'warning', 'W-EC-PREC', 'multiple conditions without recorded precedence edge case or A-PREC ambiguity', 'edge_cases');
        }
    }
    # --- PC09 MTF/timeframe consistency -------------------------------------------------
    {
        my $mtf = $c->{mtf_flag};
        if ($mtf) {
            if (!defined $c->{tf_chart} || $c->{tf_chart} eq '') {
                $add->('PC09', 'blocker', 'B-MTF-CHART', 'mtf true but timeframe.chart is null', 'timeframe.chart');
            }
            if (!@{ $c->{required_data} || [] }) {
                $add->('PC09', 'blocker', 'B-MTF-DATA', 'mtf true but required_data is empty', 'required_data');
            }
            if (lc($c->{repaint_raw} // '') =~ /no repaint mechanism detected/) {
                $add->('PC09', 'blocker', 'B-MTF-REPAINT', 'mtf true but repaint classification claims no repaint mechanism — inconsistent', 'repaint_risk');
            }
        } elsif (@{ $c->{required_data} || [] }) {
            $add->('PC09', 'blocker', 'B-MTF-EXTRA', 'mtf false but required_data is non-empty — inconsistent', 'required_data');
        }
    }
    # --- PC10 repaint identification --------------------------------------------------------
    {
        my $raw = $c->{repaint_raw};
        if (!defined $raw || $raw eq '') {
            $add->('PC10', 'blocker', 'B-REPAINT-UNDECLARED', 'repaint_risk undeclared — AGENT_RULES 3.12 requires a classification on every request', 'repaint_risk');
        } elsif ($raw !~ /^(none|low|medium|high)\b/) {
            $add->('PC10', 'blocker', 'B-REPAINT-MALFORMED', "repaint_risk '" . $raw . "' does not start with none|low|medium|high", 'repaint_risk');
        } elsif ($raw =~ /^high\b/) {
            $add->('PC10', 'warning', 'W-REPAINT-ACCEPT', 'repaint classification high — explicit user acceptance is required before implementation', 'repaint_risk');
        }
    }
    # --- PC11 required-data completeness -------------------------------------------------------
    {
        my $has_htf_amb = grep { ($_->{id} // '') eq 'A-HTF-TF' } @{ $c->{ambiguities} || [] };
        my $i = 0;
        for my $d (@{ $c->{required_data} || [] }) {
            $i++;
            my $ref = "required_data[$i]";
            if (!defined $d->{kind} || $d->{kind} eq '') {
                $add->('PC11', 'blocker', 'B-DATA-KIND', "required_data entry $i has no kind", $ref);
            }
            if ((!defined $d->{timeframe} || $d->{timeframe} eq '') && !$has_htf_amb) {
                $add->('PC11', 'blocker', 'B-DATA-TF', "required_data entry $i has null timeframe and no A-HTF-TF ambiguity recorded", $ref);
            }
        }
    }
    # --- PC12 contradictions ----------------------------------------------------------------------
    {
        my %seen;
        for my $cond (@{ $c->{conditions} || [] }) {
            my $p = parse_clause($cond->{condition}) or next;
            next unless $p->{dir} =~ /^(above|below)$/;
            my $key = lc($p->{subject}) . '|' . lc($p->{threshold});
            my $opp = $p->{dir} eq 'above' ? 'below' : 'above';
            if ($seen{$key} && $seen{$key} eq $opp) {
                $add->('PC12', 'blocker', 'B-CONTRA', "contradictory conditions: '" . $p->{subject} . "' is " . $seen{$key} . ' and ' . $p->{dir} . ' ' . $p->{threshold}, $cond->{id} // 'C-?', $seen{$key . '|id'} // '');
            }
            $seen{$key} = $p->{dir};
            $seen{ $key . '|id' } = $cond->{id} // 'C-?';
        }
    }
    # --- PC13 hidden/implicit assumptions (advisory) ---------------------------------------------------
    {
        if (clause_vague($c->{request_text} // '')) {
            my $has_thr = grep { ($_->{id} // '') eq 'A-THR' } @{ $c->{ambiguities} || [] };
            $add->('PC13', 'warning', 'W-IMPLICIT-THR', 'vague threshold wording in the request' . ($has_thr ? '' : ' without a recorded A-THR ambiguity'), 'natural_language_request');
        }
        if (@{ $c->{conditions} || [] } && !has_timing($c->{request_text} // '')) {
            my $has_conf = grep { ($_->{id} // '') eq 'A-CONF' } @{ $c->{ambiguities} || [] };
            $add->('PC13', 'warning', 'W-IMPLICIT-TIMING', 'conditions present without execution-timing wording' . ($has_conf ? '' : ' and without A-CONF ambiguity'), 'boolean_conditions');
        }
    }
    # --- PC14 traceability integrity ---------------------------------------------------------------------
    {
        $add->('PC14', 'blocker', 'B-TRACE-SKILLS', 'source_skills empty — routing decisions must be copied into the contract', 'source_skills') unless @{ $c->{source_skills} || [] };
        $add->('PC14', 'blocker', 'B-TRACE-REQ', 'verification_requirements empty — downstream checks unrecorded', 'verification_requirements') unless @{ $c->{verification_requirements} || [] };
        $add->('PC14', 'blocker', 'B-TRACE-CONST', 'implementation_constraints empty', 'implementation_constraints') unless @{ $c->{implementation_constraints} || [] };
        my %ids;
        my @all;
        for my $lst ($c->{ambiguities}, $c->{edge_cases}, $c->{conditions}, $c->{formulas}) {
            for my $e (@{ $lst || [] }) { push @all, $e->{id} // ''; }
        }
        for my $id (@all) {
            next unless length $id;
            if ($ids{$id}) { $add->('PC14', 'blocker', 'B-TRACE-DUP', "duplicate contract element id '" . $id . "'", $id); }
            $ids{$id} = 1;
        }
    }
    # upstream blockers are merged here (parsed separately by verify())
    return \@F;
}

# ---------------------------------------------------------------------------
# verification orchestration
# ---------------------------------------------------------------------------
sub _finalize {
    my ($r, $c) = @_;
    my @findings = @{ $r->{findings} || [] };
    my $i = 0;
    for my $f (@findings) { $i++; $f->{id} = sprintf('F-%03d', $i); }
    my @blockers = grep { $_->{severity} eq 'blocker' } @findings;
    my @warnings = grep { $_->{severity} eq 'warning' } @findings;
    my @checks;
    for my $d (@DOMAINS) {
        my ($cid, $dom) = @$d;
        my @mine = grep { $_->{check_id} eq $cid } @findings;
        my $verdict = (grep { $_->{severity} eq 'blocker' } @mine) ? 'fail' : (@mine ? 'warn' : 'pass');
        push @checks, { check_id => $cid, domain => $dom, verdict => $verdict, findings => [map { $_->{id} } @mine] };
    }
    my (@amb_mirror, @unresolved);
    if ($c) {
        for my $a (@{ $c->{ambiguities} || [] }) {
            my $st = $a->{resolution_status} // 'unresolved';
            push @amb_mirror, { id => ($a->{id} // ''), resolution_status => $st };
            push @unresolved, $a->{id} // () if $st eq 'unresolved';
        }
        for my $e (@{ $c->{edge_cases} || [] }) {
            my $rb = $e->{required_behavior};
            push @unresolved, $e->{id} // () if !defined $rb || $rb eq '' || $rb eq 'null';
        }
    }
    my @body = ($r->{request_id} // '', $r->{approved_routing_id} // '', $r->{formalization_id} // '', $r->{contract_sha} // '');
    push @body, map { $_->{verdict} } @checks;
    for my $f (@findings) { push @body, $f->{id}, $f->{check_id}, $f->{severity}, $f->{code}, $f->{message}, join("\x1E", @{ $f->{refs} || [] }); }
    push @body, map { $_->{code} } @warnings;
    push @body, @unresolved;
    push @body, map { $_->{id} . '=' . $_->{resolution_status} } @amb_mirror;
    my $vid = 'pre-' . substr(sha256_hex(encode('UTF-8', join("\x1F", @body))), 0, 12);
    my $result = $r->{input_valid} ? 'INVALID_INPUT'
               : (@blockers ? 'BLOCKED' : (@warnings ? 'PASS_WITH_WARNINGS' : 'PASS'));
    my $open = ($result eq 'PASS' || $result eq 'PASS_WITH_WARNINGS') ? 1 : 0;
    $r->{checks} = \@checks;
    $r->{findings} = \@findings;
    $r->{blockers} = \@blockers;
    $r->{warnings} = \@warnings;
    $r->{ambiguities_mirror} = \@amb_mirror;
    $r->{unresolved_items} = \@unresolved;
    $r->{verification_id} = $vid;
    $r->{result} = $result;
    $r->{status} = $open ? 'passed' : 'blocked';
    $r->{implementation_allowed} = $open;
    $r->{feasibility_allowed} = $open;
    $r->{next_stage} = $open ? 'FEASIBILITY' : 'HALT';
    return $r;
}

sub verify_text {
    my ($text) = @_;
    if (!defined $text || $text !~ /\S/) {
        return _finalize({ input_valid => 1, findings => [{ check_id => 'PC01', severity => 'blocker', code => 'B-INPUT', message => 'formalization contract missing or empty', refs => ['contract_file'] }] }, undef);
    }
    my $c = eval { parse_contract($text) };
    if (!$c) {
        my $err = $@ // 'unknown parse error'; $err =~ s/\s+$//; $err =~ s/ at .* line \d+\.*$//;
        return _finalize({ input_valid => 1, findings => [{ check_id => 'PC01', severity => 'blocker', code => 'B-INPUT', message => "formalization contract could not be parsed: $err", refs => ['contract_file'] }] }, undef);
    }
    my $findings = run_checks($c);
    return _finalize({
        input_valid => 0,
        (map { $_ => $c->{$_} } qw(request_id approved_routing_id formalization_id)),
        contract_sha => sha256_hex(encode('UTF-8', $text)),
        findings => $findings,
    }, $c);
}

# ---------------------------------------------------------------------------
# result emitter (fixed field order; all scalars single-quoted, '' escaped)
# ---------------------------------------------------------------------------
sub _q { my $s = shift // 'null'; $s =~ s/'/''/g; return "'$s'"; }
sub _ql { my ($l) = @_; return '[]' unless @{ $l || [] }; return '[' . join(', ', map { _q($_) } @$l) . ']'; }

sub result_to_yaml {
    my ($r) = @_;
    my @o;
    push @o, "# pre-verification result — generated by pre_verify.pl (schema v1.1; meta/pre_verification_procedure.md)";
    push @o, 'schema_version: "1.1"', 'stage: pre_verification', 'predecessor: formalization', 'successor: feasibility', '';
    push @o, 'pre_verification:';
    push @o, "  request_id: " . _q($r->{request_id});
    push @o, "  approved_routing_id: " . _q($r->{approved_routing_id});
    push @o, "  formalization_id: " . _q($r->{formalization_id});
    push @o, "  verification_id: " . _q($r->{verification_id});
    push @o, "  result: " . _q($r->{result});
    push @o, "  status: " . _q($r->{status});
    push @o, "  implementation_allowed: " . ($r->{implementation_allowed} ? 'true' : 'false');
    push @o, "  feasibility_allowed: " . ($r->{feasibility_allowed} ? 'true' : 'false');
    push @o, "  next_stage: " . $r->{next_stage};
    push @o, "  checks:";
    for my $c (@{ $r->{checks} }) {
        push @o, "    - { check_id: " . _q($c->{check_id}) . ", domain: " . _q($c->{domain}) . ", verdict: " . _q($c->{verdict}) . ", findings: " . _ql($c->{findings}) . " }";
    }
    if (!@{ $r->{findings} }) { push @o, '  findings: []'; }
    else {
        push @o, '  findings:';
        for my $f (@{ $r->{findings} }) {
            push @o, "    - { id: " . _q($f->{id}) . ", check_id: " . _q($f->{check_id}) . ", severity: " . _q($f->{severity}) . ", code: " . _q($f->{code}) . ", message: " . _q($f->{message}) . ", refs: " . _ql($f->{refs}) . " }";
        }
    }
    if (!@{ $r->{blockers} }) { push @o, '  blockers: []'; }
    else {
        push @o, '  blockers:';
        for my $b (@{ $r->{blockers} }) { push @o, "    - { id: " . _q($b->{id}) . ", check_id: " . _q($b->{check_id}) . ", reason: " . _q($b->{code} . ' — ' . $b->{message}) . " }"; }
    }
    if (!@{ $r->{warnings} }) { push @o, '  warnings: []'; }
    else {
        push @o, '  warnings:';
        for my $w (@{ $r->{warnings} }) { push @o, "    - { id: " . _q($w->{id}) . ", check_id: " . _q($w->{check_id}) . ", code: " . _q($w->{code}) . ", message: " . _q($w->{message}) . " }"; }
    }
    if (!@{ $r->{ambiguities_mirror} }) { push @o, '  ambiguities: []'; }
    else {
        push @o, '  ambiguities:';
        for my $a (@{ $r->{ambiguities_mirror} }) { push @o, "    - { id: " . _q($a->{id}) . ", resolution_status: " . _q($a->{resolution_status}) . " }"; }
    }
    push @o, "  unresolved_items: " . _ql($r->{unresolved_items});
    push @o, '  next_stage_note: ' . _q($r->{next_stage} eq 'FEASIBILITY' ? 'Phase 7 Feasibility may start' : 'pipeline halted — downstream progression forbidden');
    return join("\n", @o) . "\n";
}

# ---------------------------------------------------------------------------
# gate-check on a RESULT file: approved iff verification_id well-formed,
# result PASS|PASS_WITH_WARNINGS, blockers [], feasibility_allowed true
# ---------------------------------------------------------------------------
sub gate_check_text {
    my ($t) = @_;
    my ($vid) = $t =~ /^\s{2}verification_id:\s*'([^']*)'/m;
    my ($res) = $t =~ /^\s{2}result:\s*'([^']*)'/m;
    my ($fa)  = $t =~ /^\s{2}feasibility_allowed:\s*(true|false)/m;
    my $blockers_empty = ($t =~ /^  blockers: \[\]/m) ? 1 : 0;
    return (0, 'verification_id missing or malformed') unless defined $vid && $vid =~ /^pre-[0-9a-f]{12}$/;
    return (0, "result is '$res' — downstream progression forbidden") unless defined $res && $res =~ /^PASS/;
    return (0, 'blockers list is non-empty') unless $blockers_empty;
    return (0, "feasibility_allowed is '$fa'") unless defined $fa && $fa eq 'true';
    return (1, "approved_verification_id = $vid");
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
sub _slurp { my $f = shift; open my $fh, '<:raw', $f or die "cannot read '$f': $!\n"; local $/; my $t = <$fh>; close $fh; return $t; }

sub main {
    my ($contract_file, $out_file, $gate) = (undef, undef, 0);
    while (@ARGV) {
        my $a = shift @ARGV;
        if    ($a eq '--contract') { $contract_file = shift @ARGV; }
        elsif ($a eq '--out')      { $out_file = shift @ARGV; }
        elsif ($a eq '--gate-check') { $gate = 1; }
        elsif ($a eq '--selftest') { my $st = selftest(); exit $st; }
        else { die "unknown argument '$a'\n"; }
    }
    die "usage: pre_verify.pl --contract FILE [--out FILE] | --gate-check --contract FILE | --selftest\n" if !$gate && !$contract_file;
    if ($gate) {
        die "--gate-check requires --contract FILE\n" unless $contract_file;
        my $t = eval { _slurp($contract_file) } // die "cannot read '$contract_file'\n";
        my ($ok, $msg) = gate_check_text($t);
        print "$msg\n";
        exit($ok ? 0 : 2);
    }
    my $text = eval { _slurp($contract_file) };
    my $r = verify_text($text);
    my $yaml = result_to_yaml($r);
    if ($out_file) { open my $fh, '>:raw', $out_file or die "cannot write '$out_file': $!\n"; print $fh $yaml; close $fh; }
    else { print $yaml; }
    exit(($r->{result} =~ /^PASS/) ? 0 : 2);
}

# ---------------------------------------------------------------------------
# selftest — 20 mandated acceptance cases (TEST-PRE-001..020)
# ---------------------------------------------------------------------------
sub selftest {
    my ($pass, $fail) = (0, 0);
    my $ok = sub { my ($cond, $name) = @_; if ($cond) { $pass++; } else { $fail++; print "FAIL: $name\n"; } };
    my $BASE = <<'EOB';
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
EOB
    my $fx = sub { my %o = @_; my $t = $BASE; $t =~ s/\Q$_\E/$o{$_}/g for keys %o; return $t; };
    my $blocked = sub { my ($r, $code, $name) = @_; $ok->(defined $r && $r->{result} eq 'BLOCKED' && (grep { $_->{code} eq $code } @{ $r->{blockers} }), "$name [$code]"); };
    local *blocked = $blocked;   # bareword blocked->(...) resolves at runtime

    # T-PRE-001 valid completed contract -> PASS (mandated #1)
    my $r1 = verify_text($BASE);
    $ok->($r1->{result} eq 'PASS', 'T-PRE-001 result PASS');
    $ok->($r1->{status} eq 'passed' && $r1->{feasibility_allowed} && $r1->{implementation_allowed} && $r1->{next_stage} eq 'FEASIBILITY', 'T-PRE-001 gates open');
    $ok->(scalar @{ $r1->{checks} } == 14 && (grep { $_->{verdict} ne 'pass' } @{ $r1->{checks} }) == 0, 'T-PRE-001 14 checks all pass');

    # T-PRE-002 implementation_allowed false -> BLOCKED (mandated #2)
    blocked->(verify_text($fx->("implementation_allowed: true" => "implementation_allowed: false")), 'B-GATE', 'T-PRE-002');

    # T-PRE-003 upstream blockers remain -> BLOCKED (mandated #3)
    blocked->(verify_text($fx->("  blockers: []" => "  blockers:\n    - { id: 'B-X', reason: 'upstream failure' }")), 'B-GATE', 'T-PRE-003');

    # T-PRE-004 unresolved behavior-affecting ambiguity -> BLOCKED (mandated #4)
    my $r4 = verify_text($fx->('  ambiguities: []' => "  ambiguities:\n    - { id: 'A-1', description: 'd', options: 'o', affects_behavior: true, resolution_status: 'unresolved' }"));
    blocked->($r4, 'B-AMB-UNRESOLVED', 'T-PRE-004');
    $ok->((grep { $_->{check_id} eq 'PC07' } @{ $r4->{blockers} }), 'T-PRE-004 PC07 verdict');

    # T-PRE-005 resolved_by_user ambiguity -> allowed (mandated #5)
    my $r5 = verify_text($fx->('  ambiguities: []' => "  ambiguities:\n    - { id: 'A-1', description: 'd', options: 'o', affects_behavior: true, resolution_status: 'resolved_by_user' }"));
    $ok->($r5->{result} eq 'PASS', 'T-PRE-005 resolved_by_user unlocks');

    # T-PRE-006 resolved_assumed must NOT unlock (mandated #6, TEST-FORMALIZATION-001 must_not)
    blocked->(verify_text($fx->('  ambiguities: []' => "  ambiguities:\n    - { id: 'A-1', description: 'd', options: 'o', affects_behavior: true, resolution_status: 'resolved_assumed' }")), 'B-AMB-ASSUMED', 'T-PRE-006');

    # T-PRE-007 formula dependency error (mandated #7)
    my $f7 = $fx->("  formulas: []" => "  formulas:\n    - { id: 'F-1', expression: 'close / open', description: 'd', depends_on: 'F-9' }");
    my $r7 = verify_text($f7);
    blocked->($r7, 'B-DEP', 'T-PRE-007 dep');

    # T-PRE-008 missing variable/reference (mandated #8)
    my $r8 = verify_text($fx->("condition: 'close crosses over 30'" => "condition: 'rsi crosses over 30'"));
    blocked->($r8, 'B-VAR-MISSING', 'T-PRE-008');
    $ok->((grep { (grep { $_ eq 'rsi' } @{ $_->{refs} }) } @{ $r8->{blockers} }), 'T-PRE-008 ref traces subject');

    # T-PRE-009 contradictory conditions (mandated #9)
    my $r9 = verify_text($fx->("    - { id: 'C-1', condition: 'close crosses over 30', meaning: 'verbatim request clause', used_by: 'entry' }" => "    - { id: 'C-1', condition: 'close is above 50', meaning: 'verbatim request clause', used_by: 'entry' }\n    - { id: 'C-2', condition: 'close is below 50', meaning: 'verbatim request clause', used_by: 'exit' }"));
    blocked->($r9, 'B-CONTRA', 'T-PRE-009');

    # T-PRE-010 incomplete required-data specification (mandated #10)
    my $r10 = verify_text($fx->("  required_data: []" => "  required_data:\n    - { kind: 'price', symbol_hint: null, timeframe: null, notes: 'htf' }", "  mtf: false" => '  mtf: true', "  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "  repaint_risk: 'high — mechanism: unconfirmed HTF data'"));
    blocked->($r10, 'B-DATA-TF', 'T-PRE-010');

    # T-PRE-011 MTF inconsistency (mandated #11): mtf true, chart null, no data, low repaint
    my $r11 = verify_text($fx->("    chart: '15m'" => '    chart: null', "  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'", "  mtf: false" => '  mtf: true'));
    for my $code ('B-MTF-CHART', 'B-MTF-DATA', 'B-MTF-REPAINT') { blocked->($r11, $code, 'T-PRE-011'); }

    # T-PRE-012 repaint-risk classification (mandated #12)
    blocked->(verify_text($fx->("  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => '  repaint_risk: null')), 'B-REPAINT-UNDECLARED', 'T-PRE-012a null');
    blocked->(verify_text($fx->("  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "  repaint_risk: 'extreme — mechanism: m'")), 'B-REPAINT-MALFORMED', 'T-PRE-012b malformed');
    my $r12c = verify_text($fx->("  repaint_risk: 'low — mechanism: no repaint mechanism detected in the request'" => "  repaint_risk: 'high — mechanism: unconfirmed HTF data'"));
    $ok->($r12c->{result} eq 'PASS_WITH_WARNINGS' && (grep { $_->{code} eq 'W-REPAINT-ACCEPT' } @{ $r12c->{warnings} }), 'T-PRE-012c high warns');

    # T-PRE-013 edge-case coverage (mandated #13): division w/o E-DIV blocked; guard wording clears
    my $divfx = "  formulas:\n    - { id: 'F-1', expression: 'close / open', description: 'd', depends_on: '' }";
    blocked->(verify_text($fx->('  formulas: []' => $divfx)), 'B-EC-DIV', 'T-PRE-013a');
    my $r13b = verify_text($fx->('  formulas: []' => $divfx, "natural_language_request: 'close crosses over 30 on bar close'" => "natural_language_request: 'close crosses over 30 on bar close with zero check'"));
    $ok->(!(grep { $_->{code} eq 'B-EC-DIV' } @{ $r13b->{blockers} }), 'T-PRE-013b guard wording recognized');

    # T-PRE-014 traceability integrity (mandated #14)
    my $r14 = verify_text($fx->("  source_skills: ['strategy-engine', 'momentum-indicators']" => '  source_skills: []'));
    blocked->($r14, 'B-TRACE-SKILLS', 'T-PRE-014');
    $ok->(!(grep { !@{ $_->{refs} || [] } } @{ $r14->{findings} }), 'T-PRE-014 every finding has refs');

    # T-PRE-015 deterministic verification id (mandated #15)
    my ($ra, $rb) = (verify_text($BASE), verify_text($BASE));
    $ok->($ra->{verification_id} eq $rb->{verification_id}, 'T-PRE-015 id stable');
    my $rc = verify_text($fx->("    chart: '15m'" => "    chart: '1h'"));
    $ok->($ra->{verification_id} ne $rc->{verification_id}, 'T-PRE-015 id content-sensitive');

    # T-PRE-016 byte-identical repeated output (mandated #16)
    $ok->(result_to_yaml($ra) eq result_to_yaml($rb), 'T-PRE-016 byte-identical');
    $ok->(result_to_yaml($ra) ne result_to_yaml($rc), 'T-PRE-016 distinct inputs differ');

    # T-PRE-017 malformed formalization contract -> INVALID_INPUT (mandated #17)
    my $r17 = verify_text("\tnot a contract }}}");
    $ok->($r17->{result} eq 'INVALID_INPUT' && (grep { $_->{code} eq 'B-INPUT' } @{ $r17->{blockers} }), 'T-PRE-017 INVALID_INPUT');
    $ok->((grep { $_->{check_id} =~ /^PC\d+$/ } @{ $r17->{blockers} }), 'T-PRE-017 finding attributed');

    # T-PRE-018 invalid/missing handoff (mandated #18)
    my $r18 = verify_text(undef);
    $ok->($r18->{result} eq 'INVALID_INPUT', 'T-PRE-018a missing input');
    my $r18b = verify_text("   \n  ");
    $ok->($r18b->{result} eq 'INVALID_INPUT', 'T-PRE-018b empty input');

    # T-PRE-019 no-Pine output invariant (mandated #19)
    my $out = result_to_yaml($r1);
    my $pine_free = 1;
    for my $tok ('//@version', 'indicator(', 'strategy(', 'library(', 'plot(', 'ta.sma', 'ta.rsi') { $pine_free = 0 if index($out, $tok) >= 0; }
    $ok->($pine_free, 'T-PRE-019 no Pine constructs in result');

    # T-PRE-020 downstream gate behavior (mandated #20)
    require File::Temp;
    my ($fh1, $p1) = File::Temp::tempfile(SUFFIX => '.yaml');
    print $fh1 result_to_yaml($r1); close $fh1;
    my ($okg, $msgg) = gate_check_text(_slurp($p1));
    $ok->($okg && $msgg =~ /approved_verification_id = pre-[0-9a-f]{12}/, 'T-PRE-020a gate approves PASS');
    my ($fh2, $p2) = File::Temp::tempfile(SUFFIX => '.yaml');
    print $fh2 result_to_yaml($r17); close $fh2;
    my ($okb, $msgb) = gate_check_text(_slurp($p2));
    $ok->(!$okb && $msgb =~ /forbidden|non-empty|malformed/, 'T-PRE-020b gate refuses INVALID_INPUT');
    my ($fh3, $p3) = File::Temp::tempfile(SUFFIX => '.yaml');
    my $rbk = verify_text($fx->("implementation_allowed: true" => 'implementation_allowed: false'));
    print $fh3 result_to_yaml($rbk); close $fh3;
    my ($okc,) = gate_check_text(_slurp($p3));
    $ok->(!$okc && $rbk->{next_stage} eq 'HALT' && !$rbk->{feasibility_allowed}, 'T-PRE-020c gate refuses BLOCKED; HALT');
    for my $p ($p1, $p2, $p3) { 1 while unlink $p; }

    print "SELFTEST: $pass passed, $fail failed\n";
    print "All TEST-PRE-001..020 acceptance cases pass (pre-verification contract v1.1).\n" if !$fail;
    return $fail ? 1 : 0;
}

main() unless caller;
1;
