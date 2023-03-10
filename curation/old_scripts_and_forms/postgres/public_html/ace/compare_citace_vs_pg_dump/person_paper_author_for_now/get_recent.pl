#!/usr/bin/perl -w
#
# Get all Verified data from pap_view.  Store by person the papers and timestamps.
# Get all Persons from pap_possible.  Store by person and by author-name the highest timestamp.
# Output all to .ace file.
# This doesn't need a -D for re-entry because that's taken care of by the Person (full two data)
# dump (entry), since all the stuff here is entered via Person.
# Data goes to Possibly_publishes_as whether or not it's confirmed (as opposed to Publishes_as)
# because there's no XREF back for Publishes_as.  2003 04 10
#
# Filter .'s and ,'s from names of Authors because Eimear doesn't want them.  2003 05 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
my %hash;

open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_verified ~ 'YES';");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    my $joinkey = $row[0];
    $row[1] =~ s///g;
    my $author = $row[1];
    $row[2] =~ s///g;
    my $person = $row[2];
    $person =~ s/two/WBPerson/g;
    my $result2 = $conn->exec( "SELECT pap_timestamp FROM pap_verified WHERE joinkey = '$joinkey' AND pap_author = '$author';");
    my @row2 = $result2->fetchrow;
    my $timestamp = $row2[0];
    $timestamp = &otime($timestamp);
    $hash{$person}{paper}{$joinkey} = $timestamp;
  } # if ($row[0])
} # while (my @row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM pap_possible WHERE pap_possible IS NOT NULL;");
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    $row[1] =~ s///g;
    my $author = $row[1];
    $row[2] =~ s///g;
    my $person = $row[2];
    $person =~ s/two/WBPerson/g;
    $row[3] =~ s///g;
    my $timestamp = $row[3];
    $timestamp = &otime($timestamp);

    if ($author =~ m/^[\-\w\s]+"/) { $author =~ m/^([\-\w\s]+)\"/; $author = $1; }
    my $highest = 0;
    if ( $hash{$person}{author}{$author} ) {	# if there's timestamp, get numerical value as highest
      $highest = $hash{$person}{author}{$author};
      ($highest) = $highest =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d)/;
      $highest =~ s/\D//g;
    }
    my $time_temp = $timestamp;
    ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d)/;
    $time_temp =~ s/\D//g;
    if ($time_temp > $highest) {
      $highest = $time_temp;
      $hash{$person}{author}{$author} = $timestamp;
    } # if ($time_temp > $highest)

  } # if ($row[0])
} # while (my @row = $result->fetchrow)

foreach my $person (sort keys %hash) {
  print OUT "Person\t$person\n";
  foreach my $paper (sort keys %{$hash{$person}{paper}}) {
    print OUT "Paper\t\"[$paper]\"\n";
#     print OUT "Paper\t\"[$paper]\" -O \"$hash{$person}{paper}{$paper}\"\n";
  } # foreach my $paper (sort keys %{$hash{$person}})
  foreach my $author (sort keys %{$hash{$person}{author}}) {
    $author =~ s/\.//g; $author =~ s/,//g;
    print OUT "Possibly_publishes_as\t\"$author\"\n";
#     print OUT "Possibly_publishes_as\t\"$author\" -O \"$hash{$person}{author}{$author}\"\n";
  } # foreach my $paper (sort keys %{$hash{$person}})
  print OUT "\n";
} # foreach my $person (sort keys %hash)

close (OUT) or die "Cannot close $outfile : $!";


sub otime {
  my $otime = shift;
  $otime =~ s/\-\d\d$/_cecilia/g;
  return $otime;
} # sub otime

