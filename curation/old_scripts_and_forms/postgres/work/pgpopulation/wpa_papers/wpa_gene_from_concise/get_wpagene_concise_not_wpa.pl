#!/usr/bin/perl -w

# Look at evidence from concise description for Paper to Gene connections, then
# check which don't exist in the Paper editor's wpa_gene table.  2006 12 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %ident;
my $result = $conn->exec( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { 
  next unless ($row[1]);
  if ($row[3] eq 'valid') { $ident{$row[1]} = $row[0]; }
    else { delete $ident{$row[1]}; } }

my %concise;
$result = $conn->exec( "SELECT * FROM car_con_ref_reference ORDER BY car_timestamp;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $concise{$row[0]} = $row[1]; } }

my %con_gene;
foreach my $gene (sort keys %concise) {
  next unless ($concise{$gene});
  my $papers = $concise{$gene};
  my @papers;
  if ($papers =~ m/, /) { @papers = split/, /, $papers; }
    else { push @papers, $papers; }
  foreach my $paper (@papers) {
    $paper =~ s/^\s+//g; $paper =~ s/\s+$//g; $paper =~ s/,+$//g; $paper =~ s/\.+$//g; 
    if ($paper =~ m/WBPaper(\d+)/) { $con_gene{$1}{$gene}++; }
    elsif ($paper =~ m/^WB/) { next; }
    elsif ($paper =~ m/^Expr/) { next; }
    elsif ($ident{$paper}) { $con_gene{$ident{$paper}}{$gene}++; }
  } # foreach my $paper (@papers)
}

my %wpa_gene; my %filter;
$result = $conn->exec( "SELECT * FROM wpa_gene ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { 
  next unless ($row[1]);
  my $what = $row[1];
  if ($row[2]) { $what .= ' ' . $row[2]; }
  if ($row[3] eq 'valid') { $filter{$row[0]}{$what}++; }
    else { delete $filter{$row[0]}{$what}; } }
foreach my $pap (sort keys %filter) {
  foreach my $what (sort keys %{ $filter{$pap}}) {
    if ($what =~ m/(WBGene\d+)/) { my $gene = $1; $wpa_gene{$pap}{$gene}++; } } }

my $bad_pap = 0;
foreach my $pap (sort keys %con_gene) {
  my $bad_pap_flag = 0;
  foreach my $gene (sort keys %{ $con_gene{$pap} }) {
    next unless ($gene =~ m/WBGene/);
    unless ($wpa_gene{$pap}{$gene}) { $bad_pap_flag++; print "$pap $gene missing in Paper-Gene connections\n"; } }
  if ($bad_pap_flag) { $bad_pap++; }
}
print "There are $bad_pap bad papers\n"; 

