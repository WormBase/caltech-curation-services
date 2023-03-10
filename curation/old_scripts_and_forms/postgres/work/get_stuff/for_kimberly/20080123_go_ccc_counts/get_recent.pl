#!/usr/bin/perl -w

# get count by curator and lastupdate (year) for cellular component go_curation
# data counting once for each paper in evidence with a term  2008 01 23

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;
my $result = $conn->exec( "SELECT * FROM got_cell_goid ORDER BY got_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[2]) { $hash{term}{$row[0]}{$row[1]}++; }
      else { delete $hash{term}{$row[0]}{$row[1]}; } } }
$result = $conn->exec( "SELECT * FROM got_cell_paper_evidence ORDER BY got_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[2]) { $hash{paper}{$row[0]}{$row[1]} = $row[2]; }
      else { delete $hash{paper}{$row[0]}{$row[1]}; } } }
$result = $conn->exec( "SELECT * FROM got_cell_curator_evidence ORDER BY got_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[2]) { $hash{curator}{$row[0]}{$row[1]} = $row[2]; }
      else { delete $hash{curator}{$row[0]}{$row[1]}; } } }
$result = $conn->exec( "SELECT * FROM got_cell_lastupdate ORDER BY got_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[2]) { 
        my ($time) = $row[2] =~ m/^(\d{4})/;
        $hash{time}{$row[0]}{$row[1]} = $time; }
      else { delete $hash{time}{$row[0]}{$row[1]}; } } }

my %curators;
foreach my $wbgene (sort keys %{ $hash{term} }) {
  foreach my $row (sort keys %{ $hash{term}{$wbgene} }) {
    my $curator = $hash{curator}{$wbgene}{$row};
    my $paper = $hash{paper}{$wbgene}{$row}; my $count = 0;
    if ($paper) { my @papers = split/,/, $paper; $count = scalar(@papers); }
    my $time = $hash{time}{$wbgene}{$row};
    $curators{$curator}{$time} += $count;
    $curators{all}{$time} += $count;
  } # foreach my $row (sort keys %{ $hash{term}{$wbgene} })
} # foreach my $wbgene (sort keys %{ $hash{term} })

foreach my $curator (sort keys %curators) {
  foreach my $time (sort keys %{ $curators{$curator} }) {
    my $count = $curators{$curator}{$time};
    print "$curator\t$time\t$count\n";
  } # foreach my $time (sort keys %{ $curators{$curator} })
} # foreach my $curator (sort keys %curators)

__END__

    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
