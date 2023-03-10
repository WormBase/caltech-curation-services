#!/usr/bin/perl

# process alliance molecular interactions to generate stats.  2019 10 02

use strict;
use diagnostics;

my $start = time;

my @order = qw( totalInteractionCount interactorsPerSpecies interactorTypes interactorTypePairsSorted interactorTypePairsSortedTaxid:9606 interactorTypePairsSortedTaxid:10116 interactorTypePairsSortedTaxid:10090 interactorTypePairsSortedTaxid:7955 interactorTypePairsSortedTaxid:7227 interactorTypePairsSortedTaxid:6239 interactorTypePairsSortedTaxid:559292 interactorTypePairsSortedInterspecies interactionTypes experimentalRoles sourceDatabases interactionIdPrefixes primaryInteractorId altInteractorId aliasInteractorId detectionMethods );



my %taxonInteraction;			# for a given column 10 & 11, get the column 14 and store by taxon Id if the same or by 'Interspecies' if different
my %hash;
my $count = 0;
# my $infile = 'Alliance_molecular_interactions_2.2.txt';
my $infile = 'alliance_molecular_interactions.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^#/);
#   $count++; last if ($count > 10);
  chomp $line;
  my @tabs = split/\t/, $line;
  &processPipeColon('primaryInteractorId', $tabs[0], $tabs[1]);
  &processPipeColon('altInteractorId', $tabs[2], $tabs[3]);
  &processPipeColon('aliasInteractorId', $tabs[4], $tabs[5]);
  &processSingle('detectionMethods', $tabs[6]);
  &processSingle('interactorsPerSpecies', $tabs[9], $tabs[10]);
  &processTaxonInteraction($tabs[9], $tabs[10], $tabs[13], $tabs[20], $tabs[21]);
  &processSingle('interactionTypes', $tabs[11]);
  &processSingle('sourceDatabases', $tabs[12]);
  &processSingle('totalInteractionCount', $tabs[13]);
  &processPipeColon('interactionIdPrefixes', $tabs[13]);
  &processSingle('experimentalRoles', $tabs[18], $tabs[19]);
  &processSingle('interactorTypes', $tabs[20], $tabs[21]);
}
close (IN) or die "Cannot close $infile : $!";

sub processPairSorted {
  my ($cat, @tab) = @_;
  my $key = join" ", sort @tab;
  $hash{$cat}{$key}++;
}

sub processPipeColon {
  my ($cat, @tab) = @_;
  foreach my $tab (@tab) {
    my (@entries) = split/\|/, $tab;
    foreach my $entry (@entries) {
      my ($val, @junk) = split/:/, $entry;	# allows entries that don't have a :
#       my ($val) = $entry =~ m/^(.*?):/;		# gives warnings when entries don't have a :
      $hash{$cat}{$val}++;
    }
  }
}

sub processColon {
  my ($cat, @tab) = @_;
  foreach my $tab (@tab) {
    my ($val, @junk) = split/:/, $tab;	# allows entries that don't have a :
#     my ($val) = $tab =~ m/^(.*?):/;		# gives warnings when entries don't have a :
    $hash{$cat}{$val}++;
  }
}

sub processSingle {
  my ($cat, @tab) = @_;
  foreach my $tab (@tab) {
    $hash{$cat}{$tab}++;
} }

sub processTaxonInteraction {
  my ($taxid1, $taxid2, $interaction, $intType1, $intType2) = @_;
  my @intTypes; push @intTypes, $intType1; push @intTypes, $intType2;
  my $key = join" ", sort @intTypes;
  my ($taxon1) = $taxid1 =~ m/taxid:(\d+)/;
  my ($taxon2) = $taxid2 =~ m/taxid:(\d+)/;
  $hash{interactorTypePairsSorted}{$key}++;
  if ($taxon1 eq $taxon2) { 
      my $cat = 'interactorTypePairsSortedTaxid:' . $taxon1;
      $hash{$cat}{$key}++;
      $taxonInteraction{$taxon1}{$interaction}++; }
    else { 
      $hash{'interactorTypePairsSortedInterspecies'}{$key}++;
      $taxonInteraction{'Interspecies'}{$interaction}++; }
}

sub processTaxon {
  my %taxonToPipe; my %tabToTaxon;
  my $cat = 'interactorsPerSpecies';
  foreach my $tab (sort keys %{ $hash{$cat} }) {
    my ($taxon) = $tab =~ m/taxid:(\d+)/;
    $tabToTaxon{$tab} = $taxon;
    if ($tab =~ m/\|/) { $taxonToPipe{$taxon} = $tab; }
  }
  my %temp;
  foreach my $tab (sort keys %{ $hash{$cat} }) {
    my $count = $hash{$cat}{$tab};
    my $taxon = $tabToTaxon{$tab};
    if ($taxonToPipe{$taxon}) { 
        $taxon = $taxonToPipe{$taxon}; }
      else { 
#         print qq(ERR TAB $tab TAXON $taxon doesn't map\n); 
        $taxon = $tab; }
    $temp{$taxon} += $count;
  }
  my $interactorsPerSpecies = qq(Interactors Per Species :\n);
  foreach my $pipe (sort {$temp{$b}<=>$temp{$a}} keys %temp) { $interactorsPerSpecies .= qq($pipe\t$temp{$pipe}\n); }

  %temp = ();
  foreach my $taxon (keys %taxonInteraction) {
    my $count = scalar keys %{ $taxonInteraction{$taxon} }; 
    if ($taxonToPipe{$taxon}) { $taxon = $taxonToPipe{$taxon}; }
    $temp{$taxon} = $count; }
  print qq(Interactions Per Species :\n);
  foreach my $pipe (sort {$temp{$b}<=>$temp{$a}} keys %temp) { print qq($pipe\t$temp{$pipe}\n); }
  print qq(\n$interactorsPerSpecies);
}


# foreach my $cat (sort keys %hash) 
foreach my $cat (@order) {
  my $printCat = $cat;
  $printCat =~ s/([A-Z])/ $1/g; $printCat = ucfirst($printCat);
  if ($cat eq 'interactorsPerSpecies') { &processTaxon(); }
    elsif ($cat eq 'totalInteractionCount') { 
      print qq($printCat :\n);
      my $count = scalar keys %{ $hash{$cat} };
      print qq(total\t$count\n); }
    else {
      print qq($printCat :\n);
      foreach my $val (sort {$hash{$cat}{$b} <=> $hash{$cat}{$a}} keys %{ $hash{$cat} }) {
        print qq($val\t$hash{$cat}{$val}\n);
      } }
  print qq(\n);
}

my $end = time;
my $diff = $end - $start;
# print qq($diff seconds\n);
