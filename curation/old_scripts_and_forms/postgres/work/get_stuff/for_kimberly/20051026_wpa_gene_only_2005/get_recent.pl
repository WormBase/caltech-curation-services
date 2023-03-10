#!/usr/bin/perl -w

# Looks at WBPapers with year = '2005', then looking at that subset for
# WBPaper - WBGene connections, then filtering out multiple paper-gene
# connections with the same paper and gene.  2005 10 26
 

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;
my $result = $conn->exec( "SELECT joinkey, wpa_gene FROM wpa_gene WHERE joinkey IN (SELECT joinkey FROM wpa_year WHERE wpa_year = '2005') ORDER BY wpa_gene;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[1]) { 
      if ($row[1] =~ m/(WBGene\d+)/) { $theHash{$row[0]}{$row[1]}++; } } } }
my $gene_count = scalar(keys %theHash);
my $total_count = 0;
foreach my $gene (sort keys %theHash) {
  foreach my $paper (sort keys %{ $theHash{$gene} }) { $total_count++; } }
print OUT "There are $gene_count wbgenes, with $total_count separate wbgene-wbpaper connections\n";


close (OUT) or die "Cannot close $outfile : $!";
