#!/usr/bin/perl -w

# take ``doi/'' out of identifiers for Igor.  2006 05 04

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'doi';" );
while (my @row = $result->fetchrow) {
#   if ($row[0]) { print "$row[0]\n"; }
  my $id = $row[1];
  my ($new_id) = $row[1] =~ m/^doi\/(.*?)$/;
  my $command = "UPDATE wpa_identifier SET wpa_identifier = '$new_id' WHERE wpa_identifier = '$id';" ;
  my $result2 = $conn->exec( $command );
  print "$command\n";
}


close (OUT) or die "Cannot close $outfile : $!";
