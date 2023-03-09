#!/usr/bin/perl

# Parse files for Wen according to UBCExprTemplate.txt (x_ray should be x-ray)
# 2004 10 05
#
# Re-export comma-separated stuff into tab-delimited, also create a new file
# for Cell_group tags.  2005 06 15
#
# Add some more text to expr.ace remark strain_comments
# Replace . with gene_name if gene_locus is .
# Change stuff with Partial and suppress data that only says ``unidentified
# cells'' in expc.ace   2005 06 17

use strict; 
use diagnostics;

my $expr_file = 'expprfls2.txt';		# 2 is tab-delimited, original is comma-delimited
my $strain_file = 'Strains2.txt';
my $picture_file = 'PictureNames.txt';

my $transgene_outfile = 'transgene.ace';
my $expr_outfile = 'expr.ace';
my $exc_outfile = 'expc.ace';

open (EXP, ">$expr_outfile") or die "Cannot create $expr_outfile : $!";
open (EXC, ">$exc_outfile") or die "Cannot create $exc_outfile : $!";
open (TRA, ">$transgene_outfile") or die "Cannot create $transgene_outfile : $!";

my %transgenic;
my %pictures;

open (IN, "<$picture_file") or die "Cannot open $picture_file : $!";
while (my $line = <IN>) {
  chomp $line;
  if ( $line =~ m/^(.*?_.*?)_.*$/ ) {
    my ($gene_strain) = $line =~ m/^(.*?_.*?)_.*$/;
    $pictures{$gene_strain} = $line; }
} # while (<IN>)
close (IN) or die "Cannot close $picture_file : $!";

