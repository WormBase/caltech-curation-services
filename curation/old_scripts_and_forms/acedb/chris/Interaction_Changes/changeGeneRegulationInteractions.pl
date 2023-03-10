#!/usr/bin/perl

# map  Mapping_files/Gene_reg_Regulator_gene_Regulated_gene_Mappings(WS228).txt  according to
# Change_instruction_files/Gene_regulation_data_changes_for_new_Interaction_model.txt
# and output to screen.  2012 02 10
#
# Allow two genes by having a 4th column in the Transgene mapping file.  2012 02 22
#
# Use manually generated file that maps grg_name to grg_intid to change the headers.  2012 02 24
#
# Gene_reg_to_Antibody_text_Mappings.txt has inconsistent doublequotes in the second column,
# try mapping both ways.  2012 02 28
#
# Some changes to  Antibody  to  Antibody_remark  and  Antibody_info  to  Antibody  2012 04 19

use strict;

my %geneRegGenes;
my %map;
my %grgNameToIntID;


my $infile = 'Mapping_files/Gene_reg_Regulator_gene_Regulated_gene_Mappings.txt';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\"/) { $line =~ s/\"//g; }
  my ($grg, $wbg, $wbg2) = split/\t/, $line;
  if ($wbg) {  $geneRegGenes{$grg}{$wbg}++;  }
  if ($wbg2) { $geneRegGenes{$grg}{$wbg2}++; }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

$infile = 'Mapping_files/Gene_reg_to_Antibody_info_to_Gene_Mappings.txt';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\"/) { $line =~ s/\"//g; }
  my ($grg, $ant, $wbg, $junk) = split/\t/, $line;
  if ($wbg) { 
    if ($geneRegGenes{$grg}{$wbg}) {
      $map{ati}{$grg}{$ant} = $wbg; } }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

# not using att mapping anymore
# $infile = 'Mapping_files/Gene_reg_to_Antibody_text_Mappings.txt';
# open(IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   if ($line =~ m/\"/) { $line =~ s/\"//g; }
#   my ($grg, $att, $genes) = split/\t/, $line;
#   my @genes = ();
#   if ($genes eq 'NA') { next; }
#     elsif ($genes =~ m/,/) { $genes =~ s/"//g; $genes =~ s/ //g; @genes = split/,/, $genes; }
#     elsif ($genes =~ m/WBGene/) { push @genes, $genes; }
#     else { print "ERR unmapped gene $line\n"; }
#   $map{att}{$grg}{$att} = \@genes;
#   if ($att =~ m/^\"/) { $att =~ s/^\"//; } if ($att =~ m/\"$/) { $att =~ s/\"$//; }
#   $map{att}{$grg}{$att} = \@genes;
# } # while (my $line = <IN>)
# close(IN) or die "Cannot close $infile : $!";

$infile = 'Mapping_files/Gene_reg_to_Expr_pattern_to_Gene_Mappings.txt';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\"/) { $line =~ s/\"//g; }
  my ($grg, $exp, $wbg, $junk) = split/\t/, $line;
  if ($wbg) {
    if ($geneRegGenes{$grg}{$wbg}) {
      $map{exp}{$grg}{$exp} = $wbg; } }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

$infile = 'Mapping_files/Gene_reg_to_Transgene_to_Gene_Mappings.txt';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\"/) { $line =~ s/\"//g; }
  my ($grg, $tra, $wbg, $wbg2, $junk) = split/\t/, $line;
  if ($wbg2) {
    if ($geneRegGenes{$grg}{$wbg2}) {
      $map{tra}{$grg}{$tra}{$wbg2}++; } }
  if ($wbg) {
    if ($geneRegGenes{$grg}{$wbg}) {
      $map{tra}{$grg}{$tra}{$wbg}++; } }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

$infile = 'Mapping_files/Gene_reg_to_Variation_to_Gene_Mappings.txt';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\"/) { $line =~ s/\"//g; }
  my ($grg, $var, $wbg, $junk) = split/\t/, $line;
  if ($wbg) { 
    if ($geneRegGenes{$grg}{$wbg}) {
      $map{var}{$grg}{$var} = $wbg; } }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

$infile = 'Mapping_files/grgNameToIntID';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\"/) { $line =~ s/\"//g; }
  my ($grg, $intid) = split/\t/, $line;
  $grgNameToIntID{$grg} = $intid;
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";


