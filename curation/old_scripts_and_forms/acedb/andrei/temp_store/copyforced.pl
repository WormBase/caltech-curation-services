#!/usr/bin/perl

# take all the manually created cgc-pmid correlations to force into 
# cgc-pmid table and enter it.  (from ref_xrefpmidforced to ref_xref)
# 2004 01 08

use strict;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM ref_xrefpmidforced;" );
while (my @row = $result->fetchrow) {
  my $result2 = $conn->exec( "INSERT INTO ref_xref VALUES ('$row[0]', '$row[1]');" );
} # while (my @row = $result->fetchrow)
