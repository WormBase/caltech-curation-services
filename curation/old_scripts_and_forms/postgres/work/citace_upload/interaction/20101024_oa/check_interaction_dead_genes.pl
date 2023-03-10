#!/usr/bin/perl -w

# check int_gene tables for dead genes against gin_dead tables.  2011 12 12

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %dead;
my $result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $dead{$row[0]}++; }

my %dead_genes;
my @tables = qw( int_geneone int_genetwo int_geneextra );
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      my (@genes) = $row[1] =~ m/WBGene(\d+)/g;
      foreach my $gene (@genes) {
        if ($dead{$gene}) { $dead_genes{$gene}{$row[0]}++; } } } }
} # foreach my $table (@tables)

foreach my $gene (sort keys %dead_genes) {
  my @pgids = sort keys %{ $dead_genes{$gene} };
  my $pgids = join", ", @pgids;
  print "WBGene$gene\t$pgids\n";
}

