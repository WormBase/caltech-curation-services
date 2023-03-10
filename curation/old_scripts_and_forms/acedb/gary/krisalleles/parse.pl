#!/usr/bin/perl

# only care about variation, not phenotype (paragraph is variation-phenotype, so append to hash)  2009 07 09

use strict;

my %hash;

my $infile = 'allele_phenotype.ace.20090629';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($id) = $para =~ m/Variation : "(.*?)"/;
  $hash{$id}{exists}++; 					# if want to get all instead of only those with evidence / temp sens
  if ($para =~ m/Heat_sensitive/) { $hash{$id}{heat}++; }
  if ($para =~ m/Cold_sensitive/) { $hash{$id}{cold}++; }
  if ($para =~ m/Person_evidence/) { 
    my (@persons) = $para =~ m/"(WBPerson\d+)"/g;
    foreach (@persons) { $hash{$id}{person}{$_}++; }
  }
  if ($para =~ m/Paper_evidence/) { 
    my (@persons) = $para =~ m/"(WBPaper\d+)"/g;
    foreach (@persons) { $hash{$id}{paper}{$_}++; }
  }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

my %temp_paper;			# papers that have some temp sens variation
my $outfile = 'all_wo_temp';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $outfile2 = 'in_temp_paper_wo_temp';
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!";

foreach my $id (sort keys %hash) {
  if ( ($hash{$id}{heat}) || ($hash{$id}{cold}) ) {
    if ($hash{$id}{paper}) {
      foreach my $paper ( keys %{ $hash{$id}{paper} }) { $temp_paper{$paper}++; } } } }

foreach my $id (sort keys %hash) {
  next if ($hash{$id}{heat});
  next if ($hash{$id}{cold});
  my $print_flag = 0;
  my $data = '';
  $data .= "Variation : \"$id\"\n";
  if ($hash{$id}{person}) {
    my $persons = join(", ", sort keys %{ $hash{$id}{person} });
    $data .= "WBPersons\t$persons\n";
  }
  if ($hash{$id}{paper}) {
    my $papers = join(", ", sort keys %{ $hash{$id}{paper} });
    $data .= "WBPapers\t$papers\n";
    foreach my $paper ( keys %{ $hash{$id}{paper} }) { if ($temp_paper{$paper}) { $print_flag++; } }
  }
  $data .= "\n";
  print OUT $data;
  if ($print_flag) { print OU2 $data; }
} # foreach my $id (sort keys %hash
close (OUT) or die "Cannot close $outfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";

__END__

Juancarlos,

The file to parse (allele_phenotype.ace.20090629) can be found on 
tazendra in /home/acedb/gary/krisalleles.


The two out puts should be:

output1

All alleles and paper or person reference that DO NOT include either

Heat_sensitive

Cold_sensitive


the format:

something like


Variation : "xxxx"

paper/person evidence: WBPXXXX


Variation : "yyyyy"

paper/person evidence: WBPYYYY



Output 2

will have the same format of output, but will include all alleles that 
DO NOT include either

Heat_sensitive

Cold_sensitive

AND are from Paper_evidence where another allele is temp sensitive.


__END__ 

Variation : "ad472"
Phenotype	"WBPhenotype:0000081"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0000081"	Paper_evidence	"WBPaper00001709"
Phenotype	"WBPhenotype:0000081"	Remark	"Weakly cold sensitive: More larvae passed the L1 block at 25 C than at 15 C or 20 C."	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0000081"	Remark	"Weakly cold sensitive: More larvae passed the L1 block at 25 C than at 15 C or 20 C."	Paper_evidence	"WBPaper00001709"
Phenotype	"WBPhenotype:0000081"	Remark	"Weakly cold sensitive: More larvae passed the L1 block at 25 C than at 15 C or 20 C."
Phenotype	"WBPhenotype:0000081"	Cold_sensitive	""	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0000081"	Cold_sensitive	""	Paper_evidence	"WBPaper00001709"
Phenotype	"WBPhenotype:0000081"	Life_stage	"L1 larva"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0000081"	Life_stage	"L1 larva"	Paper_evidence	"WBPaper00001709"
Phenotype	"WBPhenotype:0000081"	Temperature	"15, 20, 25"	Curator_confirmed	"WBPerson2021"
Phenotype	"WBPhenotype:0000081"	Temperature	"15, 20, 25"	Paper_evidence	"WBPaper00001709"

