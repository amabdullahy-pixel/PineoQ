#!/usr/bin/perl
# ============================================================================
# router.pl — Pine Agent Skill Router DECISION ENGINE (contract routing/2)
# ============================================================================
# PHASE 4 — Router Implementation (executes the PHASE 3 design).
#
# Spec    : meta/skill_router.md (Design Specification v2.0.0, routing/2)
# Config  : config/routing.yaml (five layers)
# Registry: skills/registry.yaml (77 Skills, Import Mode output)
# Overlap : skills/import-reports/processing-index.yaml duplicate_candidates
#           (redundancy-analysis source of truth)
#
# The Router is a SELECTOR AND PLANNER, not an implementation engine (§15):
# never creates/modifies/merges Skills, never activates non-eligible entries,
# never executes Pine code, never bypasses downstream stages. Only
# routing_status: ready sets downstream.allowed: true.
#
# Determinism (§16): same request text + same registry revision =>
#   byte-identical output. No randomness, no session state, no clock.
#   All caps/thresholds read from config/routing.yaml. Tie-break order:
#   priority (1=highest) -> narrowest domain match (fewest domains) ->
#   lowest dependency count -> registry id lexicographic.
#
# Class core sets: engine constant CLASS_CORE, sourced from Registry skill
#   `skill-routing` (75) rule 2 ("core {...} + topic skills") and rule 3
#   ("06 is in EVERY set that touches code/APIs"). Skill 75 itself is the
#   router METHOD and is never selected — this engine IS its execution.
#
# Matching model (deterministic, no fuzzing — config fuzzy_matching: false):
#   a candidate's grade comes from exact substring hits of REGISTERED
#   triggers (English + Persian, equal force) inside the normalized request:
#     trigger hit(s) + voted domains  -> match
#     trigger hit(s) only             -> partial_match
#     domain votes without trigger hit -> weak_match (never selected)
#     neither                          -> no_match
#   Domain votes are the summed trigger hits of vote-casting eligible skills.
#   Capabilities are identified by the set of matched triggers; two match
#   candidates with an IDENTICAL matched-trigger signature cover the same
#   capability — the tie-break keeps one, the other is excluded as an
#   alternative (minimal sufficiency; never merged).
#
# Runtime: core Perl only (no CPAN). `use utf8` keeps Persian handling exact.
#
# CLI:
#   perl skills/agent/router.pl --request "TEXT" [--format yaml|json|v1]
#        [--registry FILE] [--config FILE] [--overlaps FILE] [--out FILE]
#   perl skills/agent/router.pl --selftest
#
# Exit codes: 0 = ready (handoff permitted); 2 = any non-ready status.
#
# Output formats:
#   yaml (default) — contract routing/2 (meta/skill_router.md §13)
#   v1             — v0.1 compatibility: status ready->routed (else blocked),
#                    numeric estimated_context_size, unresolved_triggers
#   json           — same decision, JSON encoding
# ============================================================================

use strict;
use warnings;
use utf8;
use Encode qw(decode encode);
use File::Temp qw(tempfile);

our $VERSION = '1.0.0';
my $CONTRACT_VERSION = 'routing/2';
my $ROUTER_ID        = 'router.pl';

# ---------------------------------------------------------------------------
# Class core sets (source: skill-routing rule 2/3 — see header note).
# ---------------------------------------------------------------------------
my %CLASS_CORE = (
    conceptual                => [],
    analytical                => [],
    debugging                 => ['pine-version-intelligence', 'pine-debugging-and-testing'],
    mathematical              => [],
    indicator_design          => ['pine-language-core', 'pine-version-intelligence'],
    strategy_logic            => ['pine-language-core', 'pine-version-intelligence',
                                  'strategy-engine'],
    'Pine_Script_implementation' => ['pine-language-core', 'pine-version-intelligence',
                                  'requirements-engineering', 'pine-code-architecture'],
    MTF                       => [],
    performance               => [],
    visualization             => [],
    verification              => ['pine-version-intelligence', 'code-review-and-refactoring'],
    research                  => ['research-methodology'],
    architecture              => ['pine-code-architecture'],
    mixed                     => [],   # filled dynamically from tied classes
);
my $CLASS_STEM_DOMAIN = {          # class -> preferred domain id when no votes exist
    debugging    => 'debugging',
    verification => 'verification',
    MTF          => 'mtf',
    performance  => 'performance',
    research     => 'research-methods',
};

# ---------------------------------------------------------------------------
# Classification markers (deterministic, EN + FA). Additive detection.
# ---------------------------------------------------------------------------
my %CLASS_MARKERS = (
    conceptual => [
        qr/\bwhat (?:is|does|are)\b/i, qr/\bwhy (?:is|are|do)\b/i,
        qr/\bhow (?:does|do)\b/i,      qr/\bdifference between\b/i,
        qr/\bmeaning of\b/i,           qr/\bexplain\b/i, qr/\bdefine\b/i,
        qr/\Qچیست\E/, qr/\Qچیه\E/, qr/\Qچرا\E/, qr/\Qتفاوت\E/, qr/\Qیعنی چی\E/, qr/\Qتوضیح بده\E/,
    ],
    analytical => [
        qr/\bstatistic/i, qr/\bbacktest(?:ing)?\b/i, qr/\banaly[sz]e\b/i, qr/\bvalidation\b/i,
        qr/\Qتحلیل\E/,
    ],
    debugging => [
        qr/\bwhy does my\b/i,          qr/\bdebug\b/i,      qr/\bfix(ed)?\b/i,
        qr/\bnot working\b/i,          qr/\bfire twice\b/i, qr/\berror(s)?\b/i,
        qr/\bCE\b/, qr/\bRE\b/,        qr/\bwrong (?:value|result|signal)\b/i,
        qr/\bflip(s|ping)?\b/i,        qr/\bbreaks? when\b/i,
        qr/\Qدیباگ\E/, qr/\Qخطا\E/, qr/\Qارور\E/, qr/\Qکار نمی\E/,
    ],
    mathematical => [
        qr/\bformula\b/i, qr/\bcalculate\b/i, qr/\bmath\b/i, qr/\bderivation\b/i,
        qr/\Qفرمول\E/, qr/\Qمحاسبه\E/,
    ],
    indicator_design => [
        qr/\bindicator design\b/i, qr/\bdesign (?:a |an )?indicator\b/i,
        qr/\bnew indicator\b/i,    qr/\bcreate (?:a |an )?indicator\b/i,
        qr/\Qطراحی اندیکاتور\E/,
    ],
    strategy_logic => [
        qr/\bstrategy\b/i, qr/\bentry (?:rule|condition|logic)\b/i,
        qr/\bexit (?:rule|condition|logic)\b/i, qr/\bstop loss\b/i,
        qr/\btake profit\b/i, qr/\bpyramiding\b/i,
        qr/\Qاستراتژی\E/, qr/\Qحد ضرر\E/, qr/\Qحد سود\E/, qr/\Qورود و خروج\E/,
    ],
    'Pine_Script_implementation' => [
        qr/\bbuild\b/i, qr/\bwrite\b/i, qr/\bimplement\b/i,
        qr/\bcreate (?:a |an )?(?:indicator|strategy|script)\b/i,
        qr/\bcod(?:e|ing) (?:it|this|my)\b/i,
        qr/\Qبساز\E/, qr/\Qبنویس\E/, qr/\Qپیاده سازی\E/,
    ],
    MTF => [
        qr/\bhigher[ -]?timeframe\b/i, qr/\bhtf\b/i, qr/\bmulti[ -]?timeframe\b/i,
        qr/\brequest\.security/i,      qr/\blower[ -]?timeframe\b/i, qr/\bintrabar(s)?\b/i,
        qr/\Qتایم\u200cفریم\E/, qr/\Qچند تایم\E/, qr/\Qاینتربار\E/, qr/\Qتایم فریم\E/,
    ],
    performance => [
        qr/\bslow\b/i, qr/\bperformance\b/i, qr/\btimeout\b/i, qr/\btoo (?:slow|many)\b/i,
        qr/\Qکند است\E/, qr/\Qبهینه سازی اجرا\E/, qr/\Qسرعت\E/,
    ],
    visualization => [
        qr/\bplot(s|ting)?\b/i, qr/\blabel(s)?\b/i, qr/\btable(s)?\b/i,
        qr/\bcolor(s)?\b/i,     qr/\bdrawing(s)?\b/i,
        qr/\Qنمایش\E/, qr/\Qلیبل\E/, qr/\Qجدول\E/, qr/\Qرنگ\E/,
    ],
    verification => [
        qr/\breview\b/i, qr/\baudit\b/i, qr/\bcheck my\b/i,
        qr/\bbefore (?:i |we )?(?:ship|publish)\b/i, qr/\bverify my\b/i,
        qr/\Qبازبینی\E/, qr/\Qممیزی\E/, qr/\Qچک کنید\E/,
    ],
    research => [
        qr/\bresearch\b/i, qr/\bis it true\b/i, qr/\bevidence\b/i, qr/\bhypothes/is,
        qr/\Qپژوهش\E/, qr/\Qتحقیق\E/, qr/\Qفرضیه\E/,
    ],
    architecture => [
        qr/\brefactor\b/i, qr/\bfile organi[sz]ation\b/i, qr/\bcode structure\b/i,
        qr/\Qبازآرایی\E/, qr/\Qساختار کد\E/,
    ],
);

# Ambiguity instance (TEST-ROUTING-007 fixture b): two parameterized RSI
# readings compared with no length/TF/symbol declaration — the documented
# "RSI1 vs RSI3" ambiguity class.
my $AMBIG_RSI_PAIR   = qr/\bRSI\s*\d+\s*[<>]\s*RSI\s*\d+/i;
my $AMBIG_NO_CONTEXT = qr/\b(?:length|period|timeframe|tf|symbol|resolution|src|source)\b/i;

# Conflict instance (spec §10; TEST-ROUTING-007 fixture e): one signal with
# opposing confirmation semantics and no declared tolerance. Implemented as a
# request-level pre-gate (stage 9 evaluated on the request semantics before
# selection so that a semantically self-contradictory request is flagged even
# when its vocabulary matches no registered trigger).
my $CONFLICT_INTRABAR  = qr/\b(?:intrabar|every tick|each tick|calc_on_every_tick)\b/i;
my $CONFLICT_CONFIRMED = qr/\b(?:barstate\.isconfirmed|close[ -]?confirm\w*|confirmed (?:close|bar|htf|higher[ -]?timeframe)|close to be confirmed)\b/i;

