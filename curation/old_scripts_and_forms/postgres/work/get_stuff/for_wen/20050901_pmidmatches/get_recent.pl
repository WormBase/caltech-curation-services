#!/usr/bin/perl -w

# Get all Papers that have the same PMID.  2005 09 01

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %id_hash;
my %valid_hash;

my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $valid_hash{$row[0]}++; }
    else { delete $valid_hash{$row[0]}; }
} # while (my @row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($valid_hash{$row[0]}) {			# if the paper is valid
    if ($row[3] eq 'valid') { $id_hash{$row[1]}{$row[0]}++; }
      else { delete $id_hash{$row[1]}{$row[0]}; }
  }
}

foreach my $pmid (sort keys %id_hash) {
  my @joinkeys;
  foreach my $joinkey (sort keys %{ $id_hash{$pmid} }) {
    push @joinkeys, $joinkey;
  } # foreach my $joinkey (sort keys %{ $id_hash{$pmid} })
  if (scalar(@joinkeys) > 1) { 
    my $joinkeys = join", ", @joinkeys;
    print OUT "$pmid\t$joinkeys\n"; }
} # foreach my $pmid (sort keys %id_hash)


close (OUT) or die "Cannot close $outfile : $!";
