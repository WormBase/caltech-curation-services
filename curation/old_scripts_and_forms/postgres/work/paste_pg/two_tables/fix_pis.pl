#!/usr/bin/perl

# get list of pis from cecilia, get data from lab for those keys and put into two_pis.
# 2003 03 26

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $infile = 'pis.list';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  my ($number) = $_ =~ m/(\d+)/;
  $hash{$number}++;
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $number (sort keys %hash) {
  my $joinkey = 'two' . $number;
  my $result = $conn->exec( "SELECT * FROM two_lab WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow;
  my $result2 = $conn->exec( "INSERT INTO two_pis VALUES ('$row[0]', '$row[1]', '$row[2]', '$row[3]', '$row[4]')" );
} # foreach my $number (sort keys %hash)
