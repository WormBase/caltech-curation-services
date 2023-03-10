#!/usr/bin/perl -w

# Get PIs and their mailing info (and other stuff) for Mary.  2005 06 03

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;

my $result = $conn->exec( "SELECT * FROM two_pis; " );
while (my @row = $result->fetchrow) {
  if ($row[0]) { $theHash{joinkeys}{$row[0]}{pis} = "$row[2]"; }
}

foreach my $joinkey (sort keys %{ $theHash{joinkeys} } ) {
  $result = $conn->exec( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Name\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_street WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Street\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_city WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "City\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_state WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "State\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_post WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "ZIP/Post\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_country WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Country\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Email\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_left_field WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Left the Field\t$row[2]\n"; } }

  $result = $conn->exec( "SELECT * FROM two_institution WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Institution\t$row[2]\n"; } }
  
  $result = $conn->exec( "SELECT * FROM two_pis WHERE joinkey = '$joinkey'; " );
  while (my @row = $result->fetchrow) { if ($row[0]) { print OUT "Lab Code\t$row[2]\n"; } }
 
  print OUT "\n";
  
} # foreach my $joinkey (sort keys %{ $theHash{joinkeys} } )

#  public | two_city                       | table    | postgres
#  public | two_country                    | table    | postgres
#  public | two_email                      | table    | postgres
#  public | two_institution                | table    | postgres
#  public | two_lab                        | table    | postgres
#  public | two_left_field                 | table    | postgres
#  public | two_post                       | table    | postgres
#  public | two_standardname               | table    | postgres
#  public | two_state                      | table    | postgres
#  public | two_street                     | table    | postgres



close (OUT) or die "Cannot close $outfile : $!";
