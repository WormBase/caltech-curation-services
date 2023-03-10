#!/usr/bin/perl -w
#
# check list of labs from jonathan vs current list of labs  2003 11 24

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %hash;

my $result = $conn->exec( "SELECT DISTINCT two_lab FROM two_lab;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $hash{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $infile = '24';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  unless ($hash{$_}) { print OUT "$_\n"; }
}

close (OUT) or die "Cannot close $outfile : $!";
