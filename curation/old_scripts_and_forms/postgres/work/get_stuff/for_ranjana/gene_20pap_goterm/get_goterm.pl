#!/usr/bin/perl

# Get a list of Genes with 20 or more papers from ws180 by doing :
# select all class gene where count (select ->Reference) > 20
# then find how many of those genes have a goterm attached in any of the three
# got_ goterm tables.  2007 09 10 

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %genes;
# my $infile = '20pap_genes';
my $infile = '5pap_genes';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/(WBGene\d+)/) { $genes{$1}++; }
}
close (IN) or die "Cannot close $infile : $!";

my %terms;
my @list = qw( bio cell mol );

foreach my $type (@list) {
  my $result = $conn->exec( "SELECT * FROM got_${type}_goterm ORDER BY got_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[2]) { $terms{$row[0]}{$row[1]} = $row[2]; }
      else { delete $terms{$row[0]}{$row[1]}; }
  } # while (@row = $result->fetchrow)
}

my $count = 0;
foreach my $gene (sort %terms) {
  if ($genes{$gene}) { $count++; }
}

print "$count\n";
