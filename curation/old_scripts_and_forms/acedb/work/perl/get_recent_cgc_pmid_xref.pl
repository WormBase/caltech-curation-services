#!/usr/bin/perl -w
#
# Quick PG query to get tab delimited cgc to pmid xrefs.  2003 04 09

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "cgc_pmid_xref.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM ref_xref ORDER BY ref_cgc;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    print OUT "$row[0]\t$row[1]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)
