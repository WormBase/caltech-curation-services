#!/usr/bin/perl -w

# Fix got_synonym entries by adding entries to PG for all got_locus entries.  2003 02 27

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT joinkey FROM got_locus;" );
while (my @row = $result->fetchrow) { 
  my $result2 = $conn->exec( "INSERT INTO got_synonym VALUES ('$row[0]', NULL);" );
} # while (my @row = $result->fetchrow)

