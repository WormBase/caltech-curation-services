#!/usr/bin/perl

# Fix middlename and firstname entries that don't exist with NULLs (for two_standardname view)
# 2002 01 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %last;
my %first; 
my %middle;

my $result = $conn->exec( "SELECT joinkey FROM two_lastname;" );
while (my @row = $result->fetchrow) {
  my $joinkey = '';
  if ($row[0]) { $last{$row[0]}++; }
}

$result = $conn->exec( "SELECT joinkey FROM two_firstname;" );
while (my @row = $result->fetchrow) {
  my $joinkey = '';
  if ($row[0]) { $first{$row[0]}++; }
}

$result = $conn->exec( "SELECT joinkey FROM two_middlename;" );
while (my @row = $result->fetchrow) {
  my $joinkey = '';
  if ($row[0]) { $middle{$row[0]}++; }
}

foreach $_ (sort keys %last) {
  unless ($middle{$_}) { $result = $conn->exec( "INSERT INTO two_middlename VALUES ('$_', NULL);" ); }
  unless ($first{$_}) { $result = $conn->exec( "INSERT INTO two_firstname VALUES ('$_', NULL);" ); }
} # foreach $_ (sort keys %last)

print OUT "\n\nDIVIDER\n\n";

close (OUT) or die "Cannot close $outfile : $!";
