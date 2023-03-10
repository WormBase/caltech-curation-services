#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $infile = 'interaction_acedb_dump_20080222.ace';

$/ = "";

my %hash;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my ($name) = $entry =~ m/Interaction : \"WBInteraction(\d+)\"/;
  next unless ($name);
  $hash{$name} = $entry;
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $name (sort keys %hash) {
  unless ($name) { print "BAD $hash{$name} BAD\n"; }
  my $int = $name;
  $int++; $int--;
  my $command = "INSERT INTO int_index VALUES ('$name', '$int', 'acedb');";
  print "$command\n";
  my $result = $conn->exec( "$command" );
#   print "N $name I $int N\n";
} # foreach my $name (sort keys %hash)