open (IN, "<$strain_file") or die "Cannot open $strain_file : $!";
my $skip = <IN>;
while (<IN>) {
  chomp;
  my ($strain_name, $transgenic_name, $mutagen, $outcrossed, $gene_name, $gene_locus, @junk) = split"\t", $_;
#   my ($strain_name, $transgenic_name, $mutagen, $outcrossed, $gene_name, $gene_locus, @junk) = split",", $_;
  if ($transgenic{$strain_name}) { print "ERR $strain_name has multiple $transgenic_name, $transgenic{$strain_name}\n"; }
  $transgenic{$strain_name} = $transgenic_name;
  print TRA "Transgene : \"$transgenic_name\"\n";
  unless ($gene_locus) { $gene_locus = $gene_name; }
  if ($gene_locus eq '.') { $gene_locus = $gene_name; }
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
  if ($_ =~ m/\"/) { $_ =~ s/\"//g; }		# filter out quotes from all text  2005 06 20
  my ($gene, $locus, $strain, $primA, $primB, $location, $strain_comments, $embryo, $larval, $adult, $image) = split"\t", $_;
#   my ($gene, $locus, $strain, $primA, $primB, $location, $strain_comments, $embryo, $larval, $adult, $image) = split",", $_;
  if ($strain_comments =~ m//) { $strain_comments =~ s///g; }
  print EXP "Expr_pattern : \"Expr$count\"\n";
  print EXP "CDS\t\"$gene\"\n";
  unless ($locus) { $locus = $gene; }
  if ($locus eq '.') { $locus = $gene; }
  print EXP "Reporter_gene\t\"[${locus}::gfp] transcriptional fusion. PCR products were amplified using primer A: 5' [$primA] 3' and primer B 5' [$primB] 3'.\"\n";
  my @pattern = ();
  my @life_stage = ();
  if ($embryo =~ m/"/) { $embryo =~ s/"//g; }
  if ($larval =~ m/"/) { $larval =~ s/"//g; }
  if ($adult =~ m/"/) { $adult =~ s/"//g; }
  if ($embryo) { push @pattern, "Pattern\t\"Embryo Expression: $embryo\"\n"; }
  if ($embryo) { push @life_stage, "Life_stage\t\"embryo\"\n"; }
  if ($larval) { push @pattern, "Pattern\t\"Larval Expression: $larval\"\n"; }
  if ($larval) { push @life_stage, "Life_stage\t\"larva\"\n"; }
  if ($adult) { push @pattern, "Pattern\t\"Adult Expression: $adult\"\n"; }
  if ($adult) { push @life_stage, "Life_stage\t\"adult\"\n"; }
  foreach my $line (@pattern) { print EXP $line; }
  foreach my $line (@life_stage) { print EXP $line; }
#   if ($embryo) { print EXP "Pattern\t\"Embryo Expression: $embryo\"\n"; }
#   if ($embryo) { print EXP "Life_stage\t\"embryo\"\n"; }
#   if ($larval) { print EXP "Pattern\t\"Larval Expression: $larval\"\n"; }
#   if ($larval) { print EXP "Life_stage\t\"larva\"\n"; }
#   if ($adult) { print EXP "Pattern\t\"Adult Expression: $adult\"\n"; }
#   if ($adult) { print EXP "Life_stage\t\"adult\"\n"; }
  if ($transgenic{$strain}) { print EXP "Transgene\t\"$transgenic{$strain}\"\n"; }
  print EXP "Remark\t\"Strain: $strain\"\n";
  if ($strain_comments) {
    if ($strain_comments =~ m/"/) { $strain_comments =~ s/"//g; }
    unless ( ($strain_comments eq ' ') || ($strain_comments =~ m/No Comment/) ) {	# suppress empty comments
      print EXP "Remark\t\"Also expressed in (comments from author) :  $strain_comments\"\n"; } }
  my $gene_strain = $gene . '_' . $strain;
  if ($pictures{$gene_strain}) { print EXP "Picture\t\"$pictures{$gene_strain}\"\n"; }
  print EXP "\n";

#   if ($embryo) { print EXC "Cell_group\t\"$embryo\"\n"; }
#   if ($larval) { print EXC "Cell_group\t\"$larval\"\n"; }
#   if ($adult) { print EXC "Cell_group\t\"$adult\"\n"; }
  my %exc_lines = ();
  if ($embryo) { 
    my @lines = split/;/, $embryo;
    foreach my $line (@lines) {
# if ($count == 5122) { print "EMB $line\n"; }
      if ($line =~ m/^\s+/) { $line =~ s/^\s+//g; } if ($line =~ m/\s+$/) { $line =~ s/\s+$//g; }
      if ($line =~ m/\s*;/) { ($line =~ s/\s*;//) }
      if ($line =~ m/unidentified cells in (.*)/) {
        $line = "Cell_group\t\"$1\"\tPartial\t\"unidentified cells\""; }
      elsif ($line =~ m/intestine - posterior cells/) {
        $line = "Cell_group\t\"intestine\"\tPartial\t\"posterior cells\""; }
      elsif ($line =~ m/intestine - anterior cells/) {
        $line = "Cell_group\t\"intestine\"\tPartial\t\"anterior cells\""; }
      else { $line = "Cell_group\t\"$line\""; }
      if ($line =~ m/Cell_group\t\"unidentified cells/) { next; }
      $exc_lines{$line}++; } }
  if ($larval) { 
    my @lines = split/;/, $larval;
    foreach my $line (@lines) {
# if ($count == 5122) { print "LAR $line\n"; }
      if ($line =~ m/^\s+/) { $line =~ s/^\s+//g; } if ($line =~ m/\s+$/) { $line =~ s/\s+$//g; }
      if ($line =~ m/\s*;/) { ($line =~ s/\s*;//) }
      if ($line =~ m/unidentified cells in (.*)/) {
        $line = "Cell_group\t\"$1\"\tPartial\t\"unidentified cells\""; }
      elsif ($line =~ m/intestine - posterior cells/) {
        $line = "Cell_group\t\"intestine\"\tPartial\t\"posterior cells\""; }
      elsif ($line =~ m/intestine - anterior cells/) {
        $line = "Cell_group\t\"intestine\"\tPartial\t\"anterior cells\""; }
      else { $line = "Cell_group\t\"$line\""; }
      if ($line =~ m/Cell_group\t\"unidentified cells/) { next; }
      $exc_lines{$line}++; } }
  if ($adult) { 
    my @lines = split/;/, $adult;
    foreach my $line (@lines) {
# if ($count == 5122) { print "ADU $line\n"; }
      if ($line =~ m/^\s+/) { $line =~ s/^\s+//g; } if ($line =~ m/\s+$/) { $line =~ s/\s+$//g; }
      if ($line =~ m/\s*;/) { ($line =~ s/\s*;//) }
      if ($line =~ m/unidentified cells in (.*)/) {
        $line = "Cell_group\t\"$1\"\tPartial\t\"unidentified cells\""; }
      elsif ($line =~ m/intestine - posterior cells/) {
        $line = "Cell_group\t\"intestine\"\tPartial\t\"posterior cells\""; }
      elsif ($line =~ m/intestine - anterior cells/) {
        $line = "Cell_group\t\"intestine\"\tPartial\t\"anterior cells\""; }
      else { $line = "Cell_group\t\"$line\""; }
      if ($line =~ m/Cell_group\t\"unidentified cells/) { next; }
      $exc_lines{$line}++; } }
  if (%exc_lines) {
    print EXC "Expr_pattern : \"Expr$count\"\n";
    foreach my $line (sort keys %exc_lines) { 
      print EXC "$line\n"; }
    print EXC "\n"; }
} # while (<IN>)
close (IN) or die "Cannot close $expr_file : $!";

