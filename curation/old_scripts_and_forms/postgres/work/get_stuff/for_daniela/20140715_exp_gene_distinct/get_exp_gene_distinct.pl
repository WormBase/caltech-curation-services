#!/usr/bin/perl -w

# get unique wbgenes in exp_gene for Daniela.  2014 07 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %genes;
my $result = $dbh->prepare( "SELECT * FROM exp_gene" );
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

