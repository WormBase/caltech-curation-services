#!/usr/bin/perl

# Add original 355 phenotype entries from phenotypes_20030327.txt

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $count = 0;

my $infile = 'phenotypes_20030327.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  my $joinkey;
  if ($count < 10) { $joinkey = '000000' . $count; }
  elsif ($count < 100) { $joinkey = '00000' . $count; }
  elsif ($count < 1000) { $joinkey = '0000' . $count; }
  elsif ($count < 10000) { $joinkey = '000' . $count; }
  elsif ($count < 100000) { $joinkey = '00' . $count; }
  elsif ($count < 1000000) { $joinkey = '0' . $count; }
  else { $joinkey = $count; }
  $joinkey = 'WBphenotype' . $joinkey;
  my ($threeletter, $reference, $definition) = split/\t/, $_;
  my $result = $conn->exec( "INSERT INTO phe_curator VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);" );
  $result = $conn->exec( "INSERT INTO phe_checked_out VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);" );
  $result = $conn->exec( "INSERT INTO phe_synonym VALUES ('$joinkey', '$threeletter', CURRENT_TIMESTAMP);" );
  $result = $conn->exec( "INSERT INTO phe_reference VALUES ('$joinkey', 'laboratory: $reference', CURRENT_TIMESTAMP);" );
  $result = $conn->exec( "INSERT INTO phe_definition VALUES ('$joinkey', '$definition', CURRENT_TIMESTAMP);" );
  $count++; 
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

