#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

open (OUT, ">./known_entities/Gene");

print "Processing genesequencelab...\n";
my $result = $dbh->prepare( "SELECT * FROM gin_genesequencelab" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[0]\n";
  } 
}

print "Processing locus...\n";
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[1]\n";
  } 
}

print "Processing seqname...\n";
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[1]\n";
  } 
}

print "Processing sequence...\n";
$result = $dbh->prepare( "SELECT * FROM gin_sequence" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
     print OUT "$row[1]\n";
  } 
}

print "Output stored in ./known_entities/Gene\n";
