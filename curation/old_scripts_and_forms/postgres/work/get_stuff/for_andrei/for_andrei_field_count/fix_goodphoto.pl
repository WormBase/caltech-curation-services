#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
# open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %photo;

my $result = $conn->exec( "SELECT * FROM cur_goodphoto WHERE cur_goodphoto ~ 'review';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[1] =~ s/\n$//g;
    $photo{$row[0]} = $row[1];
} }
$result = $conn->exec( "SELECT * FROM cur_goodphoto WHERE cur_goodphoto ~ 'no curatable';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[1] =~ s/\n$//g;
    $photo{$row[0]} = $row[1];
} }

foreach my $joinkey (sort keys %photo) {
  $result = $conn->exec( "SELECT * FROM cur_comment WHERE joinkey = '$joinkey');" );
  my @row = $result->fetchrow;
  if ($row[1]) { print "$joinkey has $row[1]\n"; } 
  else { 
    print "$joinkey : $photo{$joinkey}\n";
    $result = $conn->exec( "UPDATE cur_comment SET cur_comment = '$photo{$joinkey}' WHERE joinkey = '$joinkey'; ");
    $result = $conn->exec( "UPDATE cur_goodphoto SET cur_goodphoto = NULL WHERE joinkey = '$joinkey'; ");
  }
} # foreach my $joinkey (sort keys %photo)
