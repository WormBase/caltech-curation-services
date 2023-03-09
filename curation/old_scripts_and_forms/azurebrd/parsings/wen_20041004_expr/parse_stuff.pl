#!/usr/bin/perl

# Parse files for Wen according to UBCExprTemplate.txt (x_ray should be x-ray)
# 2004 10 05

use strict; 
use diagnostics;

my $expr_file = 'expprfls.txt';
my $strain_file = 'strains.txt';

my $transgene_outfile = 'transgene.ace';
my $expr_outfile = 'expr.ace';

open (EXP, ">$expr_outfile") or die "Cannot create $expr_outfile : $!";
open (TRA, ">$transgene_outfile") or die "Cannot create $transgene_outfile : $!";

my %transgenic;

open (IN, "<$strain_file") or die "Cannot open $strain_file : $!";
my $skip = <IN>;
while (<IN>) {
  chomp;
  my ($strain_name, $transgenic_name, $mutagen, $outcrossed, $gene_name, $gene_locus, @junk) = split"\t", $_;
  if ($transgenic{$strain_name}) { print "ERR $strain_name has multiple $transgenic_name, $transgenic{$strain_name}\n"; }
  $transgenic{$strain_name} = $transgenic_name;
  print TRA "Transgene : \"$transgenic_name\"\n";
  unless ($gene_locus) { $gene_locus = $gene_name; }
  print TRA "Summary\t\"[${gene_locus}::gfp] transcriptional fusion.\"\n";
  print TRA "Driven_by_CDS_promoter\t\"$gene_name\"\n";
  print TRA "Reporter_product\t\"GFP\"\n";
  print TRA "Strain\t\"$strain_name\"\n";
  if ($mutagen =~ m/1500 R x-ray/) { print TRA "Integrated_by\t\"X_ray\"\n"; }
  print TRA "Location\t\"BC\"\n\n";
} # while (<IN>)
close (IN) or die "Cannot close $strain_file : $!";

open (IN, "<$expr_file") or die "Cannot open $expr_file : $!";
$skip = <IN>;
my $count = 5000;
while (<IN>) {
  chomp;
  $count++;
  my ($gene, $locus, $strain, $primA, $primB, $location, $strain_comments, $embryo, $larval, $adult) = split"\t", $_;
  print EXP "Expr_pattern : \"Expr$count\"\n";
  print EXP "CDS\t\"$gene\"\n";
  unless ($locus) { $locus = $gene; }
  print EXP "Reporter_gene\t\"[${locus}::gfp] transcriptional fusion. PCR products were amplified using primer A: 5' [$primA] 3' and primer B 5' [$primB] 3'.\"\n";
  if ($embryo) { print EXP "Pattern\t\"Embryo Expression: $embryo\"\n"; }
  if ($larval) { print EXP "Pattern\t\"Larval Expression: $larval\"\n"; }
  if ($adult) { print EXP "Pattern\t\"Adult Expression: $adult\"\n"; }
  if ($transgenic{$strain}) { print EXP "Transgene\t\"$transgenic{$strain}\"\n"; }
  print EXP "Remark\t\"Strain: $strain\"\n";
  print EXP "Remark\t\"From Author: $strain_comments\"\n\n";
} # while (<IN>)
close (IN) or die "Cannot close $expr_file : $!";