Variation : "ar226"
Phenotype	"WBPhenotype:0001033"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0001033"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0001033"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0001033"	"Recessive"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0001033"	"Recessive"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0001033"	"Recessive"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0001033"	Penetrance	Low ""	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0001033"	Penetrance	Low ""	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0001033"	Penetrance	Low ""	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0001033"	Range	"7" "7"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0001033"	Range	"7" "7"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0001033"	Range	"7" "7"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0001033"	"Hypomorph"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0001033"	"Hypomorph"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0001033"	"Hypomorph"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0001033"	Temperature	"25"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0001033"	Temperature	"25"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0001033"	Temperature	"25"	Paper_evidence	"WBPaper00028280"

Variation : "ar226"
Phenotype	"WBPhenotype:0000823"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0000823"	"Recessive"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	"Recessive"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	"Recessive"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0000823"	Penetrance	Incomplete ""	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	Penetrance	Incomplete ""	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	Penetrance	Incomplete ""	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0000823"	Range	"72" "72"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	Range	"72" "72"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	Range	"72" "72"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0000823"	Heat_sensitive	"25"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	Heat_sensitive	"25"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	Heat_sensitive	"25"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0000823"	"Hypomorph"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	"Hypomorph"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	"Hypomorph"	Paper_evidence	"WBPaper00028280"
Phenotype	"WBPhenotype:0000823"	Temperature	"25.7"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000823"	Temperature	"25.7"	Person_evidence	"WBPerson261"
Phenotype	"WBPhenotype:0000823"	Temperature	"25.7"	Paper_evidence	"WBPaper00028280"

Variation : "a83"
Phenotype	"WBPhenotype:0000255"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000255"	Paper_evidence	"WBPaper00002087"
Phenotype	"WBPhenotype:0000255"	Remark	"Defects in dye filling."	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000255"	Remark	"Defects in dye filling."	Paper_evidence	"WBPaper00002087"
Phenotype	"WBPhenotype:0000255"	Remark	"Defects in dye filling."
Phenotype	"WBPhenotype:0000255"	"Recessive"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000255"	"Recessive"	Paper_evidence	"WBPaper00002087"

Variation : "a83"
Phenotype	"WBPhenotype:0000255"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000255"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000255"	Remark	"FITC does not stain amphids or phasmids."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000255"	Remark	"FITC does not stain amphids or phasmids."	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000255"	Remark	"FITC does not stain amphids or phasmids."

Variation : "a83"
Phenotype	"WBPhenotype:0001530"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001530"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0001530"	Remark	"FITC occasionally stains CEP."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001530"	Remark	"FITC occasionally stains CEP."	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0001530"	Remark	"FITC occasionally stains CEP."

Variation : "a83"
Phenotype	"WBPhenotype:0001535"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001535"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0001535"	Remark	"FITC occasionally stains ADE or PDE."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0001535"	Remark	"FITC occasionally stains ADE or PDE."	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0001535"	Remark	"FITC occasionally stains ADE or PDE."

Variation : "a83"
Phenotype	"WBPhenotype:0000505"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000505"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000505"	Remark	"FITC occasionally stains ray sensilla."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000505"	Remark	"FITC occasionally stains ray sensilla."	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000505"	Remark	"FITC occasionally stains ray sensilla."

Variation : "a83"
Phenotype	"WBPhenotype:0000478"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000478"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000478"	NOT	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000478"	NOT	Paper_evidence	"WBPaper00000932"

Variation : "a83"
Phenotype	"WBPhenotype:0000315"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000315"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000315"	NOT	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000315"	NOT	Paper_evidence	"WBPaper00000932"

Variation : "a83"
Phenotype	"WBPhenotype:0000843"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000843"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000843"	Remark	"Mating efficiency 0; no detected matings."	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000843"	Remark	"Mating efficiency 0; no detected matings."	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000843"	Remark	"Mating efficiency 0; no detected matings."
Phenotype	"WBPhenotype:0000843"	Genotype	"him-5(e1490)"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000843"	Genotype	"him-5(e1490)"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000843"	Life_stage	"adult male"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000843"	Life_stage	"adult male"	Paper_evidence	"WBPaper00000932"

