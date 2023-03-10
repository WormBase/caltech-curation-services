#!/usr/bin/perl -w
#
# Add entries to got_provisional and got_pro_paper_evidence with NULL values and
# joinkey as those from got_locus to match potential UPDATE calls.  2003 01 15
# don't run this again

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %loci;

my $result = $conn->exec( "SELECT joinkey FROM got_locus;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    my $locus = $row[0];
    my $result2 = $conn->exec( "INSERT INTO got_provisional VALUES ('$locus', NULL);");
    $result2 = $conn->exec( "INSERT INTO got_pro_paper_evidence VALUES ('$locus', NULL);");
  } # if ($row[0])
} # while (@row = $result->fetchrow)


close (OUT) or die "Cannot close $outfile : $!";