$/ = "";
$infile = 'Object_source_files/WS232_Gene_regulation_objects.ace';
open(IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;
while (my $object = <IN>) {
  my (@lines) = split/\n/, $object;
  my $header = shift @lines;
  if ($header =~ m/\\/) { $header =~ s/\\//g; }		# strip backslashes from object names
  my ($objName) = $header =~ m/\"(.*?)\"/;
  next unless $objName;
  my $cleanObjName = $objName;
  my $newheader = $header;
  $newheader =~ s/Gene_regulation/Interaction/;
  unless ($grgNameToIntID{$objName}) { print "ERR $objName NO MATCH\n"; }
  $newheader =~ s/$objName/$grgNameToIntID{$objName}/;
  print "$newheader\n";
  foreach my $line (@lines) { 
    my ($tag, @rest) = split/\t/, $line;
    my $rest = join"\t", @rest;
    if ($tag eq 'Summary') { $line = "Interaction_summary\t" . $rest; }
    elsif ($tag eq 'RNAi') { $line = "Interaction_RNAi\t" . $rest; }
    elsif ($tag eq 'Trans_regulator_gene') { $line = "Interactor_overlapping_gene\t" . $rest . "\tTrans_regulator"; }
    elsif ($tag eq 'Trans_regulated_gene') { $line = "Interactor_overlapping_gene\t" . $rest . "\tTrans_regulated"; }
    elsif ($tag eq 'Trans_regulator_seq') { $line = "Interactor_overlapping_CDS\t" . $rest . "\tTrans_regulator"; }
    elsif ($tag eq 'Trans_regulated_seq') { $line = "Interactor_overlapping_CDS\t" . $rest . "\tTrans_regulated"; }
    elsif ($tag eq 'Cis_regulator_seq') { $line = "Sequence_interactor\t" . $rest . "\tCis_regulator"; }
    elsif ($tag eq 'Cis_regulated_seq') { $line = "Interactor_overlapping_CDS\t" . $rest . "\tCis_regulated"; }
    elsif ($tag eq 'Associated_feature') { $line = "Interaction_associated_feature\t" . $rest; }
    elsif ($tag eq 'Reference') { $line = "Paper\t" . $rest; }
    elsif ($tag eq 'Antibody') {
      if ( $line =~ m/\"(.*?)\"/ ) {				# if there's text 
          my ($attInfo) = $line =~ m/\"(.*?)\"/;
          $line = "Antibody_remark\t\"$attInfo\"\n"; }
#         { my ($attInfo) = $line =~ m/\"(.*?)\"/;
#           if ( $map{att}{$objName}{$attInfo} ) { 	# if the text matches a gene for that grg object
#               my $genesref = $map{att}{$objName}{$attInfo};
#               my @genes = @$genesref; $line = '';
#               foreach my $gene (@genes) {
#                 $line .= "Interactor_overlapping_gene\t\"$gene\"\tAntibody\t\"$attInfo\"\n"; } }
#             else { $line = "Remark\t\"Antibody used: $attInfo\"\n"; } }	# if it doesn't match add a remark
#         else { $line = "ERR no Antibody data"; } 	# chris no longer wants error line
      $line .= "Antibody"; }						# always add an Antibody line
    elsif ($tag eq 'Antibody_info') {
      if ( $line =~ m/\"(.*?)\"/ ) {				# if there's text 
          my ($antInfo) = $line =~ m/\"(.*?)\"/;
          if ( $map{ati}{$objName}{$antInfo} ) { 	# if the text matches a gene for that grg object
              $line = "Interactor_overlapping_gene\t\"$map{ati}{$objName}{$antInfo}\"\tAntibody\t\"$antInfo\"\n"; }
            else { $line = "Remark\t\"Antibody used: $antInfo\"\n"; } }	# if it doesn't match add a remark
        else { $line = ""; }						# if there's no antibody info text, just add an Antibody line
      $line .= "Antibody"; }						# if there's no antibody info text, just add an Antibody line
    elsif ($tag eq 'Expr_pattern') {
      if ( $line =~ m/\"(.*?)\"/ ) {				# if there's text 
          my ($expInfo) = $line =~ m/\"(.*?)\"/;
          if ( $map{exp}{$objName}{$expInfo} ) { 	# if the text matches a gene for that grg object
              $line = "Interactor_overlapping_gene\t\"$map{exp}{$objName}{$expInfo}\"\tExpr_pattern\t\"$expInfo\""; }
            else { $line = "Remark\t\"Expr_pattern: $expInfo\""; } }	# if it doesn't match add a remark
        else { $line = "ERR no Expr_pattern data"; } }				# if there's no antibody info text, just add an Antibody line
    elsif ($tag eq 'Transgene') {
      if ( $line =~ m/\"(.*?)\"/ ) {				# if there's text 
          my ($traInfo) = $line =~ m/\"(.*?)\"/;
          if ( $map{tra}{$objName}{$traInfo} ) { 	# if the text matches a gene for that grg object
              foreach my $wbg (sort keys %{ $map{tra}{$objName}{$traInfo} }) {
#                 $line = "Interactor_overlapping_gene\t\"$map{tra}{$objName}{$traInfo}\"\tTransgene\t\"$traInfo\"";
                $line = "Interactor_overlapping_gene\t\"$wbg\"\tTransgene\t\"$traInfo\""; } }
            else { $line = "Remark\t\"Transgene: $traInfo\""; } }	# if it doesn't match add a remark
        else { $line = "ERR no Transgene data"; } }				# if there's no antibody info text, just add an Antibody line
    elsif ($tag eq 'Allele') {
      if ( $line =~ m/\"(.*?)\"/ ) {				# if there's text 
          my ($varInfo) = $line =~ m/\"(.*?)\"/;
          if ( $map{var}{$objName}{$varInfo} ) { 	# if the text matches a gene for that grg object
              $line = "Interactor_overlapping_gene\t\"$map{var}{$objName}{$varInfo}\"\tVariation\t\"$varInfo\""; }
            else { $line = "Remark\t\"Variation: $varInfo\""; } }	# if it doesn't match add a remark
        else { 
          # $line = "ERR no Variation data"; 
          $line = ''; } 							# Chris says to not output these  2012 02 10
      }				# if there's no antibody info text, just add an Antibody line
    if ($line) { print "$line\n"; }					# sometimes a line won't be printed by making it blank
  } # foreach my $line (@lines)
  print "Regulatory\n\n";
} # while (my $line = <IN>)
$/ = "\n";


__END__

Gene_regulation : "cgc1664_mec-3.a"
Summary  "UNC-86 and MEC-3 are required for mec-3 expression. u3m3 deletions abolishes the binding of mec-3 5' flanking region CS3 with UNC-86 and MEC-3 proteins. u3m3(-) animals showed no LacZ expression."
Reporter_gene    "[mec-3(m)::lacZ]. Site-directed mutagenesis on mec-3 5' flanking region that are critical for binding with MEC-3 and UNC-86, and transforming animals with the mutagenized DNA."
Trans_regulator_gene     "WBGene00006818"
Trans_regulator_gene     "WBGene00003167"
Trans_regulated_gene     "WBGene00003167"
Reference        "WBPaper00001664"

Gene_regulation : "cgc1664_mec-3.b"
Summary  "UNC-86 is required for mec-3 expression. A two nucleotide change at position u2 greatly reduced the UNC-86 binding but not MEC-3 binding, at CS2 site of 5' flanking region of mec-3. Young L2 larva have normal beta-gal activity in PLML, PLMR, PVD and PVM, greatly reduced activity in FLPL, FLPR, and essentially no activity in ALML, ALMR and AVM. At later stages (L3 to adult), beta-gal expression in the usual mec-3-expressing cells gradually disppeared."
Reporter_gene    "[mec-3(m)::lacZ]. Site-directed mutagenesis on mec-3 5' flanking region that are critical for binding with MEC-3 and UNC-86, and transforming animals with the mutagenized DNA."
Trans_regulator_gene     "WBGene00006818"
Trans_regulated_gene     "WBGene00003167"
Positive_regulate        Life_stage "L2 larva"
Positive_regulate        Life_stage "L3 larva"
Positive_regulate        Life_stage "L4 larva"
Positive_regulate        Life_stage "adult"
Positive_regulate        Anatomy_term "WBbt:0003832"
Positive_regulate        Anatomy_term "WBbt:0003953"
Positive_regulate        Anatomy_term "WBbt:0003954"
Positive_regulate        Anatomy_term "WBbt:0004086"
Positive_regulate        Anatomy_term "WBbt:0004103"
Positive_regulate        Anatomy_term "WBbt:0004104"
Positive_regulate        Anatomy_term "WBbt:0004797"
Positive_regulate        Anatomy_term "WBbt:0004798"
Positive_regulate        Anatomy_term "WBbt:0006831"
Reference        "WBPaper00001664"



-rw-r--r-- 1 acedb acedb 210252 2012-02-10 13:55 Gene_reg_Regulator_gene_Regulated_gene_Mappings(WS228).txt
-rw-r--r-- 1 acedb acedb  22596 2012-02-10 13:55 Gene_reg_to_Antibody_info_to_Gene_Mappings(WS228).txt
-rw-r--r-- 1 acedb acedb   6861 2012-02-10 13:55 Gene_reg_to_Antibody_text_Mappings(WS228).txt
-rw-r--r-- 1 acedb acedb  87924 2012-02-10 13:55 Gene_reg_to_Expr_pattern_to_Gene_Mappings(WS228).txt
-rw-r--r-- 1 acedb acedb  30105 2012-02-10 13:55 Gene_reg_to_Transgene_to_Gene_Mappings(WS228).txt
-rw-r--r-- 1 acedb acedb 176973 2012-02-10 13:55 Gene_reg_to_Variation_to_Gene_Mappings(WS228).txt

# my @samples = qw( [cgc1358]:hlh-1 Expr2286 kyIs235 WBVar00296485 WBVar00000643 );
# my @mapTypes = qw( ant exp tra var );
# foreach my $name (@samples) {
#   my $mapped = '';
#   foreach my $type (@mapTypes) {
#     if ($map{$type}{$name}) { $mapped = "$type : $name : $map{$type}{$name}\n"; }
#   } # foreach my $type (@mapTypes)
#   if ($mapped) { print $mapped; } else { print "No map for $name\n"; }
# } # foreach my $name (@samples)
