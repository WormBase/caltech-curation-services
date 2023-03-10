#!/usr/bin/perl -w

# get interaction gene pairs from different sources for Jae.  2020 02 20

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %genes;

my @tables = qw( int_genenondir int_geneone int_genetwo grg_transregulator grg_transregulated );
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { &process($table, $row[0], $row[1]); } 
}


sub process {
  my ($table, $joinkey, $chunks) = @_;
  my (@genes) = $chunks =~ m/(WBGene\d+)/g;
  foreach my $gene (@genes) { $genes{$table}{$joinkey}{$gene}++; }
}


my %geneticPairAny;

my %geneticPairNondirectional;
foreach my $joinkey (sort keys %{ $genes{'int_genenondir'} }) {
  foreach my $geneA (sort keys %{ $genes{'int_genenondir'}{$joinkey} }) {
    foreach my $geneB (sort keys %{ $genes{'int_genenondir'}{$joinkey} }) {
      next if ($geneA eq $geneB);
      my @list = (); push @list, $geneA; push @list, $geneB; my @sortedlist = sort @list;
      my $pair = join"\t", @list;
      $geneticPairNondirectional{$pair}++;
      $geneticPairAny{$pair}++;
} } }

print qq(genetic pairs nondirectional\n);
foreach my $geneticPairNondirectional (sort keys %geneticPairNondirectional) { print qq($geneticPairNondirectional\n); }
print qq(\n);

my %geneticPairDirectional;
foreach my $joinkey (sort keys %{ $genes{'int_geneone'} }) {
  foreach my $geneA (sort keys %{ $genes{'int_geneone'}{$joinkey} }) {
    foreach my $geneB (sort keys %{ $genes{'int_genetwo'}{$joinkey} }) {
      my @list = (); push @list, $geneA; push @list, $geneB; my @sortedlist = sort @list;
      my $pair = join"\t", @list;
      $geneticPairDirectional{$pair}++;
      $geneticPairAny{$pair}++;
} } }

print qq(genetic pairs directional\n);
foreach my $geneticPairDirectional (sort keys %geneticPairDirectional) { print qq($geneticPairDirectional\n); }
print qq(\n);

print qq(genetic pairs any\n);
foreach my $geneticPairAny (sort keys %geneticPairAny) { print qq($geneticPairAny\n); }
print qq(\n);


my %regulatoryPair;
foreach my $joinkey (sort keys %{ $genes{'grg_transregulator'} }) {
  foreach my $geneA (sort keys %{ $genes{'grg_transregulator'}{$joinkey} }) {
    foreach my $geneB (sort keys %{ $genes{'grg_transregulated'}{$joinkey} }) {
      my @list = (); push @list, $geneA; push @list, $geneB; my @sortedlist = sort @list;
      my $pair = join"\t", @list;
      $regulatoryPair{$pair}++;
} } }

print qq(transregulatory pairs\n);
foreach my $regulatoryPair (sort keys %regulatoryPair) { print qq($regulatoryPair\n); }
print qq(\n);


__END__

