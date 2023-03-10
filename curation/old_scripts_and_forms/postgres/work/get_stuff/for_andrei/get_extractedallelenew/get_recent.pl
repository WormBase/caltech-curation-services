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

my %pmid;
my %cgc;
my %both;

my $result = $conn->exec( "SELECT * FROM cur_extractedallelenew WHERE cur_extractedallelenew IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[2]\t$row[0]\t$row[1]\n";
} }