my @STOPWORDS = qw(a an the my our your of for in on with to and or is are does do
                   what why how when that this it its i we you should must be been
                   have has want need please help about into from as at by);
my $CODE_TOUCHING = qr/\b(?:script|code|pine|indicator|strategy)\b/i;

# ===========================================================================
# Small utilities
# ===========================================================================
sub _u    { return decode('UTF-8', $_[0]); }
sub _trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s; }
sub _norm { my $s = _trim(shift); $s =~ s/\s+/ /g; $s =~ s/[-_]+/ /g; return $s; }
sub _min  { return $_[0] < $_[1] ? $_[0] : $_[1]; }
sub _uniq { my %s; return grep { !$s{$_}++ } @_; }

sub _q { my $s = shift; $s =~ s/'/''/g; return "'$s'"; }
sub _jq {
    my $s = shift;
    $s =~ s/\\/\\\\/g; $s =~ s/"/\\"/g;
    $s =~ s/\t/\\t/g; $s =~ s/\n/\\n/g; $s =~ s/\r/\\r/g;
    return "\"$s\"";
}

sub _trigger_hit { my ($r, $t) = @_; return index(_norm($r), _norm($t)) >= 0 ? 1 : 0; }

# ===========================================================================
# Registry parsing — YAML subset (shapes actually used by skills/registry.yaml)
# ===========================================================================
sub _flow_complete { my $s = shift; my $o = () = $s =~ /\[/g; my $c = () = $s =~ /\]/g; return $o <= $c; }

sub _parse_flow_list {
    my $s = _trim(shift);
    $s =~ s/^\[//; $s =~ s/\]$//;
    my @items = map { my $i = _trim($_); $i =~ s/^['"]|['"]$//g; $i } split /,/, $s;
    return [ grep { length } @items ];
}

sub parse_registry {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file
        or die "$ROUTER_ID: cannot read registry '$file': $!\n";
    my (%skills, @order);
    my $in_skills = 0;
    my ($cur, $submap, $subkey, $flow_key, $flow_buf) = (undef, '', '', undef, '');

    my $store_list = sub {
        my ($v) = @_;
        return unless $cur;
        if    ($submap eq 'triggers'     && $subkey eq 'english')   { push @{ $cur->{tr_eng} },   @{ _parse_flow_list($v) } }
        elsif ($submap eq 'triggers'     && $subkey eq 'persian')   { push @{ $cur->{tr_fa} },    @{ _parse_flow_list($v) } }
        elsif ($submap eq 'dependencies' && $subkey eq 'mandatory') { push @{ $cur->{dep_mand} }, @{ _parse_flow_list($v) } }
        elsif ($submap eq 'dependencies' && $subkey eq 'optional')  { push @{ $cur->{dep_opt} },  @{ _parse_flow_list($v) } }
        return;
    };
    my $store_scalar = sub {
        my ($k, $v) = @_;
        return unless $cur;
        $v = _trim($v); $v =~ s/^['"]|['"]$//g;
        $cur->{$k} = $v;
    };

    while (my $line = <$fh>) {
        $line =~ s/\r?\n$//;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;

        if (defined $flow_key) {                                    # multi-line flow list
            $flow_buf .= ' ' . _trim($line);
            if (_flow_complete($flow_buf)) {
                if ($flow_key eq 'domains') { push @{ $cur->{domains} }, @{ _parse_flow_list($flow_buf) }; }
                else { $store_list->($flow_buf); }
                ($flow_key, $flow_buf) = (undef, '');
            }
            next;
        }
        if ($line =~ /^skills:\s*$/) { $in_skills = 1; next; }
        next unless $in_skills;

        if ($line =~ /^  - id:\s*(.+?)\s*$/) {                      # new entry
            $skills{ $cur->{id} } = $cur if $cur;
            my $id = $1; $id =~ s/^['"]|['"]$//g;
            $cur = { id => $id, name => '', version => '', path => '', source_path => '',
                     layer => '', domains => [], tr_eng => [], tr_fa => [],
                     dep_mand => [], dep_opt => [],
                     status => '', activation => '', validation_status => '',
                     import_batch => '', priority => 5 };
            push @order, $id;
            $submap = ''; $subkey = '';
            next;
        }
        next unless $cur;

        my $body = _trim($line);

        if ($body =~ /^-(.*)$/) {                                   # block list item
            my $item = _trim($1); $item =~ s/^['"]|['"]$//g;
            if    ($submap eq 'triggers'     && $subkey eq 'english')   { push @{ $cur->{tr_eng} }, $item }
            elsif ($submap eq 'triggers'     && $subkey eq 'persian')   { push @{ $cur->{tr_fa} },  $item }
            elsif ($submap eq 'dependencies' && $subkey eq 'mandatory') { push @{ $cur->{dep_mand} }, $item }
            elsif ($submap eq 'dependencies' && $subkey eq 'optional')  { push @{ $cur->{dep_opt} }, $item }
            next;
        }
        if ($body =~ /^(dependencies|triggers):\s*$/) { $submap = $1; $subkey = ''; next; }
        if ($submap && $body =~ /^(english|persian|mandatory|optional):\s*(.*)$/) {
            $subkey = $1; my $val = _trim($2);
            next if $val eq '';                                     # block items follow
            if (!_flow_complete($val)) { ($flow_key, $flow_buf) = ($submap, $val); next; }
            $store_list->($val);
            next;
        }
        if ($body =~ /^([\w-]+):\s*(.*)$/) {
            my ($k, $v) = ($1, _trim($2));
            $submap = '' if $k =~ /^(domains|triggers|dependencies|status|priority|layer|path|name|version|source_path|validation_status|import_batch|activation)$/;
            next if $v eq '';
            if ($k eq 'domains') {
                if (!_flow_complete($v)) { ($flow_key, $flow_buf) = ('domains', $v); next; }
                push @{ $cur->{domains} }, @{ _parse_flow_list($v) };
            } elsif (!$submap) {
                if (!_flow_complete($v) && $v =~ /^\[/) { ($flow_key, $flow_buf) = ('__plain__', $v); next; }
                $store_scalar->($k, $v);
            }
            next;
        }
    }
    $skills{ $cur->{id} } = $cur if $cur;
    close $fh;
    return { map => \%skills, order => \@order };
}

# ===========================================================================
# Routing config parsing — flattened dotted keys (routing.*)
# ===========================================================================
sub parse_routing_config {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file
        or die "$ROUTER_ID: cannot read routing config '$file': $!\n";
    my %cfg; my @path;                       # [indent, key]
    while (my $line = <$fh>) {
        $line =~ s/\r?\n$//;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        my ($indent) = $line =~ /^(\s*)/;
        my $body = _trim($line);
        pop @path while @path && $path[-1][0] >= length($indent);
        next if $body =~ /^- /;                                     # list items carry no keys (AFTER the pop)
        if ($body =~ /^([\w-]+):\s*(.*)$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/^\s*#.*$// if $v =~ /^\s*#/;    # value is entirely a comment
            $v =~ s/\s+#.*$//;                       # trailing comment after a real value
            $v = _trim($v);
            $v =~ s/^['"]|['"]$//g;                 # strip quoting
            push @path, [length($indent), $k] if $v eq '';
            my $key = join '.', (map { $_->[1] } @path), ($v eq '' ? () : ($k));
            $key =~ s/\.\././g;
            $cfg{$key} = $v if $v ne '';
        }
    }
    close $fh;
    return \%cfg;
}

sub _cget { my ($cfg, $key, $default) = @_; my $v = $cfg->{$key}; return defined $v ? $v : $default; }

# ===========================================================================
# Overlap record parsing (processing-index.yaml duplicate_candidates)
# ===========================================================================
sub parse_overlaps {
    my ($file) = @_;
    return {} unless defined $file && -e $file;
    open my $fh, '<:encoding(UTF-8)', $file or return {};
    my (%ov, $in, $buf);
    my $finish = sub {
        return unless defined $buf;
        my @files = $buf =~ /(skills\/incoming\/[^\s,\]]+)/g;
        my ($rel) = $buf =~ /relationship:\s*(\w+)/;
        my ($res) = $buf =~ /resolved:\s*(\w+)/;
        if (@files == 2 && $rel && $res && $res eq 'true') {
            my @ids = map { my $i = $_; $i =~ s{.*/\d+-([^./]+)\.\w+$}{$1}; $i } @files;
            $ov{ join '|', sort @ids } = { a => $ids[0], b => $ids[1], relationship => $rel };
        }
        $buf = undef;
    };
    while (my $line = <$fh>) {
        $line =~ s/\r?\n$//;
        if    ($line =~ /^duplicate_candidates:/) { $in = 1; next; }
        elsif ($line =~ /^\S/)                    { $finish->(); $in = 0; next; }
        next unless $in;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        $buf = defined($buf) ? $buf . ' ' . _trim($line) : _trim($line);
        $finish->() if $buf =~ /\}\s*$/;
    }
    $finish->();
    close $fh;
    return \%ov;
}

# ===========================================================================
# Pipeline stages
# ===========================================================================
sub stage1_normalize {
    my ($req) = @_;
    my $r = _trim($req); $r =~ s/\s+/ /g;
    return $r;
}

sub _marker_scan {
    my ($text) = @_;
    my %hits; my %pos;
    for my $class (keys %CLASS_MARKERS) {
        for my $re (@{ $CLASS_MARKERS{$class} }) {
            if ($text =~ $re) {
                $hits{$class} = ($hits{$class} // 0) + 1;
                my $p = $-[0];
                $pos{$class} = $p if !defined $pos{$class} || $p < $pos{$class};
            }
        }
    }
    return (\%hits, \%pos);
}

sub stage23_classify {
    my ($req, $class_order) = @_;
    my ($hits, $pos) = _marker_scan($req);
    my @fired = grep { ($hits->{$_} // 0) > 0 } @$class_order;
    my $primary = ''; my @secondary;
    if (@fired) {
        my $max = (sort { $b <=> $a } map { $hits->{$_} } @fired)[0];
        my @top = grep { $hits->{$_} == $max } @fired;
        if (@top >= 2) {
            @top = sort { ($pos->{$a} // 1e9) <=> ($pos->{$b} // 1e9) } @top;
            my $earliest = $pos->{ $top[0] } // 1e9;
            my @tied = grep { ($pos->{$_} // 1e9) == $earliest } @top;
            if (@tied >= 2) {
                $primary = 'mixed';
                @secondary = sort @tied;
            } else {
                $primary = $tied[0];
                @secondary = grep { $_ ne $primary } sort @top;
            }
        } else {
            $primary = $top[0];
            @secondary = grep { $_ ne $primary } sort @fired;
        }
    } else {
        $primary = 'conceptual';                                  # deterministic fallback (documented)
    }
    return ($primary, [sort @secondary], $hits);
}

sub stage4_domains {
    my ($req, $reg, $eligible, $primary) = @_;
    my %votes;
    my %voters;
    for my $id (@{ $reg->{order} }) {
        next unless $eligible->{$id};
        my $e = $reg->{map}{$id};
        my $h = 0;
        $h += _trigger_hit($req, $_) for @{ $e->{tr_eng} }, @{ $e->{tr_fa} };
        next unless $h;
        for my $d (@{ $e->{domains} }) {
            $votes{$d} = ($votes{$d} // 0) + $h;
            $voters{$d} = $id unless exists $voters{$d};
        }
    }
    my @known_domains = map { @{ $reg->{map}{$_}{domains} } } grep { $eligible->{$_} } @{ $reg->{order} };
    my %known = map { $_ => 1 } @known_domains;
    my @sorted = sort {
        $votes{$b} <=> $votes{$a}
        || (($voters{$a} // 'z') cmp ($voters{$b} // 'z'))
        || $a cmp $b
    } keys %votes;
    my $primary_domain = @sorted ? $sorted[0] : '';
    if (!$primary_domain) {                                       # fallback 1: class stem domain (Registry-driven)
        my $stem = $CLASS_STEM_DOMAIN->{$primary} // '';
        $primary_domain = $stem if $stem && $known{$stem};
    }
    my @secondary = grep { $_ ne $primary_domain } @sorted;
    @secondary = @secondary[0 .. _min($#secondary, 2)] if @secondary > 3;
    return ($primary_domain, \@secondary);
}

sub grade_candidates {
    my ($req, $reg, $eligible, $votes) = @_;
    my @grades;
    for my $id (@{ $reg->{order} }) {
        next unless $eligible->{$id};
        my $e = $reg->{map}{$id};
        my @hits;
        for my $t (@{ $e->{tr_eng} }, @{ $e->{tr_fa} }) { push @hits, _norm($t) if _trigger_hit($req, $t); }
        my $dom_votes = 0; $dom_votes += ($votes->{$_} // 0) for @{ $e->{domains} };
        my $grade = @hits ? ($dom_votes > 0 ? 'match' : 'partial_match')
                          : ($dom_votes > 0 ? 'weak_match' : 'no_match');
        push @grades, [ $id, $grade, scalar(@hits), [sort @hits] ];
    }
    return \@grades;
}

sub _tb_key {                                   # deterministic tiebreak key
    my ($e) = @_;
    my $deps = scalar @{ $e->{dep_mand} } + scalar @{ $e->{dep_opt} };
    return ( ($e->{priority} // 5) + 0, scalar @{ $e->{domains} }, $deps, $e->{id} );
}

sub stage6_minimum_set {
    my ($reg, $eligible, $grades, $primary, $secondary_classes, $max_sel, $req, $code_touching) = @_;
    my (@selected, %in, @alts);
    my $add = sub {
        my ($id, $reason, $grade) = @_;
        return 0 if $in{$id} || @selected >= $max_sel;
        push @selected, { id => $id, reason => $reason, match => $grade };
        $in{$id} = 1; return 1;
    };

    my @cores = @{ $CLASS_CORE{$primary} // [] };
    if ($primary eq 'mixed') {
        for my $c (@$secondary_classes) { push @cores, @{ $CLASS_CORE{$c} // [] }; }
        @cores = _uniq(@cores);
    }
    # skill 75 rule 3: pine-version-intelligence in EVERY set that touches code/APIs
    if ($code_touching && !grep { $_ eq 'pine-version-intelligence' } @cores) {
        push @cores, 'pine-version-intelligence';
    }
    for my $cid (@cores) {
        return ('blocked_missing_core', $cid, [], 0, [])
            unless $eligible->{$cid};
        $add->($cid, "class core ($primary) per skill-routing rule 2/3", 'match');
    }

    my %seen_sig;
    my @matched = sort { join("\x1f", _tb_key($reg->{map}{ $a->[0] })) cmp join("\x1f", _tb_key($reg->{map}{ $b->[0] })) }
                  grep { $_->[1] eq 'match' && !$in{ $_->[0] } } @$grades;
    for my $g (@matched) {
        last if @selected >= $max_sel;
        my $sig = join("\x1f", @{ $g->[3] });
        if ($sig ne '' && $seen_sig{$sig}) {
            push @alts, { id => $g->[0],
                          reason => "alternative: same matched-trigger capability already covered by $seen_sig{$sig} "
                                  . "(tie-break: priority > domain-breadth > dep-count > id) — NO merge performed" };
            next;
        }
        $seen_sig{$sig} = $g->[0] if $sig ne '';
        $add->($g->[0], "trigger hit: " . join('; ', @{ $g->[3] }), 'match');
    }
    my %alt = map { $_->{id} => 1 } @alts;
    my $overflow = (grep { $_->[1] eq 'match' && !$in{ $_->[0] } && !$alt{ $_->[0] } } @$grades) ? 1 : 0;
    return ('', '', \@selected, $overflow, \@alts);
}

sub stage7_dependencies {
    my ($reg, $selected_ids, $depth_cap) = @_;
    my @deps; my %seen; my @path;
    my $fail;
    my $walk;
    $walk = sub {
        my ($id, $req_by, $depth) = @_;
        return if $fail;
        if ($depth > $depth_cap) {
            $fail = { mode => 'depth_exceeded',
                      detail => "dependency chain deeper than depth_cap=$depth_cap at $id (path: " . join('->', @path, $id) . ')' };
            return;
        }
        push @path, $id;
        if (grep { $_ eq $id } @path[0 .. $#path - 1]) {
            $fail = { mode => 'circular', detail => 'cycle path: ' . join('->', @path) };
            pop @path; return;
        }
        for my $dep (@{ $reg->{map}{$id}{dep_mand} }) {
            if (!$reg->{map}{$dep}) {
                $fail = { mode => 'missing', detail => "mandatory dependency id '$dep' (required by $id) not in registry" };
                pop @path; return;
            }
            if ($reg->{map}{$dep}{status} ne 'normalized' || $reg->{map}{$dep}{activation} ne 'eligible') {
                $fail = { mode => 'missing', detail => "mandatory dependency '$dep' (required by $id) is not activation-eligible" };
                pop @path; return;
            }
            if (!$seen{$dep}) {
                $seen{$dep} = 1;
                push @deps, { id => $dep, required_by => $req_by };
            }
            $walk->($dep, $dep, $depth + 1);
            return if $fail;
        }
        pop @path;
    };
    for my $id (@$selected_ids) { $walk->($id, $id, 0); last if $fail; }
    return (\@deps, $fail);
}

sub stage8_redundancy {
    my ($reg, $grades, $selected, $overlaps, $max_sel) = @_;
    my @notes; my @excluded;
    my @out = @$selected;
    my %sel = map { $_->{id} => 1 } @out;
    my %grade_of = map { $_->[0] => $_->[1] } @$grades;

    for my $key (sort keys %$overlaps) {
        my $o = $overlaps->{$key};
        my ($a, $b) = ($o->{a}, $o->{b});
        my $rel = $o->{relationship};
        my ($in_a, $in_b) = ($sel{$a} ? 1 : 0, $sel{$b} ? 1 : 0);
        next unless $in_a || $in_b;
        next if $in_a && $in_b && $rel eq 'unrelated';

        if ($in_a && $in_b) {
            if ($rel eq 'complementary') {
                push @notes, "[$a + $b] complementary (Import Mode record): retain_both per selection_rules.redundancy_rules";
                next;
            }
            if ($rel eq 'related_but_distinct' || $rel eq 'partial_overlap' || $rel eq 'exact_duplicate') {
                my @s = sort { join("\x1f", _tb_key($reg->{map}{$a})) cmp join("\x1f", _tb_key($reg->{map}{$b})) } ($a, $b);
                my ($keep, $drop) = ($s[0], $s[1]);
                @out = grep { $_->{id} ne $drop } @out;
                delete $sel{$drop};
                push @notes, "[$a + $b] $rel (Import Mode record): kept $keep, excluded $drop "
                           . "(capability the request needs; NO merge performed)";
                push @excluded, { id => $drop, reason => "redundancy: $rel with $keep; capability unnecessary for complete coverage (NO merge)" };
            }
            next;
        }

        # exactly one endpoint selected: record the decision for the considered partner
        my ($kept, $partner) = $in_a ? ($a, $b) : ($b, $a);
        my $pg = $grade_of{$partner} // 'no_match';
        next if $pg eq 'no_match';                                # irrelevant partner: nothing to record
        if ($rel eq 'complementary') {
            push @notes, "[$a + $b] complementary (Import Mode record): selected subset covers the request; "
                       . "$partner ($pg) not required — retain_both applies when both capabilities are needed; NO merge";
        } else {
            push @notes, "[$a + $b] $rel (Import Mode record): kept $kept (capability the request needs); "
                       . "$partner ($pg) excluded — not required for complete coverage; NO merge performed";
            push @excluded, { id => $partner, reason => "redundancy: $rel with $kept; the request needs ${kept}'s capability (NO merge)" };
        }
    }
    @out = @out[0 .. _min($#out, $max_sel - 1)] if @out > $max_sel;
    return (\@out, \@notes, \@excluded);
}

sub _skill_tokens {
    my ($reg) = @_;
    my %t;
    for my $id (keys %{ $reg->{map} }) {
        my $e = $reg->{map}{$id};
        $t{$id} = 1800 + 90 * (scalar @{ $e->{tr_eng} } + scalar @{ $e->{tr_fa} });
    }
    return \%t;
}

sub stage10_context {
    my ($selected, $deps, $skill_tokens) = @_;
    my $tokens = 400;
    $tokens += $skill_tokens->{$_} // 1800 for (@$selected, map { $_->{id} } @$deps);
    my $level = $tokens <= 6000 ? 'S' : $tokens <= 15000 ? 'M' : $tokens <= 30000 ? 'L' : 'XL';
    return ($level, $tokens);
}

sub _unmatched_terms {
    my ($req) = @_;
    my %sw = map { $_ => 1 } @STOPWORDS;
    my @words = grep { !$sw{$_} } map { my $w = lc $_; $w =~ s/[^a-z0-9\x{0600}-\x{06FF}_-]//g; $w } split /\s+/, $req;
    @words = grep { length > 2 } @words;
    my @u = _uniq(@words);
    return @u[0 .. _min($#u, 7)];
}

# ===========================================================================
# route_request — orchestrates stages 1..14, returns the routing/2 contract
# ===========================================================================
sub route_request {
    my (%opt) = @_;
    my $req_raw  = $opt{request};
    my $reg      = $opt{registry};
    my $cfg      = $opt{config};
    my $overlaps = $opt{overlaps} // {};

    my $max_sel   = 0 + _cget($cfg, 'routing.selection_rules.hard_caps.max_selected_skills', 5);
    my $depth_cap = 0 + _cget($cfg, 'routing.dependency_rules.resolution.depth_cap', 3);
    my $class_order = _cget($cfg, 'routing.classification_rules.request_classes', '');
    my @class_order = grep { $_ ne 'mixed' && length } @{ _parse_flow_list("[$class_order]") } if $class_order;
    @class_order = qw(conceptual analytical debugging mathematical indicator_design
                      strategy_logic Pine_Script_implementation MTF performance
                      visualization verification research architecture)
        unless @class_order;
    my $fuzzy = _cget($cfg, 'routing.matching_rules.trigger_fidelity.fuzzy_matching', 'false');
    die "$ROUTER_ID: config requires fuzzy_matching: false (trigger fidelity)\n" unless $fuzzy eq 'false';

    my %eligible;
    my $vis_status = _cget($cfg, 'routing.matching_rules.candidate_visibility.status', 'normalized');
    my $vis_act    = _cget($cfg, 'routing.matching_rules.candidate_visibility.activation', 'eligible');
    my $vis_prefix = _cget($cfg, 'routing.matching_rules.candidate_visibility.path_prefix', 'skills/normalized/');
    for my $id (@{ $reg->{order} }) {
        my $e = $reg->{map}{$id};
        $eligible{$id} = ($e->{status} eq $vis_status && $e->{activation} eq $vis_act
                          && index(($e->{path} // ''), $vis_prefix) == 0) ? 1 : 0;
    }

    my $contract = {
        contract_version => $CONTRACT_VERSION, routing_status => '', request_class => '',
        primary_domain => '', secondary_domains => [], operational_intent => '',
        selected_skills => [], dependency_skills => [], excluded_skills => [],
        coverage => { required_capabilities => [], covered_capabilities => [], missing_capabilities => [] },
        conflicts => [], ambiguity => [], reason => '', estimated_context_size => '',
        routing_trace => { classification => '', matching => '', minimal_set_reasoning => '',
                           dependency_resolution => '', redundancy_analysis => '' },
        downstream => { next_stage => 'FORMALIZATION', allowed => 0 },
    };
    my $set_trace = sub {
        my (%kv) = @_;
        $contract->{routing_trace}{$_} = $kv{$_} for keys %kv;
    };
    my $fill_excluded = sub {
        my ($grades, $selected, $votes) = @_;
        my %sel = map { $_->{id} => 1 } @{ $contract->{selected_skills} }, @$selected;
        my %ids = map { $_->{id} => 1 } @{ $contract->{excluded_skills} };
        for my $g (@$grades) {
            next if $sel{ $g->[0] } || $ids{ $g->[0] };
            my $why = $g->[1] eq 'weak_match' ? 'weak_match — never selected alone (trigger fidelity)'
                    : $g->[1] eq 'no_match'   ? 'no_match — irrelevant'
                    :                           "$g->[1] — not required for complete coverage";
            push @{ $contract->{excluded_skills} }, { id => $g->[0], reason => $why };
            $ids{ $g->[0] } = 1;
        }
        $contract->{coverage}{required_capabilities} = [ map { $_->{id} } @{ $contract->{selected_skills} } ]
            unless @{ $contract->{coverage}{required_capabilities} };
        $contract->{coverage}{covered_capabilities} = [ sort keys %sel ]
            unless @{ $contract->{coverage}{covered_capabilities} };
    };
    my $finish_fields = sub {
        my ($reg, $selected, $deps) = @_;
        my $tok = _skill_tokens($reg);
        my ($level, $tokens) = stage10_context($selected, $deps, $tok);
        $contract->{estimated_context_size} = sprintf('%s + ~%.1fk tokens', $level, $tokens / 1000);
        if ($level eq 'XL') {
            $contract->{routing_trace}{minimal_set_reasoning} .=
                ' XL footprint requires written justification: selection already minimal for coverage; reduce scope before handoff';
        }
        $contract->{selected_skills} = [@$selected] if @$selected;
        $contract->{dependency_skills} = [@$deps] if @$deps && !@{ $contract->{dependency_skills} };
        $contract->{routing_trace}{minimal_set_reasoning} =
            'core(' . $contract->{request_class} . ') + trigger-matched topics; caps enforced '
            . "(max_selected_skills=$max_sel); tie-breaks: priority > domain-breadth > dep-count > id lexicographic; no merges"
            unless $contract->{routing_trace}{minimal_set_reasoning};
        # handoff gate: ONLY routing_status == ready may proceed to Formalization (spec §12)
        $contract->{downstream}{allowed} = ($contract->{routing_status} eq 'ready') ? 1 : 0;
    };

    # --- Stage 0: empty-registry controlled failure (TEST-ROUTING-001) -------
    unless (@{ $reg->{order} }) {
        $contract->{routing_status} = 'blocked';
        $contract->{reason} = 'registry.yaml contains no Skills (skills: []) — controlled failure; nothing loaded; '
                            . 'import Skills or explicitly consent to proceed skill-less';
        $contract->{ambiguity} = ['registry is empty: import Skills into skills/normalized/ or explicitly consent to proceed skill-less'];
        $contract->{routing_trace}{$_} = 'not reached (empty registry)'
            for qw(classification matching minimal_set_reasoning dependency_resolution redundancy_analysis);
        $contract->{routing_trace}{minimal_set_reasoning} = 'no-fallback policy: never bulk-load, never synthesize Skills';
        return $contract;
    }

    # --- Stage 1: normalization ----------------------------------------------
    my $req = stage1_normalize($req_raw);

    # --- Stages 2-3: classification -------------------------------------------
    my ($primary, $secondary_classes, $mhits) = stage23_classify($req, \@class_order);
    $contract->{request_class} = $primary;
    $contract->{operational_intent} = "Routed as '$primary' request"
        . (@$secondary_classes ? ' (secondary: ' . join(', ', @$secondary_classes) . ')' : '')
        . '; select the minimum sufficient Skill set from the Registry.';
    $contract->{routing_trace}{classification} =
        'markers fired: ' . join(', ', map { "$_=" . ($mhits->{$_} // 0) } grep { ($mhits->{$_} // 0) > 0 } sort keys %$mhits)
        . "; primary=$primary" . (@$secondary_classes ? '; secondary=' . join('/', @$secondary_classes) : '');

    # --- Ambiguity gate (TEST-ROUTING-007 fixture b) ---------------------------
    my @ambig;
    if ($req =~ $AMBIG_RSI_PAIR && $req !~ $AMBIG_NO_CONTEXT) {
        push @ambig, 'two parameterized RSI readings are compared (RSI1/RSI3 ambiguity class) but the request declares no lengths/periods';
        push @ambig, 'timeframe context not declared (chart TF vs calculation TF)';
        push @ambig, 'symbol context not declared (same symbol vs cross-symbol comparison)';
    }
    if (@ambig) {
        $contract->{routing_status} = 'ambiguous';
        $contract->{ambiguity} = \@ambig;
        $contract->{reason} = 'request is underdetermined (' . scalar(@ambig)
            . ' missing information items) — the Router does not guess; resolve and re-submit';
        $contract->{routing_trace}{$_} = 'skipped: ambiguous request (selection must not guess)'
            for qw(minimal_set_reasoning dependency_resolution redundancy_analysis);
        $contract->{routing_trace}{matching} = 'skipped: ambiguous request';
        return $contract;
    }

    # --- Stage 9 (request-level pre-gate): semantic conflict, no tolerance -----
    if ($req =~ $CONFLICT_INTRABAR && $req =~ $CONFLICT_CONFIRMED) {
        push @{ $contract->{conflicts} },
            'the request demands opposing confirmation discipline for the same signal — intrabar/live updates vs '
          . 'close-confirmed evaluation — with no declared tolerance; the Router flags conflicts, it never resolves them';
        $contract->{routing_status} = 'conflict_detected';
        $contract->{reason} = 'selected semantics are internally incompatible (opposing confirmation semantics) — '
                            . 'resolve the conflict in a new request before routing';
        $contract->{routing_trace}{matching} = 'conflict gate fired before selection (request-level stage-9 pre-gate)';
        $contract->{routing_trace}{minimal_set_reasoning} = 'skipped: conflict_detected — no selection authorized';
        $contract->{routing_trace}{dependency_resolution} = 'not reached (conflict_detected)';
        $contract->{routing_trace}{redundancy_analysis} = 'not reached (conflict_detected)';
        return $contract;
    }

    # --- Stages 4-5: domains, matching -----------------------------------------
    my ($primary_domain, $secondary_domains) = stage4_domains($req, $reg, \%eligible, $primary);
    $contract->{primary_domain} = $primary_domain;
    $contract->{secondary_domains} = [@$secondary_domains];
    my $votes = _domain_votes($req, $reg, \%eligible);
    my $grades = grade_candidates($req, $reg, \%eligible, $votes);
    my @match_or_partial = grep { $_->[1] eq 'match' || $_->[1] eq 'partial_match' } @$grades;
    my $code_touching = ($req =~ $CODE_TOUCHING) ? 1 : 0;

    # --- Stage 6: minimal set ----------------------------------------------------
    my ($sel_res, $sel_extra, $selected, $overflow, $alts) =
        stage6_minimum_set($reg, \%eligible, $grades, $primary, $secondary_classes, $max_sel, $req, $code_touching);
    if ($sel_res eq 'blocked_missing_core') {
        $contract->{routing_status} = 'blocked';
        $contract->{reason} = "class core skill '$sel_extra' is missing or not activation-eligible — controlled failure (skill 75 rule 3 gate)";
        $contract->{coverage}{missing_capabilities} = ["class-core capability: $sel_extra"];
        $contract->{routing_trace}{matching} = "core gate failed on $sel_extra";
        $contract->{routing_trace}{minimal_set_reasoning} = 'selection blocked by missing class-core skill';
        $contract->{routing_trace}{dependency_resolution} = 'not reached (blocked_missing_core)';
        $contract->{routing_trace}{redundancy_analysis} = 'not reached (blocked_missing_core)';
        return $contract;
    }
    if (!@match_or_partial && !@$selected) {
        # v0.1 no-trigger-match preserved: controlled failure (TEST-ROUTING-004 tail)
        my @terms = _unmatched_terms($req);
        $contract->{routing_status} = 'blocked';
        $contract->{reason} = 'no registered trigger matched the request and no class-core set applies — controlled failure; '
                            . 'search not broadened, no unrelated Skills loaded';
        $contract->{coverage}{missing_capabilities} = \@terms;
        $contract->{routing_trace}{matching} = 'zero match/partial candidates; unmatched request terms recorded; '
                                             . 'weak/no-match grades kept out of selection (trigger fidelity)';
        $contract->{routing_trace}{minimal_set_reasoning} = 'nothing selected — no sufficient set exists for this request';
        $contract->{routing_trace}{dependency_resolution} = 'not reached (no candidates)';
        $contract->{routing_trace}{redundancy_analysis} = 'not reached (no candidates)';
        $fill_excluded->($grades, [], $votes);
        return $contract;
    }
    $contract->{routing_trace}{matching} =
        'candidates graded: ' . scalar(@$grades) . ' eligible; '
        . join(', ', map { $_->[0] . '=' . $_->[1] } grep { $_->[1] ne 'no_match' } @$grades)
        . (@$alts ? '; identical-capability alternatives resolved by tie-break (no merge)' : '');

    # --- Stage 7: dependency resolution ------------------------------------------
    my ($deps, $fail) = stage7_dependencies($reg, [ map { $_->{id} } @$selected ], $depth_cap);
    $contract->{routing_trace}{dependency_resolution} = $fail
        ? "FAILED: $fail->{mode} — $fail->{detail}"
        : ( @$deps
            ? 'mandatory dependency closure: ' . join(', ', map { "$_->{id} (required_by $_->{required_by})" } @$deps)
            : 'no mandatory dependencies in selected set; closure trivially complete (registry has no mandatory edges)' );
    if ($fail) {
        $contract->{routing_status} = 'blocked';
        $contract->{reason} = "dependency resolution failed ($fail->{mode}): $fail->{detail}";
        $fill_excluded->($grades, $selected, $votes);
        $finish_fields->($reg, $selected, []);
        return $contract;
    }

    # --- Stage 8: redundancy elimination -------------------------------------------
    my ($sel2, $rnotes, $rexcl) = stage8_redundancy($reg, $grades, $selected, $overlaps, $max_sel);
    $selected = $sel2;
    push @{ $contract->{excluded_skills} }, @$rexcl;
    my @all_notes = (@$alts ? (map { "[alternative] $_->{reason}" } @$alts) : (), @$rnotes);
    $contract->{routing_trace}{redundancy_analysis} = @all_notes
        ? join('; ', @all_notes)
        : 'no overlap decision applied; no removals; no merges performed';

    # --- Cap overflow with distinct capabilities => insufficient_coverage ---------
    if ($overflow) {
        $contract->{routing_status} = 'insufficient_coverage';
        $contract->{reason} = "required coverage needs more than max_selected_skills=$max_sel (hard cap, config/routing.yaml) — "
                            . 'reduce scope or split the request; never a silent cap violation';
        $contract->{coverage}{missing_capabilities} = [ map { "coverage by " . $_->[0] }
            grep { my $gid = $_->[0]; $_->[1] eq 'match' && !grep { $_->{id} eq $gid } @$selected } @$grades ];
        my %s = map { $_->{id} => 1 } @$selected;
        $contract->{coverage}{covered_capabilities} = [ sort keys %s ];
        $contract->{routing_trace}{minimal_set_reasoning} = 'cap reached with distinct-capability matches remaining; '
            . 'status downgraded to insufficient_coverage per selection_rules (never a silent cap violation)';
        $fill_excluded->($grades, $selected, $votes);
        $finish_fields->($reg, $selected, $deps);
        return $contract;
    }

    # --- Stages 10-12: context, decision -------------------------------------------
    $contract->{routing_status} = 'ready';
    $contract->{reason} = 'minimum sufficient set of ' . scalar(@$selected)
        . " skill(s) covers the '$primary' request with dependency closure complete; no conflicts, no ambiguity, "
        . 'no coverage gaps; handoff to Formalization permitted';
    $fill_excluded->($grades, $selected, $votes);
    $finish_fields->($reg, $selected, $deps);
    return $contract;
}

sub _domain_votes {
    my ($req, $reg, $eligible) = @_;
    my %votes;
    for my $id (@{ $reg->{order} }) {
        next unless $eligible->{$id};
        my $e = $reg->{map}{$id};
        my $h = 0;
        $h += _trigger_hit($req, $_) for @{ $e->{tr_eng} }, @{ $e->{tr_fa} };
        next unless $h;
        $votes{$_} = ($votes{$_} // 0) + $h for @{ $e->{domains} };
    }
    return \%votes;
}

# ===========================================================================
# Output emitters
# ===========================================================================
sub _emit_skill_rows {
    my ($rows, $keys) = @_;
    return "    []\n" unless @$rows;
    my $o = '';
    for my $r (@$rows) {
        $o .= '    - { ' . join(', ', map { "$_: " . _q($r->{$_}) } @$keys) . " }\n";
    }
    return $o;
}

sub contract_to_yaml_v2 {
    my ($c) = @_;
    my $o = "routing:\n";
    $o .= "  contract_version: " . _q($c->{contract_version}) . "\n";
    $o .= "  routing_status: " . _q($c->{routing_status}) . "\n";
    $o .= "  request_class: " . _q($c->{request_class}) . "\n";
    $o .= "  primary_domain: " . _q($c->{primary_domain}) . "\n";
    $o .= "  secondary_domains: [" . join(', ', map { _q($_) } @{ $c->{secondary_domains} }) . "]\n";
    $o .= "  operational_intent: " . _q($c->{operational_intent}) . "\n";
    $o .= "  selected_skills:\n"    . _emit_skill_rows($c->{selected_skills},    [qw(id reason match)]);
    $o .= "  dependency_skills:\n"  . _emit_skill_rows($c->{dependency_skills},  [qw(id required_by)]);
    $o .= "  excluded_skills:\n"    . _emit_skill_rows($c->{excluded_skills},    [qw(id reason)]);
    $o .= "  coverage:\n";
    $o .= "    required_capabilities: [" . join(', ', map { _q($_) } @{ $c->{coverage}{required_capabilities} }) . "]\n";
    $o .= "    covered_capabilities: ["  . join(', ', map { _q($_) } @{ $c->{coverage}{covered_capabilities} }) . "]\n";
    $o .= "    missing_capabilities: ["  . join(', ', map { _q($_) } @{ $c->{coverage}{missing_capabilities} }) . "]\n";
    $o .= "  conflicts: [" . join(', ', map { _q($_) } @{ $c->{conflicts} }) . "]\n";
    $o .= "  ambiguity: [" . join(', ', map { _q($_) } @{ $c->{ambiguity} }) . "]\n";
    $o .= "  reason: " . _q($c->{reason}) . "\n";
    $o .= "  estimated_context_size: " . _q($c->{estimated_context_size}) . "\n";
    $o .= "  routing_trace:\n";
    $o .= "    classification: "        . _q($c->{routing_trace}{classification}) . "\n";
    $o .= "    matching: "              . _q($c->{routing_trace}{matching}) . "\n";
    $o .= "    minimal_set_reasoning: " . _q($c->{routing_trace}{minimal_set_reasoning}) . "\n";
    $o .= "    dependency_resolution: " . _q($c->{routing_trace}{dependency_resolution}) . "\n";
    $o .= "    redundancy_analysis: "   . _q($c->{routing_trace}{redundancy_analysis}) . "\n";
    $o .= "  downstream:\n    next_stage: FORMALIZATION\n    allowed: "
        . ($c->{downstream}{allowed} ? 'true' : 'false') . "\n";
    return $o;
}

sub contract_to_yaml_v1 {
    my ($c) = @_;
    my $status_v1 = $c->{routing_status} eq 'ready' ? 'routed' : 'blocked';
    my ($tokens) = $c->{estimated_context_size} =~ /~([\d.]+)k/;
    my $num = defined $tokens ? int($tokens * 1000) : 0;
    my $o = "routing:\n";
    $o .= "  status: " . _q($status_v1) . "\n";
    $o .= "  routing_status_v2: " . _q($c->{routing_status}) . "   # routing/2 extended value set\n";
    $o .= "  request_class: " . _q($c->{request_class}) . "\n";
    $o .= "  primary_domain: " . _q($c->{primary_domain}) . "\n";
    $o .= "  secondary_domains: [" . join(', ', map { _q($_) } @{ $c->{secondary_domains} }) . "]\n";
    $o .= "  operational_intent: " . _q($c->{operational_intent}) . "\n";
    $o .= "  selected_skills:\n"   . _emit_skill_rows($c->{selected_skills},   [qw(id reason match)]);
    $o .= "  dependency_skills:\n" . _emit_skill_rows($c->{dependency_skills}, [qw(id required_by)]);
    $o .= "  unresolved_triggers: [" . join(', ', map { _q($_) } @{ $c->{coverage}{missing_capabilities} }) . "]\n";
    $o .= "  excluded_skills: [" . join(', ', map { _q($_->{id}) } @{ $c->{excluded_skills} }) . "]\n";
    $o .= "  estimated_context_size: $num\n";
    $o .= "  reason: " . _q($c->{reason}) . "\n";
    $o .= "  downstream:\n    next_stage: FORMALIZATION\n    allowed: "
        . ($c->{downstream}{allowed} ? 'true' : 'false') . "\n";
    return $o;
}

sub contract_to_json {
    my ($c) = @_;
    my @parts;
    push @parts, _jq('contract_version') . ':' . _jq($c->{contract_version});
    push @parts, _jq('routing_status') . ':' . _jq($c->{routing_status});
    push @parts, _jq('request_class') . ':' . _jq($c->{request_class});
    push @parts, _jq('primary_domain') . ':' . _jq($c->{primary_domain});
    push @parts, _jq('secondary_domains') . ':[' . join(',', map { _jq($_) } @{ $c->{secondary_domains} }) . ']';
    push @parts, _jq('operational_intent') . ':' . _jq($c->{operational_intent});
    push @parts, _jq('selected_skills') . ':[' . join(',',
        map { '{' . _jq('id') . ':' . _jq($_->{id}) . ',' . _jq('reason') . ':' . _jq($_->{reason}) . ','
                   . _jq('match') . ':' . _jq($_->{match}) . '}' } @{ $c->{selected_skills} }) . ']';
    push @parts, _jq('dependency_skills') . ':[' . join(',',
        map { '{' . _jq('id') . ':' . _jq($_->{id}) . ',' . _jq('required_by') . ':' . _jq($_->{required_by}) . '}' }
        @{ $c->{dependency_skills} }) . ']';
    push @parts, _jq('excluded_skills') . ':[' . join(',',
        map { '{' . _jq('id') . ':' . _jq($_->{id}) . ',' . _jq('reason') . ':' . _jq($_->{reason}) . '}' }
        @{ $c->{excluded_skills} }) . ']';
    push @parts, _jq('coverage') . ':{' . _jq('required_capabilities') . ':['
        . join(',', map { _jq($_) } @{ $c->{coverage}{required_capabilities} }) . '],'
        . _jq('covered_capabilities') . ':[' . join(',', map { _jq($_) } @{ $c->{coverage}{covered_capabilities} }) . '],'
        . _jq('missing_capabilities') . ':[' . join(',', map { _jq($_) } @{ $c->{coverage}{missing_capabilities} }) . ']}';
    push @parts, _jq('conflicts') . ':[' . join(',', map { _jq($_) } @{ $c->{conflicts} }) . ']';
    push @parts, _jq('ambiguity') . ':[' . join(',', map { _jq($_) } @{ $c->{ambiguity} }) . ']';
    push @parts, _jq('reason') . ':' . _jq($c->{reason});
    push @parts, _jq('estimated_context_size') . ':' . _jq($c->{estimated_context_size});
    push @parts, _jq('routing_trace') . ':{' . join(',',
        map { _jq($_) . ':' . _jq($c->{routing_trace}{$_}) }
        qw(classification matching minimal_set_reasoning dependency_resolution redundancy_analysis)) . '}';
    push @parts, _jq('downstream') . ':{' . _jq('next_stage') . ':' . _jq('FORMALIZATION') . ','
        . _jq('allowed') . ':' . ($c->{downstream}{allowed} ? 'true' : 'false') . '}';
    return "{\n  " . join(",\n  ", @parts) . "\n}\n";
}

# ===========================================================================
# Selftest — TEST-ROUTING-001..008 (executable acceptance suite)
# ===========================================================================
my ($PASS, $FAIL, @FAILS);
sub _ok {
    my ($cond, $name, $detail) = @_;
    if ($cond) { $PASS++ }
    else {
        $FAIL++; $detail //= ''; $name //= '';
        my ($pkg, $file, $line) = caller(0);
        $name = "<unnamed at $file line $line>" if $name eq '';
        push @FAILS, "$name — $detail"; print "FAIL $name: $detail\n";
    }
}

# list-safe helpers (grep BLOCK LIST must never consume _ok's trailing args)
sub _has { my ($list, $id) = @_; return (grep { ($_->{id} // '') eq $id } @$list) ? 1 : 0; }
sub _has_bad_grade { my ($list) = @_; return grep { ($_->{match} // '') eq 'weak_match' || ($_->{match} // '') eq 'no_match' } @$list; }

sub _tmp_registry {
    my ($text) = @_;
    my ($fh, $name) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
    binmode $fh, ':encoding(UTF-8)';
    print $fh $text; close $fh;
    return $name;
}

sub run_selftest {
    my ($paths) = @_;
    $PASS = 0; $FAIL = 0; @FAILS = ();
    my $reg = parse_registry($paths->{registry});
    my $cfg = parse_routing_config($paths->{config});
    my $ovl = parse_overlaps($paths->{overlaps});

    my $run = sub {
        my (%o) = @_;
        my $r = $o{registry} ? parse_registry($o{registry}) : $reg;
        route_request( request => $o{request}, registry => $r, config => $cfg,
                       overlaps => $o{no_overlaps} ? {} : $ovl );
    };
    my $entry = sub {   # minimal registry entry text
        my (%f) = @_;
        "  - id: $f{id}\n    path: skills/normalized/x/$f{id}/skill.md\n"
        . "    domains: [" . ($f{domains} // 'd') . "]\n"
        . "    triggers:\n      english: [" . ($f{trig} // 'nothing') . "]\n"
        . "    dependencies:\n      mandatory: [" . ($f{mand} // '') . "]\n      optional: [" . ($f{opt} // '') . "]\n"
        . "    status: normalized\n    activation: eligible\n    priority: " . ($f{prio} // 1) . "\n";
    };

    # ---- TEST-ROUTING-001: empty registry ------------------------------------
    {
        my $empty = _tmp_registry("# test\nskills: []\n");
        my $c = $run->(registry => $empty, request => 'Build a supertrend indicator', no_overlaps => 1);
        _ok($c->{routing_status} eq 'blocked', '001.status-blocked', "got $c->{routing_status}");
        _ok(!@{ $c->{selected_skills} } && !@{ $c->{dependency_skills} } && !@{ $c->{excluded_skills} },
            '001.empty-lists', '');
        _ok($c->{reason} =~ /no Skills/, '001.reason-recorded', $c->{reason});
        _ok(!$c->{downstream}{allowed}, '001.no-handoff', '');
    }

    # ---- TEST-ROUTING-002: discovery + v1 compatibility -----------------------
    {
        my $c = $run->(request => 'deep backtesting validation', no_overlaps => 1);
        my $v1 = contract_to_yaml_v1($c);
        _ok($v1 =~ /status: 'routed'/, '002.v1-status-routed', (grep { /status/ } split /\n/, $v1)[0] // '');
        _ok(_has($c->{selected_skills}, 'backtesting-science'), '002.selected-hit', '');
        _ok(!@{ $c->{dependency_skills} }, '002.no-deps-real-registry', '');
        _ok(scalar @{ $c->{excluded_skills} } >= 70, '002.excluded-audit-trail', scalar @{ $c->{excluded_skills} });
        my ($num) = $v1 =~ /estimated_context_size: (\d+)/;
        _ok(defined $num && $num > 0, '002.v1-numeric-context', $num // 'undef');
    }

    # ---- TEST-ROUTING-003: determinism + contract shape -----------------------
    {
        my $c1 = $run->(request => 'Why does my supertrend signal flip intrabar?', no_overlaps => 1);
        my $c2 = $run->(request => 'Why does my supertrend signal flip intrabar?', no_overlaps => 1);
        _ok(contract_to_yaml_v2($c1) eq contract_to_yaml_v2($c2), '003.byte-identical', 'two runs differ');
        _ok($c1->{request_class} eq 'debugging', '003.class-debugging', $c1->{request_class});
        _ok($c1->{primary_domain} ne '', '003.domain-set', "primary_domain='$c1->{primary_domain}'");
        my %dom = map { $_ => 1 } map { @{ $reg->{map}{$_}{domains} } } keys %{ $reg->{map} };
        _ok($dom{ $c1->{primary_domain} }, '003.domain-in-registry', $c1->{primary_domain});
        _ok(scalar @{ $c1->{secondary_domains} } <= 3, '003.secondary-cap', scalar @{ $c1->{secondary_domains} });
        for my $f (qw(contract_version routing_status request_class primary_domain secondary_domains
                      operational_intent selected_skills dependency_skills excluded_skills coverage
                      conflicts ambiguity reason estimated_context_size routing_trace downstream)) {
            _ok(exists $c1->{$f}, "003.field-$f", 'missing');
        }
        for my $t (qw(classification matching minimal_set_reasoning dependency_resolution redundancy_analysis)) {
            _ok(length($c1->{routing_trace}{$t}), "003.trace-$t", 'empty');
        }
        _ok(($c1->{routing_status} eq 'ready') == ($c1->{downstream}{allowed} ? 1 : 0), '003.allowed-gate', '');
    }

    # ---- TEST-ROUTING-004: trigger fidelity — weak never selected -------------
    {
        # weak-match mechanics (synthetic): skillB shares the domain but has no trigger hit
        my $pair = "skills:\n" . $entry->(id => 'skA', domains => 'domQ', trig => 'quantam')
                              . $entry->(id => 'skB', domains => 'domQ', trig => 'unrelated-phrase');
        my $cw = $run->(registry => _tmp_registry($pair), request => 'quantam topic', no_overlaps => 1);
        my %selW = map { $_->{id} => 1 } @{ $cw->{selected_skills} };
        my %excW = map { $_->{id} => 1 } @{ $cw->{excluded_skills} };
        _ok($selW{'skA'} && $excW{'skB'}, '004.weak-mechanics', join(',', sort keys %selW));
        _ok((grep { $_->{id} eq 'skB' } @{ $cw->{excluded_skills} })[0]{reason} =~ /weak_match/,
            '004.weak-grade-recorded', (grep { $_->{id} eq 'skB' } @{ $cw->{excluded_skills} })[0]{reason} // '');

        # real-registry fixture: definitional question must not pull volume-analysis
        my $c = $run->(request => 'What does the volume percentile mean in my script?', no_overlaps => 1);
        my %sel = map { $_->{id} => 1 } @{ $c->{selected_skills} };
        my %exc = map { $_->{id} => 1 } @{ $c->{excluded_skills} };
        _ok($exc{'volume-analysis'} && !$sel{'volume-analysis'}, '004.weak-excluded', '');
        my $grades_ok = 1;
        for my $s (@{ $c->{selected_skills} }) { $grades_ok = 0 if $s->{match} !~ /^(match|partial_match)$/; }
        _ok($grades_ok, '004.grades-vocabulary', '');
        _ok(!_has_bad_grade($c->{selected_skills}),
            '004.no-weak-selected', '');

        # Persian triggers carry equal force (registered Persian trigger phrase)
        my $cf = $run->(request => 'حجم نسبی چیست', no_overlaps => 1);
        _ok(_has($cf->{selected_skills}, 'volume-analysis'),
            '004.persian-trigger-force', join(',', map { ref($_) ? $_->{id} : $_ } @{ $cf->{selected_skills} }));

        # no registered trigger at all -> controlled failure, no broadening
        my $cn = $run->(request => 'quantum flux capacitor resonance', no_overlaps => 1);
        _ok($cn->{routing_status} eq 'blocked', '004.no-match-blocked', $cn->{routing_status});
        _ok(scalar @{ $cn->{coverage}{missing_capabilities} } >= 1, '004.unmatched-recorded', '');
    }

    # ---- TEST-ROUTING-005: minimal sufficiency, caps, tie-breaks --------------
    {
        # Fixture A: related-but-unneeded skills stay unloaded (real registry)
        my $c = $run->(request => 'Build a volume-profile indicator', no_overlaps => 1);
        my %sel = map { $_->{id} => 1 } @{ $c->{selected_skills} };
        my %exc = map { $_->{id} => 1 } @{ $c->{excluded_skills} };
        _ok(scalar keys %sel <= 5, '005A.cap-respected', scalar keys %sel);
        _ok($exc{'technical-analysis-core'} && !$sel{'technical-analysis-core'}, '005A.related-unloaded', '');
        _ok($exc{'volume-analysis'} && !$sel{'volume-analysis'}, '005A.volume-related-unloaded', '');
        _ok($c->{routing_status} eq 'ready', '005A.ready', $c->{routing_status});

        # Fixture B: six DISTINCT-capability matches -> hard cap -> insufficient_coverage
        my $six = "skills:\n"
            . $entry->(id => 'sx1', domains => 'dx1', trig => 'alpha one')
            . $entry->(id => 'sx2', domains => 'dx2', trig => 'alpha two')
            . $entry->(id => 'sx3', domains => 'dx3', trig => 'alpha three')
            . $entry->(id => 'sx4', domains => 'dx4', trig => 'alpha four')
            . $entry->(id => 'sx5', domains => 'dx5', trig => 'alpha five')
            . $entry->(id => 'sx6', domains => 'dx6', trig => 'alpha six');
        my $c6 = $run->(registry => _tmp_registry($six), request => 'alpha one alpha two alpha three alpha four alpha five alpha six', no_overlaps => 1);
        _ok(scalar @{ $c6->{selected_skills} } <= 5, '005B.cap-respected', scalar @{ $c6->{selected_skills} });
        _ok($c6->{routing_status} eq 'insufficient_coverage', '005B.insufficient-on-cap', $c6->{routing_status});
        _ok(!$c6->{downstream}{allowed}, '005B.no-handoff', '');
        _ok($c6->{reason} =~ /max_selected_skills/, '005B.cap-named', $c6->{reason});

        # Fixture C: identical capability -> tie-break keeps lower dependency count
        my $pairc = "skills:\n"
            . $entry->(id => 'aa-few-deps', domains => 'domA', trig => 'betaboard')
            . $entry->(id => 'zz-many-deps', domains => 'domA', trig => 'betaboard', opt => 'p1, p2, p3')
            . $entry->(id => 'p1', domains => 'domP', prio => 9)
            . $entry->(id => 'p2', domains => 'domP', prio => 9)
            . $entry->(id => 'p3', domains => 'domP', prio => 9);
        my $cC = $run->(registry => _tmp_registry($pairc), request => 'betaboard', no_overlaps => 1);
        my %selC = map { $_->{id} => 1 } @{ $cC->{selected_skills} };
        my %excC = map { $_->{id} => 1 } @{ $cC->{excluded_skills} };
        _ok($selC{'aa-few-deps'} && $excC{'zz-many-deps'}, '005C.tiebreak-dep-count', join(',', sort keys %selC));
        _ok($cC->{routing_trace}{redundancy_analysis} =~ /alternative/, '005C.alternative-recorded',
            $cC->{routing_trace}{redundancy_analysis});
        my $cC2 = $run->(registry => _tmp_registry($pairc), request => 'betaboard', no_overlaps => 1);
        _ok(contract_to_yaml_v2($cC) eq contract_to_yaml_v2($cC2), '005C.deterministic', '');

        # optional dependencies are never auto-resolved
        _ok(!$selC{'p1'} && !$selC{'p2'} && !$selC{'p3'}, '005C.optional-not-auto', join(',', sort keys %selC));
    }

    # ---- TEST-ROUTING-006: dependency closure, cycles, missing, depth ---------
    {
        my $chain = "skills:\n"
            . $entry->(id => 'skA', domains => 'dA', trig => 'sigA', mand => 'skB')
            . $entry->(id => 'skB', domains => 'dB', mand => 'skC')
            . $entry->(id => 'skC', domains => 'dC');
        my $ca = $run->(registry => _tmp_registry($chain), request => 'sigA', no_overlaps => 1);
        _ok($ca->{routing_status} eq 'ready', '006a.chain-ready', $ca->{routing_status});
        my @depmap = map { "$_->{id}<-$$_{required_by}" } @{ $ca->{dependency_skills} };
        _ok(join('|', sort @depmap) eq 'skB<-skA|skC<-skB', '006a.provenance', join('|', @depmap));

        my $cycle = "skills:\n"
            . $entry->(id => 'skX', domains => 'dX', trig => 'sigX', mand => 'skY')
            . $entry->(id => 'skY', domains => 'dY', mand => 'skX');
        my $cb = $run->(registry => _tmp_registry($cycle), request => 'sigX', no_overlaps => 1);
        _ok($cb->{routing_status} eq 'blocked', '006b.cycle-blocked', $cb->{routing_status});
        _ok($cb->{routing_trace}{dependency_resolution} =~ /cycle path/, '006b.cycle-path-recorded',
            $cb->{routing_trace}{dependency_resolution});
        _ok(!$cb->{downstream}{allowed}, '006b.no-handoff', '');

        my $missing = "skills:\n"
            . $entry->(id => 'skS', domains => 'dS', trig => 'sigS', mand => 'ghost-id');
        my $cc = $run->(registry => _tmp_registry($missing), request => 'sigS', no_overlaps => 1);
        _ok($cc->{routing_status} eq 'blocked', '006c.missing-blocked', $cc->{routing_status});
        _ok($cc->{reason} =~ /ghost-id/, '006c.missing-named', $cc->{reason});

        my $deep = "skills:\n"
            . $entry->(id => 'skD1', domains => 'd1', trig => 'sigD', mand => 'skD2')
            . $entry->(id => 'skD2', domains => 'd2', mand => 'skD3')
            . $entry->(id => 'skD3', domains => 'd3', mand => 'skD4')
            . $entry->(id => 'skD4', domains => 'd4', mand => 'skD5')
            . $entry->(id => 'skD5', domains => 'd5');
        my $cd = $run->(registry => _tmp_registry($deep), request => 'sigD', no_overlaps => 1);
        _ok($cd->{routing_status} eq 'blocked' && $cd->{reason} =~ /depth/i, '006d.depth-blocked', $cd->{reason});

        # real registry: no mandatory edges anywhere -> closure always trivial
        my $real_dep_ok = 1;
        for my $id (@{ $reg->{order} }) { $real_dep_ok = 0 if @{ $reg->{map}{$id}{dep_mand} }; }
        _ok($real_dep_ok, '006.real-no-mandatory-edges', '');
    }

    # ---- TEST-ROUTING-007: status gating ---------------------------------------
    {
        my $ready = $run->(request => 'Build a volume-profile indicator', no_overlaps => 1);
        _ok($ready->{routing_status} eq 'ready' && $ready->{downstream}{allowed}
            && $ready->{downstream}{next_stage} eq 'FORMALIZATION', '007a.ready-handoff', $ready->{routing_status});

        my $amb = $run->(request => 'RSI1 > RSI3', no_overlaps => 1);
        _ok($amb->{routing_status} eq 'ambiguous', '007b.ambiguous', $amb->{routing_status});
        _ok(scalar @{ $amb->{ambiguity} } >= 2, '007b.itemized', scalar @{ $amb->{ambiguity} });
        _ok(!$amb->{downstream}{allowed}, '007b.no-handoff', '');

        # insufficient_coverage via the 005B fixture (distinct capabilities > cap)
        my $six = "skills:\n"
            . $entry->(id => 'sx1', domains => 'dx1', trig => 'alpha one')
            . $entry->(id => 'sx2', domains => 'dx2', trig => 'alpha two')
            . $entry->(id => 'sx3', domains => 'dx3', trig => 'alpha three')
            . $entry->(id => 'sx4', domains => 'dx4', trig => 'alpha four')
            . $entry->(id => 'sx5', domains => 'dx5', trig => 'alpha five')
            . $entry->(id => 'sx6', domains => 'dx6', trig => 'alpha six');
        my $c7c = $run->(registry => _tmp_registry($six), request => 'alpha one alpha two alpha three alpha four alpha five alpha six', no_overlaps => 1);
        _ok($c7c->{routing_status} eq 'insufficient_coverage' && !$c7c->{downstream}{allowed},
            '007c.insufficient-refused', $c7c->{routing_status});

        my $blk = $run->(registry => _tmp_registry("skills: []\n"), request => 'anything', no_overlaps => 1);
        _ok($blk->{routing_status} eq 'blocked' && !$blk->{downstream}{allowed}, '007d.blocked-refused', '');

        my $con = $run->(request => 'Emit the entry signal intrabar on every tick and require the higher timeframe close to be confirmed before exit', no_overlaps => 1);
        _ok($con->{routing_status} eq 'conflict_detected', '007e.conflict-detected', $con->{routing_status});
        _ok(scalar @{ $con->{conflicts} } >= 1, '007e.itemized', scalar @{ $con->{conflicts} });
        _ok(!$con->{downstream}{allowed}, '007e.no-handoff', '');
    }

    # ---- TEST-ROUTING-008: trace + redundancy from Import Mode record ----------
    {
        # Fixture A: related_but_distinct pair 09 (strategy-engine) / 51 (backtesting-science)
        my $a = $run->(request => 'deep backtesting validation');
        my %selA = map { $_->{id} => 1 } @{ $a->{selected_skills} };
        my %excA = map { $_->{id} => 1 } @{ $a->{excluded_skills} };
        _ok($selA{'backtesting-science'}, '008A.needed-member-selected', '');
        _ok($excA{'strategy-engine'}, '008A.pair-member-excluded', '');
        _ok($a->{routing_trace}{redundancy_analysis} =~ /related_but_distinct/, '008A.reason-recorded',
            $a->{routing_trace}{redundancy_analysis});

        # Fixture B: complementary pair 44 (quantitative-analysis) / 46 (signal-fusion)
        my $b = $run->(request => 'composite score with ensemble confluence and combine indicators signals');
        my %selB = map { $_->{id} => 1 } @{ $b->{selected_skills} };
        _ok($selB{'quantitative-analysis'} && $selB{'signal-fusion'}, '008B.complementary-retained',
            join(',', sort keys %selB));
        _ok($b->{routing_trace}{redundancy_analysis} =~ /complementary/, '008B.recorded',
            $b->{routing_trace}{redundancy_analysis});

        # Fixture C: five mandatory trace sections on any ready decision
        my $c = $run->(request => 'Build a volume-profile indicator', no_overlaps => 1);
        my @vals = values %{ $c->{routing_trace} };
        _ok((grep { length } @vals) == 5, '008C.trace-complete', scalar(grep { length } @vals));
    }

    print "\n";
    printf "SELFTEST: %d passed, %d failed\n", $PASS, $FAIL;
    if ($FAIL) { print "$_\n" for reverse @FAILS; return 1; }
    print "All TEST-ROUTING-001..008 acceptance cases pass (routing/2).\n";
    return 0;
}

# ===========================================================================
# Scenario runner — concrete registry-backed fixtures (tests/routing/scenarios)
# Fixtures live in scenarios.yaml; expectations assert only spec-derivable
# properties (status, class, Registry domains, membership, gating, trace).
# ===========================================================================
sub parse_scenarios {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file
        or die "$ROUTER_ID: cannot read scenarios '$file': $!\n";
    my (@scens, $cur, $in_expect, $key);
    while (my $line = <$fh>) {
        $line =~ s/\r?\n$//;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        if ($line =~ /^scenario_id:\s*(\S+)/) {
            push @scens, $cur if $cur;
            $cur = { id => $1, spec_refs => [], notes => '' };
            $in_expect = 0; $key = undef;
            next;
        }
        next unless $cur;
        if ($line =~ /^(request|title|notes):\s*(.*)$/) {
            $key = $1; $cur->{$key} = _trim($2);
            $cur->{$key} =~ s/^"|"$//g;
            $in_expect = 0;
            next;
        }
        if ($line =~ /^expect:\s*$/) { $in_expect = 1; $key = undef; next; }
        if ($line =~ /^(\s+)title:\s*(.*)$/ && $in_expect) { next; }   # continuation of a quoted string (unused)
        if ($in_expect) {
            if ($line =~ /^(\s+)([\w_]+):\s*(.*)$/) {
                my ($ind, $k, $v) = (length($1), $2, _trim($3));
                $key = $k;
                if ($v eq '') { $cur->{expect}{$k} = [] unless ref $cur->{expect}{$k}; next; }
                $v =~ s/^\[//; $v =~ s/\]$//;
                $v =~ s/^['"]|['"]$//g;
                if ($v =~ /^\d+$/) { $cur->{expect}{$k} = 0 + $v; }
                elsif ($k eq 'downstream_allowed') { $cur->{expect}{$k} = ($v eq 'true') ? 1 : 0; }
                elsif ($k =~ /_include|_exclude|trace_sections_present/) { $cur->{expect}{$k} = [ split /,\s*/, $v ]; }
                else { $cur->{expect}{$k} = $v; }
                next;
  }
            if ($line =~ /^\s+-\s*(.+)$/) {                            # block list item under last key
                my $item = _trim($1); $item =~ s/^['"]|['"]$//g;
                $cur->{expect}{$key} = [] unless ref $cur->{expect}{$key};
                push @{ $cur->{expect}{$key} }, $item;
                next;
            }
        }
        if (!$in_expect && $line =~ /^spec_refs:\s*\[(.*)\]/) {
            $cur->{spec_refs} = [ map { my $s = _trim($_); $s =~ s/^['"]|['"]$//g; $s } split /,/, $1 ];
            next;
        }
    }
    push @scens, $cur if $cur;
    close $fh;
    return \@scens;
}

sub run_scenarios {
    my ($paths, $scenario_file) = @_;
    binmode STDOUT, ':encoding(UTF-8)';
    my $reg  = parse_registry($paths->{registry});
    my $cfg  = parse_routing_config($paths->{config});
    my $ovl  = parse_overlaps($paths->{overlaps});
    my $scens = parse_scenarios($scenario_file);
    die "$ROUTER_ID: no scenarios parsed from '$scenario_file'\n" unless @$scens;

    my ($P, $F, $Fails) = (0, 0, []);
    my $chk = sub {
        my ($cond, $sid, $what, $detail) = @_;
        if ($cond) { $P++ }
        else { $F++; push @$Fails, "[$sid] $what — $detail"; print "  FAIL [$sid] $what: $detail\n"; }
    };

    for my $sc (@$scens) {
        my $sid = $sc->{id};
        print "scenario $sid: $sc->{title}\n";
        my $c = route_request( request => $sc->{request}, registry => $reg,
                               config => $cfg, overlaps => $ovl );
        my $e = $sc->{expect} // {};
        $chk->($c->{routing_status} eq ($e->{routing_status} // ''), $sid, 'routing_status',
               "got '$c->{routing_status}', want '$e->{routing_status}'") if exists $e->{routing_status};
        $chk->($c->{request_class} eq ($e->{request_class} // ''), $sid, 'request_class',
               "got '$c->{request_class}', want '$e->{request_class}'") if exists $e->{request_class};
        $chk->($c->{primary_domain} eq ($e->{primary_domain} // ''), $sid, 'primary_domain',
               "got '$c->{primary_domain}', want '$e->{primary_domain}'") if exists $e->{primary_domain};
        if ($e->{secondary_include}) {
            my %got = map { $_ => 1 } @{ $c->{secondary_domains} };
            for my $d (@{ $e->{secondary_include} }) {
                $chk->($got{$d}, $sid, "secondary_include:$d", 'not in ' . join(',', @{ $c->{secondary_domains} }));
            }
        }
        if ($e->{selected_include}) {
            my %got = map { $_ => 1 } map { $_->{id} } @{ $c->{selected_skills} };
            for my $id (@{ $e->{selected_include} }) {
                $chk->($got{$id}, $sid, "selected_include:$id", 'not selected; got: ' . join(',', sort keys %got));
            }
        }
        if ($e->{selected_exclude}) {
            my %got = map { $_ => 1 } map { $_->{id} } @{ $c->{selected_skills} }
                if @{ $c->{selected_skills} };
            my %g = map { $_->{id} => 1 } @{ $c->{selected_skills} };
            for my $id (@{ $e->{selected_exclude} }) {
                $chk->(!$g{$id}, $sid, "selected_exclude:$id", 'unexpectedly selected');
  }
        }
        if ($e->{excluded_include}) {
            my %g = map { $_->{id} => 1 } @{ $c->{excluded_skills} };
            for my $id (@{ $e->{excluded_include} }){
                $chk->($g{$id}, $sid, "excluded_include:$id", 'not in excluded_skills');
            }
        }
        if (defined $e->{downstream_allowed}) {
            $chk->(($c->{downstream}{allowed} ? 1 : 0) == $e->{downstream_allowed}, $sid, 'downstream_allowed',
                   "got $c->{downstream}{allowed}");
        }
        if (defined $e->{missing_capabilities_min_count}) {
            $chk->(scalar @{ $c->{coverage}{missing_capabilities} } >= $e->{missing_capabilities_min_count},
                   $sid, 'missing_capabilities_min_count',
                   'got ' . scalar @{ $c->{coverage}{missing_capabilities} });
        }
        if (defined $e->{ambiguity_min_count}) {
            my $got_amb = scalar @{ $c->{ambiguity} };
            $chk->($got_amb >= $e->{ambiguity_min_count}, $sid, 'ambiguity_min_count', "got $got_amb");
        }
        if ($e->{redundancy_note_contains}) {
            $chk->(index($c->{routing_trace}{redundancy_analysis}, $e->{redundancy_note_contains}) >= 0,
                   $sid, 'redundancy_note_contains', $c->{routing_trace}{redundancy_analysis});
        }
        if ($e->{trace_sections_present}) {
            for my $t (@{ $e->{trace_sections_present} }) {
                $chk->(length($c->{routing_trace}{$t}), $sid, "trace:$t", 'empty');
            }
        }
    }
    print "\n";
    printf "SCENARIOS: %d assertions passed, %d failed across %d scenarios\n", $P, $F, scalar @$scens;
    if ($F) { print "$_\n" for reverse @$Fails; return 1; }
    print "All routing scenario fixtures pass (routing/2, real 77-skill registry).\n";
    return 0;
}

# ===========================================================================
# CLI
# ===========================================================================
sub main {
    my @argv = map { _u($_) } @ARGV;
    my (%opt, $selftest, $scenarios);
    while (@argv) {
        my $a = shift @argv;
        if    ($a eq '--request')  { $opt{request}  = shift @argv }
        elsif ($a eq '--format')   { $opt{format}   = shift @argv }
        elsif ($a eq '--registry') { $opt{registry} = shift @argv }
        elsif ($a eq '--config')   { $opt{config}   = shift @argv }
        elsif ($a eq '--overlaps') { $opt{overlaps} = shift @argv }
        elsif ($a eq '--out')      { $opt{out}      = shift @argv }
        elsif ($a eq '--selftest')  { $selftest = 1 }
        elsif ($a eq '--scenarios') { $scenarios = shift @argv }
        else { die "$ROUTER_ID: unknown option '$a'\n"; }
    }
    my $root = $0; $root =~ s{[\\/][^\\/]+$}{};
    $root = '.' if $root eq $0;
    my $paths = {
        registry => $opt{registry} // "$root/../../skills/registry.yaml",
        config   => $opt{config}   // "$root/../../config/routing.yaml",
        overlaps => $opt{overlaps} // "$root/../../skills/import-reports/processing-index.yaml",
    };
    if ($selftest) { exit run_selftest($paths); }
    if ($scenarios) { exit run_scenarios($paths, $scenarios); }
    die "$ROUTER_ID: --request is required (or use --selftest)\n" unless defined $opt{request};
    my $reg = parse_registry($paths->{registry});
    my $cfg = parse_routing_config($paths->{config});
    my $ovl = parse_overlaps($paths->{overlaps});
    my $c = route_request(request => $opt{request}, registry => $reg, config => $cfg, overlaps => $ovl);
    my $fmt = $opt{format} // 'yaml';
    my $out = $fmt eq 'json' ? contract_to_json($c)
            : $fmt eq 'v1'   ? contract_to_yaml_v1($c)
            :                  contract_to_yaml_v2($c);
    $out = encode('UTF-8', $out);
    if ($opt{out}) {
        open my $fh, '>:raw', $opt{out} or die "cannot write '$opt{out}': $!";
        print $fh $out; close $fh;
    } else {
        binmode STDOUT, ':raw';
        print $out;
    }
    exit($c->{routing_status} eq 'ready' ? 0 : 2);   # 0 = handoff permitted; 2 = stop before Formalization
}

main() unless caller;
