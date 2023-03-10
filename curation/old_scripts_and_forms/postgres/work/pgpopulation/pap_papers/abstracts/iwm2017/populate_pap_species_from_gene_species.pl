#!/usr/bin/perl -w

# map genes to species, map papers to genes, get genes to species.  to populate papers existing before parasite.

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %geneSpecies;
$result = $dbh->prepare( "SELECT * FROM gin_species" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $geneSpecies{$row[0]} = $row[1]; } }
my %speciesTaxon;
$result = $dbh->prepare( "SELECT * FROM pap_species_index" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $speciesTaxon{$row[1]} = $row[0]; } }


my %paps;
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid' AND pap_timestamp > '2017-07-21'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $paps{$row[0]}{exists}++; } }
$result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_timestamp > '2017-07-21'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $paps{$row[0]}{gene}{$row[1]}++; } }

my %maps;
foreach my $pap (sort keys %paps) {
  next unless ($paps{$pap}{exists});
  my %species;
  my %taxons;
  my $genes = join", ", sort keys %{ $paps{$pap}{gene} } || '';
  foreach my $gene (sort keys %{ $paps{$pap}{gene} }) {
    my $species = 'unknown';
    if ($geneSpecies{$gene}) {
        $species = $geneSpecies{$gene}; 
        my $taxon = 'unknown';
        if ($speciesTaxon{$species}) { $taxon = $speciesTaxon{$species}; }
          else { $taxon = qq(unknown species $species); }
        $taxons{$taxon}++;
      }
      else { $species = qq(unknown WBGene$gene); }
    $species{$species}++;
  } # foreach my $gene (sort keys %{ $paps{$pap}{gene} })
  my $species = join", ", sort keys %species;
  unless ($species) { $species = "NO DATA for genes $genes"; }
  my $taxons  = join", ", sort keys %taxons ;
  unless ($taxons) { $taxons = "NO DATA for genes $genes"; }
  print qq($pap\t$species\t$taxons\n);
} # foreach my $pap (sort keys %paps)



__END__

