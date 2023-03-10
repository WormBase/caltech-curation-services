#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;
my $result = $conn->exec( "SELECT * FROM wpa_gene ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $pap = $row[0];
    my $gene = $row[1];
    ($gene) = $gene =~ m/(WBGene\d+)/;
    if ($row[3] eq 'valid') { $hash{$gene}{$pap}++; }
      else { delete $hash{$gene}{$pap}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $gene_count = 0;
foreach my $gene (sort keys %hash) {
  my $count = 0;
  foreach my $pap (keys %{ $hash{$gene} }) {
    $count++;
  } # foreach my $pap (keys %{ $hash{$gene} })
  if ($count > 20) { $gene_count++; }
} # foreach my $gene (sort keys %hash)
print "There are $gene_count genes with more than 20 paper references each\n";

__END__

