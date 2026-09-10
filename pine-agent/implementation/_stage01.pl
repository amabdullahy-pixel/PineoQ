#!/usr/bin/perl
# STAGE 01/02 helper: produce the authoritative Phase-8 Implementation Plan
# from the authentic upstream fixtures, then validate the hard input gate.
use strict; use warnings;
use Encode qw(encode decode);
use File::Temp;

my $D = "C:/Users/Kabir/OneDrive/Documents/PineScript.6/pine-agent";
my $impl = "$D/implementation/implementation_plan.pl";
my $feas  = "$D/feasibility/feasibility.pl";

sub slurp { my $f=shift; open my $fh,'<:raw',$f or die "$f: $!"; local $/; my $t=<$fh>; close $fh; return decode('UTF-8',$t); }
sub w { my ($f,$c)=@_; open my $fh,'>:raw',$f or die "$f: $!"; print $fh encode('UTF-8',$c); close $fh; }
sub run { my ($cmd)=@_; my $rc=system(@$cmd); return ($rc==-1)?-1:(($rc&127)?-1:($rc>>8)); }

my $BASE_C = slurp("$D/implementation/_t_c.yaml");
my $PRE    = slurp("$D/implementation/_t_p.yaml");

my ($fh1,$c1)=File::Temp::tempfile(SUFFIX=>'.yaml'); w($c1,$BASE_C);
my ($fh2,$c2)=File::Temp::tempfile(SUFFIX=>'.yaml'); w($c2,$PRE);
my ($fh3,$c3)=File::Temp::tempfile(SUFFIX=>'.yaml'); close $fh3;
run([$^X,$feas,'--contract',$c1,'--pre',$c2,'--out',$c3]);
my $F = slurp($c3);

my ($fh4,$p)=File::Temp::tempfile(SUFFIX=>'.yaml');
my $rc = run([$^X,$impl,'--contract',$c1,'--pre',$c2,'--feasibility',$c3,'--out',$p]);
print "PLAN_EXIT=$rc\n";
my $plan = slurp($p);
open my $o, '>:raw', "$D/implementation/phase9_authoritative_plan.yaml" or die $!;
print $o encode('UTF-8',$plan); close $o;
print "WROTE $D/implementation/phase9_authoritative_plan.yaml\n";

# extract key fields
for my $k (qw(planning_status planning_id implementation_allowed next_stage)) {
    my ($v) = $plan =~ /^\s{2}\Q$k\E:\s*(?:'([^']*)'|(\S+))/m;
    print "$k=" . (defined $v ? $v : 'NULL') . "\n";
}
1 while unlink $c1,$c2,$c3,$p;