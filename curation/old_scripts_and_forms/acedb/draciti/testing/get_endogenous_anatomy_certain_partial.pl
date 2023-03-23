#!/usr/bin/perl -w

# get unique wbgenes in exp_gene for Daniela, which also have exp_endogenous + certain / uncertain in exp_qualifier.  2014 07 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %genes;
my $result = $dbh->prepare( "SELECT * FROM exp_gene WHERE joinkey IN (SELECT joinkey FROM exp_endogenous) AND joinkey IN (SELECT joinkey FROM exp_qualifier WHERE exp_qualifier = 'Certain' OR exp_qualifier = 'Partial')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@genes) = $row[1] =~ m/(WBGene\d+)/g;
    foreach (@genes) { $genes{$_}++; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $gene (sort keys %genes) { 
  print "$gene\n";
} # foreach my $gene (sort keys %genes) 

