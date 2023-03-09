#!/usr/bin/perl

# Parse files for Wen according to UBCExprTemplate.txt (x_ray should be x-ray)
# 2004 10 05
#
# Add Cell_group into a separate .ace file from embryo, larval, adult (minus
# unidentified)  Grab pictures and output from picture file.  2004 10 14
#
# Added Life_stage where appropriate for Wen.  2004 10 08

use strict; 
use diagnostics;

my $expr_file = 'expprfls.txt';
my $strain_file = 'strains.txt';
my $picture_file = 'PictureNames.txt';

my $transgene_outfile = 'transgene.ace';
my $expr_outfile = 'expr.ace';
my $expr2_outfile = 'expr2.ace';

open (EXP, ">$expr_outfile") or die "Cannot create $expr_outfile : $!";
open (EXT, ">$expr2_outfile") or die "Cannot create $expr2_outfile : $!";
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

my %picturenames;
open (IN, "<$picture_file") or die "Cannot open $picture_file : $!";
while (<IN>) {
  chomp;
  my ($key) = $_ =~ m/^(.*)_GFP/;
  push @{ $picturenames{$key} }, $_;
} # while (<IN>)
close (IN) or die "Cannot close $picture_file : $!";

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
  my %cell_group;
  if ($embryo) { 
    my @stuff = split"; ", $embryo;
    foreach (@stuff) { $cell_group{$_}++; }
    print EXP "Life_stage\t\"embryo\"\n";
    print EXP "Pattern\t\"Embryo Expression: $embryo\"\n"; }
  if ($larval) {
    my @stuff = split"; ", $larval;
    foreach (@stuff) { $cell_group{$_}++; }
    print EXP "Life_stage\t\"larva\"\n";
    print EXP "Pattern\t\"Larval Expression: $larval\"\n"; }
  if ($adult) {
    my @stuff = split"; ", $adult;
    foreach (@stuff) { $cell_group{$_}++; }
    print EXP "Life_stage\t\"adult\"\n";
    print EXP "Pattern\t\"Adult Expression: $adult\"\n"; }
  if ($transgenic{$strain}) { print EXP "Transgene\t\"$transgenic{$strain}\"\n"; }
  print EXP "Remark\t\"Strain: $strain\"\n";
  print EXP "Remark\t\"From Author: $strain_comments\"\n";
  my $key = $gene . '_' . $strain;
  if ($picturenames{$key}) { 
    foreach (@{ $picturenames{$key} }) { print EXP "Picture\t\"$_\"\n"; }
    delete $picturenames{$key}; }
  print EXP "\n";
  foreach my $cell_group (sort keys %cell_group) { 
    $cell_group =~ s/\s+/ /g; $cell_group =~ s/^\s//g; $cell_group =~ s/\s$//g; } 
  delete $cell_group{unidentified};
  if (keys %cell_group) { 
    print EXT "Expr_pattern : \"Expr$count\"\n";
    foreach my $cell_group (sort keys %cell_group) { print EXT "Cell_group\t\"$cell_group\"\n"; } }
    print EXT "\n";
} # while (<IN>)
foreach my $key (sort keys %picturenames) {
  print "ERR : These key doesn't have a matching entry in expprfls.txt $key\n"; }
close (IN) or die "Cannot close $expr_file : $!";
