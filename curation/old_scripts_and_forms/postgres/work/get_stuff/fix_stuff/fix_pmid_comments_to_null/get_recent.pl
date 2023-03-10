#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";

my %pmid; my %comment;

my $result = $conn->exec( "SELECT joinkey FROM ref_pmid;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $pmid{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT joinkey FROM ref_comment WHERE joinkey ~ 'pmid';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $comment{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach $_ ( sort keys %pmid ) {
  unless ($comment{$_}) { print OUT "INSERT INTO ref_comment VALUES ('$_', NULL);\n"; }
} # foreach $_ ( sort keys %pmid )

close (OUT) or die "Cannot close $outfile : $!";

