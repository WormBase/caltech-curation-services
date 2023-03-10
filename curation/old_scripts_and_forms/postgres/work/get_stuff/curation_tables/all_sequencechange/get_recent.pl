#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM cur_sequencechange WHERE cur_sequencechange IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[1] =~ s/\n/ /g;
    print OUT "$row[0]\t$row[1]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


close (OUT) or die "Cannot close $outfile : $!";

