#!/usr/bin/perl -w

# find pap_species entries for a paper-taxon where pap_evidence has Curator_confirmed + no Manually_connected

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %manually;
$result = $dbh->prepare( "SELECT * FROM pap_species WHERE pap_evidence ~ 'Manually_connected'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = $row[0] . '\t' . $row[1];
    $manually{$key}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %confirmed;
$result = $dbh->prepare( "SELECT * FROM pap_species WHERE pap_evidence ~ 'Curator_confirmed'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = $row[0] . '\t' . $row[1];
    unless ($manually{$key}) {
      print qq($key\n);
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

