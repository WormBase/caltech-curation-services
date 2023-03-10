#!/usr/bin/perl

# get stats for Karen  2012 06 06

use strict;

my $infile = '/home/acedb/work/allele_phenotype/allele_phenotype.ace.20120430';

my %hash;

$/ = '';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my @lines = split/\n/, $entry;
  my $header = shift @lines;
  my ($type, $objName) = $header =~ m/^(.*?) : \"(.*?)\"/;
  my $hasPhenotype = 0;
  foreach my $line (@lines) {
    if ($line =~ m/Phenotype\s+\"WBPhenotype:\d+\"/) { $hasPhenotype++; }
    if ($line =~ m/Phenotype_not_observed\s+\"WBPhenotype:\d+\"/) { $hasPhenotype++; }
  } # foreach my $line (@lines)
  if ($hasPhenotype) { 
    $hash{each_object}{$objName} = $hasPhenotype;
    $hash{type_has_phenotype}{$type}++; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $type (sort keys %{ $hash{type_has_phenotype} }) {
  print "$type has $hash{type_has_phenotype}{$type} entries with a phenotype\n"; 
} # foreach my $type (sort keys %{ $hash{type_has_phenotype} })

print "\n\n";

my $total_lines = 0;
foreach my $objName (sort keys %{ $hash{each_object} }) {
  $total_lines += $hash{each_object}{$objName};
  print "$objName has\t$hash{each_object}{$objName} phenotype lines\n"; 
}

print "\n\n";

print "total lines with a Phenotype $total_lines\n";

__END__

Strain : "AB1"
Species	"Caenorhabditis elegans"	// pgid 16825
Phenotype	"WBPhenotype:0000660"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000660"	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0000660"	Remark	"Animals are social foragers and aggregate in clumps in the presence of food."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000660"	Remark	"Animals are social foragers and aggregate in clumps in the presence of food."	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0000660"	Strain	"AB1"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000660"	Strain	"AB1"	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0000660"	Treatment	"Animals were assayed on a bacterial lawn."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000660"	Treatment	"Animals were assayed on a bacterial lawn."	Paper_evidence	"WBPaper00003187"
Species	"Caenorhabditis elegans"	// pgid 16836
Phenotype	"WBPhenotype:0001820"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001820"	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0001820"	Strain	"AB1"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001820"	Strain	"AB1"	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0001820"	Treatment	"Animals were assayed on a bacterial lawn."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001820"	Treatment	"Animals were assayed on a bacterial lawn."	Paper_evidence	"WBPaper00003187"
Species	"Caenorhabditis elegans"	// pgid 16852
Phenotype	"WBPhenotype:0000662"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000662"	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0000662"	Remark	"Animals moved more quickly on food than solitary foragers even though in the absence of food, both social and solitary foragers moved at similar rapid speeds.  When moving on food, social animals made long forays at speeds of ~190um/s until they joined a clump, at which point they reduced their speed and reversed frequently."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000662"	Remark	"Animals moved more quickly on food than solitary foragers even though in the absence of food, both social and solitary foragers moved at similar rapid speeds.  When moving on food, social animals made long forays at speeds of ~190um/s until they joined a clump, at which point they reduced their speed and reversed frequently."	Paper_evidence	"WBPaper00003187"
Phenotype	"WBPhenotype:0000662"	Strain	"AB1"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000662"	Strain	"AB1"	Paper_evidence	"WBPaper00003187"
Species	"Caenorhabditis elegans"	// pgid 17050
Phenotype	"WBPhenotype:0001764"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0001764"	Paper_evidence	"WBPaper00031936"
Phenotype	"WBPhenotype:0001764"	Remark	"Strains AB1, CB4853, and CB4856 are essentially unresponsive to CO2 compared to N2 control"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0001764"	Remark	"Strains AB1, CB4853, and CB4856 are essentially unresponsive to CO2 compared to N2 control"	Paper_evidence	"WBPaper00031936"
Phenotype	"WBPhenotype:0001764"	Life_stage	"adult hermaphrodite"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0001764"	Life_stage	"adult hermaphrodite"	Paper_evidence	"WBPaper00031936"
Phenotype	"WBPhenotype:0001764"	Strain	"AB1"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0001764"	Strain	"AB1"	Paper_evidence	"WBPaper00031936"
Phenotype	"WBPhenotype:0001764"	Treatment	"10% CO2"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0001764"	Treatment	"10% CO2"	Paper_evidence	"WBPaper00031936"
Species	"Caenorhabditis elegans"	// pgid 27447
Phenotype	"WBPhenotype:0002050"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0002050"	Paper_evidence	"WBPaper00040740"
Phenotype	"WBPhenotype:0002050"	Remark	"Animals are N2-like in their sensitivity to abamectin."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0002050"	Remark	"Animals are N2-like in their sensitivity to abamectin."	Paper_evidence	"WBPaper00040740"
Phenotype	"WBPhenotype:0002050"	Strain	"AB1"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0002050"	Strain	"AB1"	Paper_evidence	"WBPaper00040740"
Phenotype	"WBPhenotype:0002050"	Molecule	"C048324"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0002050"	Molecule	"C048324"	Paper_evidence	"WBPaper00040740"

