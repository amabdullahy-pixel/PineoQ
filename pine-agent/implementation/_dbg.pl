use strict; use warnings;
use Encode qw(encode decode);
use File::Temp;
my $dir = ($0 =~ /^(.+)[\\\/][^\\\/]+$/ ? $1 : '.');
$dir =~ s{\\}{/}g;
my $feas_pl = "$dir/../feasibility/feasibility.pl";

my $BASE_C = <<'EOC';
schema_version: "1.1"
stage: formalization
formalization:
  request_id: 'req-aaaaaaaaaaaa'
  approved_routing_id: 'rout-bbbbbbbbbbbb'
  formalization_id: 'form-cccccccccccc'
  natural_language_request: 'close crosses over 30 on bar close'
  formulas: []
  boolean_conditions:
    - { id: 'C-1', condition: 'close crosses over 30' }
  edge_cases:
    - { id: 'E-NA', case: 'na warm-up', required_behavior: null }
  timeframe:
    chart: '15m'
  mtf: false
  required_data: []
  repaint_risk: 'low'
  status: 'completed'
  blockers: []
  implementation_allowed: true
EOC

my $PRE = <<'EOP';
schema_version: "1.1"
stage: pre_verification
pre_verification:
  request_id: 'req-aaaaaaaaaaaa'
  approved_routing_id: 'rout-bbbbbbbbbbbb'
  formalization_id: 'form-cccccccccccc'
  verification_id: 'pre-111111111111'
  result: 'PASS'
  status: 'passed'
  implementation_allowed: true
  feasibility_allowed: true
  next_stage: FEASIBILITY
  checks: []
  findings: []
  blockers: []
  warnings: []
EOP

my ($fh1, $c1) = File::Temp::tempfile(SUFFIX => '.yaml');
binmode $fh1, ':raw'; print $fh1 encode('UTF-8', $BASE_C); close $fh1;
my ($fh2, $c2) = File::Temp::tempfile(SUFFIX => '.yaml');
binmode $fh2, ':raw'; print $fh2 encode('UTF-8', $PRE); close $fh2;
my ($fh3, $c3) = File::Temp::tempfile(SUFFIX => '.yaml'); close $fh3;
print "X=[$^X]\nfeas=[$feas_pl]\nc1=[$c1]\nc2=[$c2]\nc3=[$c3]\n";
my $rc = system($^X, $feas_pl, '--contract', $c1, '--pre', $c2, '--out', $c3);
print "list-rc=$rc\n";
if ($rc != 0) {
    print "--- trying string form ---\n";
    $rc = system("\"$^X\" \"$feas_pl\" --contract \"$c1\" --pre \"$c2\" --out \"$c3\" 2>\"$dir/_stderr.txt\"");
    print "str-rc=$rc\n";
    if (open my $e, '<', "$dir/_stderr.txt") { print "STDERR:\n"; print while (<$e>); close $e; }
    if (open my $o, '<:raw', $c3) { print "OUT:\n"; print while (<$o>); close $o; }
    else { print "no out file\n"; }
}
1 while unlink $c1; 1 while unlink $c2; 1 while unlink $c3; 1 while unlink "$dir/_stderr.txt";