#!/usr/bin/perl -w
#
# Find Papers from the year 2000 that do not have PDFs for Daniel
# 2002 12 18

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_daniel/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %pdfs;
my %y2000;

my $result = $conn->exec( "SELECT * FROM ref_pdf WHERE ref_pdf IS NOT NULL;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $pdfs{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM ref_year WHERE ref_year = '2000';");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $y2000{$row[0]} = $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pmid (sort keys %y2000) {
  unless ($pdfs{$pmid}) { print "$pmid\n"; }
} # foreach my $pmid (sort keys %pmids)




close (OUT) or die "Cannot close $outfile : $!";
