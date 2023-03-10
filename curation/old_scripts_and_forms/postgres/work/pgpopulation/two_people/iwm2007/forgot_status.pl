#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $low = 6432;
my $high = 6644;
for my $i ($low .. $high) {
  print "INSERT INTO two_status VALUES ('two$i', '1', 'Valid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP;)\n";
  my $result = $conn->exec( "INSERT INTO two_status VALUES ('two$i', '1', 'Valid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);" );
}
