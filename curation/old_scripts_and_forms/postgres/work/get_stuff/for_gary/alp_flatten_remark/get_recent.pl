#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pap_w_remark;
my $result = $conn->exec( "SELECT * FROM alp_remark ;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $rem_has_paper = 0;
    my $result2 = $conn->exec( "SELECT * FROM alp_paper WHERE joinkey = '$row[0]' AND alp_box = '$row[1]' ;" );
    while (my @row2 = $result2->fetchrow) {
      $rem_has_paper++;
      my $pap = $row2[2]; ($pap) = $pap =~ m/(WBPaper\d+)/; $pap_w_remark{$pap}++; }
    unless ($rem_has_paper) { print "NO PAPER $row[0] box $row[1] has remark $row[2]\n"; }
} }

print "\n\n";

foreach my $pap (sort keys %pap_w_remark) {
  my $result = $conn->exec( "SELECT * FROM alp_paper WHERE alp_paper ~ '$pap' ORDER BY joinkey;" );
  while (my @row = $result->fetchrow) {
    print "$pap with $row[0] box $row[1] ";
    my $result2 = $conn->exec( "SELECT * FROM alp_remark WHERE joinkey = '$row[0]' AND alp_box = '$row[1]' ;" );
    while (my @row2 = $result2->fetchrow) { print "remark : $row2[2]"; }
    print "\n";
  } # while (my @row = $result->fetchrow)
} # foreach my $pap (sort keys %pap_w_remark)


__END__

