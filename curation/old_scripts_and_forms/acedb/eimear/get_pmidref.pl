#!/usr/bin/perl -w
#
# Find the pmids and get their reference info

use strict;
use diagnostics;
use Pg;
use Jex;	# getSimpleDate

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $pmidreffile = "pmidreffile";

open(REF, ">$pmidreffile") or die "Cannot create $pmidreffile : $!";

# print OUT "GENE FUNCTION\n\n";

my %pmids;

my $result = $conn->exec( "SELECT * FROM ref_pmid;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    &getRef($row[0]);
  } # if ($row[0])
} # while (@row = $result->fetchrow)


sub getRef {
  my $pmid = shift;
  my @fields = qw(title author journal volume pages year abstract);
  print REF "$pmid";
  foreach my $field (@fields) {
    $field = 'ref_' . $field;
    my $result = $conn->exec( "SELECT * FROM $field WHERE joinkey = '$pmid';");
    my $out = '';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
        $row[1] =~ s///g;
#         $row[1] =~ s// /g;
        $row[1] =~ s/\n//g;
        $out = $row[1];
      } # if ($row[0])
    } # while (@row = $result->fetchrow)
    print REF "\t$out";
  } # foreach my $field (@fields)
  print REF "\n";
} # sub getRef

