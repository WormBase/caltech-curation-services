#!/usr/bin/perl -w

# query exp_gene and gin_synonyms for non CELE_ genes.  for Daniela.  2014 05 16

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %cele;
my $result = $dbh->prepare( "SELECT * FROM gin_synonyms WHERE gin_synonyms ~ 'CELE_'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cele{"WBGene$row[0]"}++; } }

$result = $dbh->prepare( "SELECT * FROM exp_gene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my (@genes) = $row[1] =~ m/(WBGene\d+)/g;
  foreach my $gene (@genes) {
    unless ($cele{$gene}) { print "$gene not CELE_ in pgid $row[0]\n"; }
  } # foreach my $gene (@genes)
}

