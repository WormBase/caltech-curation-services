#!/usr/bin/perl -w

# check what's in the with fields for GO curation  2008 01 25

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;
my @types = qw( bio mol cell );
foreach my $type (@types) {
  my $table = 'got_' . $type . '_with';
  my $result = $conn->exec( "SELECT * FROM $table ORDER BY got_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $hash{$type}{$row[0]}{$row[1]} = $row[2]; }
  } # while (@row = $result->fetchrow)
} # foreach my $type (@types)

foreach my $type (@types) {
  foreach my $joinkey (sort keys %{ $hash{$type} }) {
    foreach my $order (sort keys %{ $hash{$type}{$joinkey} }) {
      print "Type $type\tGene $joinkey\tColumn $order\tData $hash{$type}{$joinkey}{$order}\n"; 
    } # foreach my $order (sort keys %{ $hash{$type}{$joinkey} })
  } # foreach my $joinkey (sort keys %{ $hash{$type} })
} # foreach my $type (@types)

__END__

