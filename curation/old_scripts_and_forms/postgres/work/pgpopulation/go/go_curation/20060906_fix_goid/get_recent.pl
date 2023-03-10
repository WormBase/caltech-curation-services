#!/usr/bin/perl -w

# append GO: to entries missing them in got_cell_goid for Kimberly to fix Josh's
# data.  2006 09 06

use strict;
use diagnostics;
use Pg;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM got_cell_goid WHERE got_cell_goid IS NOT NULL AND got_cell_goid !~ '^GO:' AND got_timestamp > '2006-08-01' ORDER BY got_timestamp DESC; ");
while (my @row = $result->fetchrow) {
  if ($row[2]) { print "$row[2]\n";}
  my $goid = 'GO:' . $row[2];
  print OUT "UPDATE got_cell_goid SET got_cell_goid = '$goid' WHERE got_cell_goid = '$row[2]';\n";
  my $result2 = $conn->exec( "UPDATE got_cell_goid SET got_cell_goid = '$goid' WHERE got_cell_goid = '$row[2]';" );
}


close (OUT) or die "Cannot close $outfile : $!";
