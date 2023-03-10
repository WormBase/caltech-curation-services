#!/usr/bin/perl -w
#
# check which one entries merge ace entries (and will need to make sure i don't
# break stuff dealing with it)

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

for my $joinkey ( 27773 ..  28064 ) {
  $joinkey = '000' . $joinkey;
  my $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp ;" );
  my $count = 0;
  while (my @row = $result->fetchrow) {
    if ($row[2]) { print "ROW has order @row\n"; next; }
    $count++;
    my $command = "UPDATE wpa_author SET wpa_order = '$count' WHERE wpa_author = '$row[1]' AND joinkey = '$joinkey'; ";
    my $result2 = $conn->exec( $command );
    print "$command\n";
#     if ($row[0]) { 
#       $row[0] =~ s///g;
#       $row[1] =~ s///g;
#       $row[2] =~ s///g;
#       print "$row[0]\t$row[1]\t$row[2]\n";
#     } # if ($row[0])
  } # while (@row = $result->fetchrow)
} # for my $joinkey ( 27773 ..  28064 )


