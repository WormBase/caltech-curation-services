#!/usr/bin/perl -w

# get wen list of antibody data from first pass, converting pmids to cgcs where possible.
# 2004 02 03
#
# list above had some cgcs that had been first pass curated as both cgc and as pmid.
# this script gets all curated papers and outputs them in cgc and pmid format if they
# have been curated twice.  2004 02 19

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my %xref;
my %backxref;

my $result = $conn->exec( "SELECT * FROM ref_xref;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $xref{$row[1]} = $row[0]; $backxref{$row[0]} = $row[1]; } }

$result = $conn->exec( "SELECT * FROM cur_curator;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[1] =~ s/\n/ -- /g;
    if ($xref{$row[0]}) { $hash{$xref{$row[0]}}++; }
      else { $hash{$row[0]}++; }
#     if ($xref{$row[0]}) { print "$xref{$row[0]}\t$row[1]\n"; }
#       else { print "$row[0]\t$row[1]\n"; }
  }
}

foreach my $key (sort keys %hash) {
  if ($hash{$key} > 1) { print "$key\t$backxref{$key}\t$hash{$key}\n"; }
} # foreach my key (sort keys %hash)
