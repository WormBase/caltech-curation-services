#!/usr/bin/perl -w

# get wen list of antibody data from first pass, converting pmids to cgcs where possible.
# 2004 02 03

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my %xref;

my $result = $conn->exec( "SELECT * FROM ref_xref;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $xref{$row[1]} = $row[0]; } }

$result = $conn->exec( "SELECT * FROM cur_antibody WHERE cur_antibody IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[1] =~ s/\n/ -- /g;
    if ($xref{$row[0]}) { print "$xref{$row[0]}\t$row[1]\n"; }
      else { print "$row[0]\t$row[1]\n"; }
  }
}

