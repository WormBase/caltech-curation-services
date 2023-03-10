#!/usr/bin/perl -w
#
# Jeffrey H. Thomas has been assigned to 213 papers to which he's only said YES to 8.  
# These 8 must be maintained, and the other 205 need to be recreated blank and copied
# with his pap_author showing as "Jeffrey H. Thomas" instead of whatever it shows now.
# It must update pap_author, pap_verified, pap_email, pap_possible.  2003 10 15
#
# Danger.  People that did not publish a paper will show in the confirm_paper.cgi
# so authors may complain about this.   2003 10 15

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT * FROM pap_verified WHERE pap_verified ~ 'NO' AND pap_verified ~ 'Jeffrey';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $hash{$row[0]} = $row[1];
#     my $result2 = $conn->exec( "INSERT INTO two_paper VALUES ('two655', '$row[0]');" );
# don't forget to add them to two_paper
  }
}

foreach my $paper (sort keys %hash) {
  my $author = $hash{$paper};
  $result = $conn->exec( "UPDATE pap_author SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';" );
  $result = $conn->exec( "UPDATE pap_verified SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';" );
  $result = $conn->exec( "UPDATE pap_email SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';" );
  $result = $conn->exec( "UPDATE pap_possible SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';" );
  $result = $conn->exec( "INSERT INTO pap_author VALUES ('$paper', '$author', 'two655', NULL, NULL);" );
  $result = $conn->exec( "INSERT INTO pap_possible VALUES ('$paper', '$author', 'two655');" );
  $result = $conn->exec( "INSERT INTO pap_email VALUES ('$paper', '$author', NULL);" );
  $result = $conn->exec( "INSERT INTO pap_verified VALUES ('$paper', '$author', NULL);" );
#   print "UPDATE pap_author SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';\n";
#   print "UPDATE pap_verified SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';\n";
#   print "UPDATE pap_email SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';\n";
#   print "UPDATE pap_possible SET pap_author = 'Jeffrey H. Thomas' WHERE joinkey = '$paper' AND pap_author = '$author';\n";
#   print "INSERT INTO pap_author VALUES ('$paper', '$author', 'two655', NULL, NULL);\n";
#   print "INSERT INTO pap_possible VALUES ('$paper', '$author', 'two655');\n";
#   print "INSERT INTO pap_email VALUES ('$paper', '$author', NULL);\n";
#   print "INSERT INTO pap_verified VALUES ('$paper', '$author', NULL);\n";
} # foreach my $paper (sort keys %hash)




