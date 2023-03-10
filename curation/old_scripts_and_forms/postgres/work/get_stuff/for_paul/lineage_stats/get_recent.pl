#!/usr/bin/perl -w
#
# get lineage statistics from two_lingeage  2004 09 16
#
# reran for Paul.  filtered out NULLs in joinkey, two_number, and two_role.
# 2006 06 20

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
# open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %hash;

my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey IS NOT NULL AND two_number IS NOT NULL AND two_role IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[3] =~ s///g;
    $row[4] =~ s///g;
    push @{ $hash{forw}{$row[0]}{$row[3]} }, $row[4];
    push @{ $hash{back}{$row[3]}{$row[0]} }, $row[4];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $people_connected;
my $connections_to_people;
my $connections_all;

foreach my $person (sort keys %{ $hash{forw} }) {
  $people_connected++;
  foreach my $connected (sort keys %{ $hash{forw}{$person} }) {
    $connections_to_people++;
    foreach my $type_connection ( @{ $hash{forw}{$person}{$connected} } ) {
      $connections_all++; } } }

print "There are :\n";
print "$people_connected people connected to other people\n";
print "$connections_to_people connections of a given person to a given person\n";
print "$connections_all connections of any type between people (counting two people connected multiple times under different types of connection e.g. undergrad + grad)\n"; 
    

foreach my $person (sort keys %{ $hash{forw} }) {
  foreach my $connected (sort keys %{ $hash{forw}{$person} }) {
    if ($hash{back}{$connected}{$person}) { 
      delete $hash{forw}{$person}{$connected};
      delete $hash{back}{$connected}{$person}; }
  }
} # foreach my $person (sort keys %{ $hash{forw} })

foreach my $person (sort keys %{ $hash{forw} }) {
  foreach my $connected (sort keys %{ $hash{forw}{$person} }) {
    print "MISSING F $person $connected\n"; } }

foreach my $person (sort keys %{ $hash{back} }) {
  foreach my $connected (sort keys %{ $hash{back}{$person} }) {
    print "MISSING B $person $connected\n"; } }




# close (OUT) or die "Cannot close $outfile : $!";
