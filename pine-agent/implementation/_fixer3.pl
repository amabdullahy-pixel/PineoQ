#!/usr/bin/perl
# Fix @version interpolation in implement.pl static_checks grep.
# Use \x40 for @ to avoid any interpolation issues.
use strict; use warnings;
my $f = $ARGV[0];
open my $fh, "<:raw", $f or die $!;
local $/; my $t = <$fh>; close $fh;

# Replace the grep line with one that escapes @version
my $bad = "my \$has_version = grep { m{^//@version=6} } \@lines;";
my $good = "my \$has_version = grep { m{^//\\\@version=6} } \@lines;";
$t =~ s/\Q$bad\E/$good/;

open my $o, ">:raw", $f or die $!;
print $o $t; close $o;
print "fixed\n";