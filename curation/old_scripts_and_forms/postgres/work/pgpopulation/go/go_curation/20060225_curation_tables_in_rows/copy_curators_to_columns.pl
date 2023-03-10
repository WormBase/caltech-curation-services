#!/usr/bin/perl -w

# Move got_curator data to columns (mol cell bio)  2006 02 25

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @columns = qw(bio cell mol);

my %curators;
my $result = $conn->exec( "SELECT * FROM got_curator ORDER BY got_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { $curators{$row[0]} = $row[1]; }
}

my %theHash;
foreach my $col (@columns) {
  %theHash = ();
  my $goid_table = 'got_' . $col . '_goid';
  my $result = $conn->exec( "SELECT * FROM $goid_table ORDER BY got_timestamp, got_order;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $theHash{$row[0]}{$row[1]} = $row[2]; }
  }
  foreach my $joinkey (sort keys %theHash) {
    foreach my $order (sort keys %{$theHash{$joinkey} }) {
      print OUT "JOIN $joinkey ORDER $order VALUE $theHash{$joinkey}{$order}\n";
      unless ($curators{$joinkey}) { print "ERROR no curator for $joinkey\n"; }
      my $value = 'NULL';
      if ($theHash{$joinkey}{$order}) { $value = "'$curators{$joinkey}'"; }
      my $pgcommand = "INSERT INTO got_${col}_curator_evidence VALUES ('$joinkey', '$order', $value, CURRENT_TIMESTAMP);";
      print OUT "$pgcommand\n";
      my $result2 = $conn->exec( $pgcommand );
    } # foreach my $order (sort keys %{$theHash{$joinkey} })
  } # foreach my $joinkey (sort keys %theHash)
} # foreach my $col (@columns)


close (OUT) or die "Cannot close $outfile : $!";
