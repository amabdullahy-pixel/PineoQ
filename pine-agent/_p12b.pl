#!/usr/bin/perl
use strict; use warnings;

my $f = 'data_acquisition/data_acquisition.pl';
open my $in, '<:raw', $f or die $!;
local $/;
my $t = <$in>;
close $in;

# ===========================================================================
# 1. parse_csv_dataset -> header-aware, records schema + timestamp convention
# ===========================================================================
my $old_parser = <<'OLD';
# ---------------------------------------------------------------------------
# CSV dataset parsing: ts,open,high,low,close,volume
#   raw fingerprint over raw bytes; parsed rows normalized deterministically
#   (chronological stable sort — original order preserved for DI03 verdict)
# ---------------------------------------------------------------------------
sub parse_csv_dataset {
    my ($raw) = @_;
    return undef unless defined $raw && length $raw;
    my @rows;
    my $line_no = 0;
    for my $line (split /\r?\n/, $raw) {
        $line_no++;
        next if $line =~ /^\s*$/;
        next if $line =~ /^#/;
        next if $line =~ /^\s*(ts|timestamp|time)\s*,/i;   # header
        my @c = split /,/, $line;
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
    return \@rows;
}
OLD

my $new_parser = <<'NEW';
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
            my @ordered = map { $names[$_] // '' } grep { defined $col{$_} } qw(ts open high low close volume);
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
NEW

die "parser block not found" unless index($t, $old_parser) >= 0;
$t =~ s/\Q$old_parser\E/$new_parser/;

open my $out, '>:raw', $f or die $!;
print {$out} $t;
close $out;
print "batch B1 (parser) applied\n";
