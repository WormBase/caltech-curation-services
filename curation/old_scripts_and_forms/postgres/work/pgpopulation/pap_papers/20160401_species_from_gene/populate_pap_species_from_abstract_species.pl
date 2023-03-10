#!/usr/bin/perl -w

# generate mapping of papers to species based on abstracts.  2016 04 01
#
# take in manual extra taxon mappings from Kimberly.  2016 05 12

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
  if ($row[0]) { 
    $speciesTaxon{$row[1]} = $row[0]; 
    my (@words) = split/\s+/, $row[1];
    my $genus = shift @words;
    my $species = join " ", @words;
    my ($ginit) = $genus =~ m/^([A-Z])/;
    my $key = qq($ginit $species);
    $speciesTaxon{$key} = $row[0];
    $key = qq(${ginit}. $species);
    $speciesTaxon{$key} = $row[0];
} }
# foreach my $key (sort keys %speciesTaxon) { print qq($key\t$speciesTaxon{$key}\n); }

# no longer using taxons_extra file, recreated species list from smaller list of 101 that Kimberly generated
# my $taxon_file = 'taxons_extra';
# open (IN, "<$taxon_file") or die "Cannot open $taxon_file : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   my ($name, $taxon) = split/\t/, $line;
#   $speciesTaxon{$name} = $taxon;
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $taxon_file : $!";


my %paps;
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $paps{$row[0]}{exists}++; } }

# my %paps;
# my $infile = 'papers_check_abstract';
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>)  {
#   chomp $line;
#   my ($pap, $junk) = split/\t/, $line;
#   $paps{$pap}++;
# } # while (my $line = <IN>) 
# 
# my $joinkeys = join"','", sort keys %paps;

my %abstracts;
$result = $dbh->prepare( "SELECT * FROM pap_abstract" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $abstracts{$row[0]} = $row[1];
} # while (@row = $result->fetchrow)

# my %species;
# $result = $dbh->prepare( "SELECT * FROM pap_species_index ;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   $species{$row[1]} = $row[0];
# } # while (@row = $result->fetchrow)

my $count = 0;
foreach my $pap (sort keys %abstracts) {
  my $abstract = $abstracts{$pap};
  my %speciesMatched;
  my %taxonsMatched;
  foreach my $species (sort keys %speciesTaxon) {
    if ($abstract =~ m/$species/) {
      my $taxon = 'unknown';
      if ($speciesTaxon{$species}) { $taxon = $speciesTaxon{$species}; }
        else { $taxon = qq(unknown species $species); }
      $taxonsMatched{$taxon}++;
      $speciesMatched{$species}++;
#       print qq($species IN $pap IN $abstract\n); 
    } 
  } # foreach my $species (sort keys %species)
  my $species = join", ", sort keys %speciesMatched;
  unless ($species) { $species = "NO species"; }
  my $taxons  = join", ", sort keys %taxonsMatched ;
  unless ($taxons) { $taxons = "NO taxons"; }
  print qq($pap\t$species\t$taxons\t$abstract\n);
#   $count++; last if ($count > 300);
} # foreach my $pap (sort keys %abstracts)

__END__


$result = $dbh->prepare( "SELECT * FROM pap_gene" );
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

