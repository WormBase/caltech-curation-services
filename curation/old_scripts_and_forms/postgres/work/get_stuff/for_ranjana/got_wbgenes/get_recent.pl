#!/usr/bin/perl -w
#
# Get got_ data from PG and write new .ace format.  2003 02 14
#
# Filter $goid to get rid of spaces before and after.
# Get WBPerson number instead of Kishore or Schwarz.  2003 02 25

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";


my %theHash;


my $result = $conn->exec( "SELECT got_wbgene FROM got_wbgene WHERE joinkey != 'test-1';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $theHash{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $wbgene (sort keys %theHash) {
  print OUT "$wbgene\n";
} # foreach my $wbgene (sort keys %theHash)
