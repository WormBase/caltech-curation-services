#!/usr/bin/perl

# instructions
# https://docs.google.com/spreadsheets/d/1DE1Ba3XPd0L2yXYwSq2rY1cmE79VrvDNqCV1Fr-_tS4/edit#gid=0

use strict;
use diagnostics;

my %interactorType;
$interactorType{'TABTAB'}{'any'}                                               = '-';
$interactorType{'TABTABDiverging'}{'any'}                                      = '-';
$interactorType{'TABAll_suppressingTAB'}{'Effector'}                           = 'suppressor';
$interactorType{'TABAll_suppressingTAB'}{'Affected'}                           = 'suppressed';
$interactorType{'TABAll_suppressingTAB'}{'Non_directional'}                    = '-';
$interactorType{'TABEnhancingTAB'}{'Effector'}                                 = 'enhancer';
$interactorType{'TABEnhancingTAB'}{'Affected'}                                 = 'enhanced';
$interactorType{'TABEnhancingTAB'}{'Non_directional'}                          = '-';
$interactorType{'TABMaskingTAB'}{'Effector'}                                   = 'epistatic';
$interactorType{'TABMaskingTAB'}{'Affected'}                                   = 'hypostatic';
$interactorType{'TABMaskingTAB'}{'Non_directional'}                            = '-';
$interactorType{'TABSub_suppressingTAB'}{'Effector'}                           = 'suppressor';
$interactorType{'TABSub_suppressingTAB'}{'Affected'}                           = 'suppressed';
$interactorType{'TABSub_suppressingTAB'}{'Non_directional'}                    = '-';
$interactorType{'TABSuper_suppressingTAB'}{'Effector'}                         = 'suppressor';
$interactorType{'TABSuper_suppressingTAB'}{'Affected'}                         = 'suppressed';
$interactorType{'TABSuppressingTAB'}{'Effector'}                               = 'suppressor';
$interactorType{'TABSuppressingTAB'}{'Affected'}                               = 'suppressed';
$interactorType{'TABSuppressingTAB'}{'Non_directional'}                        = '-';
$interactorType{'A_phenotypicTABTABDiverging'}{'any'}                          = '-';
$interactorType{'Cis_phenotypicTABAll_suppressingTAB'}{'Non_directional'}      = '-';
$interactorType{'Cis_phenotypicTABCo_suppressingTAB'}{'Non_directional'}       = '-';
$interactorType{'Cis_phenotypicTABEnhancingTAB'}{'any'}                        = '-';
$interactorType{'Cis_phenotypicTABEnhancingTABDiverging'}{'any'}               = '-';
$interactorType{'Cis_phenotypicTABInter_suppressingTAB'}{'any'}                = '-';
$interactorType{'Cis_phenotypicTABMaskingTAB'}{'Effector'}                     = 'epistatic';
$interactorType{'Cis_phenotypicTABMaskingTAB'}{'Affected'}                     = 'hypostatic';
$interactorType{'Cis_phenotypicTABMaskingTAB'}{'Non_directional'}              = '-';
$interactorType{'Cis_phenotypicTABSemi_suppressingTAB'}{'Effector'}            = 'epistatic';
$interactorType{'Cis_phenotypicTABSemi_suppressingTAB'}{'Affected'}            = 'hypostatic';
$interactorType{'Cis_phenotypicTABSuper_suppressingTAB'}{'any'}                = '-';
$interactorType{'Cis_phenotypicTABSuppressingTAB'}{'any'}                      = '-';
$interactorType{'Iso_phenotypicTABMaskingTAB'}{'any'}                          = '-';
$interactorType{'Mono_phenotypicTABAll_suppressingTAB'}{'Effector'}            = 'suppressor';
$interactorType{'Mono_phenotypicTABAll_suppressingTAB'}{'Affected'}            = 'suppressed';
$interactorType{'Mono_phenotypicTABEnhancingTAB'}{'Effector'}                  = 'enhancer';
$interactorType{'Mono_phenotypicTABEnhancingTAB'}{'Affected'}                  = 'enhanced';
$interactorType{'Mono_phenotypicTABEnhancingTABDiverging'}{'Effector'}         = 'enhancer';
$interactorType{'Mono_phenotypicTABEnhancingTABDiverging'}{'Affected'}         = 'enhanced';
$interactorType{'Mono_phenotypicTABSub_suppressingTAB'}{'Effector'}            = 'suppressor';
$interactorType{'Mono_phenotypicTABSub_suppressingTAB'}{'Affected'}            = 'suppressed';
$interactorType{'Mono_phenotypicTABSuppressingTAB'}{'Effector'}                = 'suppressor';
$interactorType{'Mono_phenotypicTABSuppressingTAB'}{'Affected'}                = 'suppressed';
$interactorType{'Trans_phenotypicTABAll_suppressingTAB'}{'any'}                = '-';
$interactorType{'Trans_phenotypicTABEnhancingTAB'}{'Effector'}                 = 'enhancer';
$interactorType{'Trans_phenotypicTABEnhancingTAB'}{'Affected'}                 = 'enhanced';
$interactorType{'Trans_phenotypicTABMaskingTAB'}{'Effector'}                   = 'epistatic';
$interactorType{'Trans_phenotypicTABMaskingTAB'}{'Affected'}                   = 'hypostatic';
$interactorType{'Trans_phenotypicTABSuppressingTAB'}{'any'}                    = '-';

my %modToPsi; 
$modToPsi{'TABTAB'} = 'psi-mi:"MI:0208"(genetic interaction)';
$modToPsi{'TABTABDiverging'} = 'psi-mi:"MI:0794"(synthetic)';
$modToPsi{'TABTABNeutral'} = 'skip';
$modToPsi{'TABAll_suppressingTAB'} = 'psi-mi:"MI:1290"(suppression (complete))';
$modToPsi{'TABEnhancingTAB'} = 'psi-mi:"MI:0794"(enhancement)';
$modToPsi{'TABMaskingTAB'} = 'psi-mi:"MI:0797"(epistasis)';
$modToPsi{'TABSub_suppressingTAB'} = 'psi-mi:"MI:1291"(suppression (partial))';
$modToPsi{'TABSuper_suppressingTAB'} = 'psi-mi:"MI:1286"(over-suppression)';
$modToPsi{'TABSuppressingTAB'} = 'psi-mi:"MI:0796"(suppression)';
$modToPsi{'A_phenotypicTABTABDiverging'} = 'psi-mi:"MI:0794"(synthetic)';
$modToPsi{'A_phenotypicTABTABNeutral'} = 'skip';
$modToPsi{'Cis_phenotypicTABTABNeutral'} = 'skip';
$modToPsi{'Cis_phenotypicTABAll_suppressingTAB'} = 'psi-mi:"MI:1281"(mutual suppression (complete))';
$modToPsi{'Cis_phenotypicTABCo_suppressingTAB'} = 'psi-mi:"MI:1282"(mutual suppression (partial))';
$modToPsi{'Cis_phenotypicTABEnhancingTAB'} = 'psi-mi:"MI:1278"(mutual enhancement)';
$modToPsi{'Cis_phenotypicTABEnhancingTABDiverging'} = 'psi-mi:"MI:1278"(mutual enhancement)';
$modToPsi{'Cis_phenotypicTABEnhancingTABNeutral'} = 'skip';
$modToPsi{'Cis_phenotypicTABInter_suppressingTAB'} = 'psi-mi:"MI:1283"(suppression-enhancement)';
$modToPsi{'Cis_phenotypicTABMaskingTAB'} = 'psi-mi:"MI:1273"(maximal epistasis)';
$modToPsi{'Cis_phenotypicTABSemi_suppressingTAB'} = 'psi-mi:"MI:1274"(minimal epistasis)';
$modToPsi{'Cis_phenotypicTABSuper_suppressingTAB'} = 'psi-mi:"MI:1287"(mutual over-suppression)';
$modToPsi{'Cis_phenotypicTABSuppressingTAB'} = 'psi-mi:"MI:1280"(mutual suppression)';
$modToPsi{'Iso_phenotypicTABMaskingTAB'} = 'psi-mi:"MI:0795"(asynthetic)';
$modToPsi{'Mono_phenotypicTABTABNeutral'} = 'skip';
$modToPsi{'Mono_phenotypicTABAll_suppressingTAB'} = 'psi-mi:"MI:1293"(unilateral suppression (complete))';
$modToPsi{'Mono_phenotypicTABEnhancingTAB'} = 'psi-mi:"MI:1279"(unilateral enhancement)';
$modToPsi{'Mono_phenotypicTABEnhancingTABDiverging'} = 'psi-mi:"MI:1279"(unilateral enhancement)';
$modToPsi{'Mono_phenotypicTABSub_suppressingTAB'} = 'psi-mi:"MI:1294"(unilateral suppression (partial))';
$modToPsi{'Mono_phenotypicTABSuppressingTAB'} = 'psi-mi:"MI:1292"(unilateral suppression)';
$modToPsi{'Trans_phenotypicTABAll_suppressingTAB'} = 'psi-mi:"MI:1281"(mutual suppression (complete))';
$modToPsi{'Trans_phenotypicTABAll_suppressingTABNeutral'} = 'skip';
$modToPsi{'Trans_phenotypicTABEnhancingTAB'} = 'psi-mi:"MI:1288"(over-suppression-enhancement)';
$modToPsi{'Trans_phenotypicTABMaskingTAB'} = 'psi-mi:"MI:1285"(opposing epistasis)';
$modToPsi{'Trans_phenotypicTABSuppressingTAB'} = 'psi-mi:"MI:1280"(mutual suppression)';

my $errorfile = 'errorfile';
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";

# my $dir = 'WS273_Genetic_interactions_Oct_2019/';
my $dir = 'WS273_Genetic_interactions_Nov_2019/';
my $gene_names_file           = $dir . 'WS273_genetic_interaction_gene_interactors.txt';
my $pap_map_file              = $dir . 'WS273_genetic_interaction_papers_and_PMIDs.txt';
my $int_gene_type_file        = $dir . 'WS273_genetic_interactions_and_interactors.txt';
my $int_phen_file             = $dir . 'WS273_genetic_interactions_and_phenotypes.txt';
my $int_module_pap_file       = $dir . 'WS273_genetic_interactions_and_types_and_papers.txt';
my $int_var_file              = $dir . 'WS273_genetic_interactions_and_variations.txt';
my $var_gene_file             = $dir . 'WS273_variation_interactors_and_genes.txt';

my $valid_gi_int_other_file   = $dir . 'WS273_GIs_2genes_no_other_mol_rearr.txt';               # interactions that are valid for GI
my $valid_gi_int_rnai_file    = $dir . 'WS273_GIs_RNAis_and_RNAi_genes.txt';
my $valid_int_transgene_file  = $dir . 'WS273_interactions_with_transgene_interactors.txt';



# my $testInt = 'WBInteraction000000820';		# for testing
my $testInt = '';		# for testing

my %intGene;			# int -> gene -> countPerGene	to keep track of all gene connections to an interaction across any files

my %intValidGiNoOther;
my $infile = $valid_gi_int_other_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  $intValidGiNoOther{$line}++;
}
close (IN) or die "Cannot close $infile : $!";

my %intValidGiRnai;
$infile = $valid_gi_int_rnai_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($int, $rnai, $gene) = split/\t/, $line;
  next unless ($int && $rnai && $gene);
  $intValidGiRnai{$int}{$gene}{$rnai}++;
  $intGene{$int}{$gene}++;
}
close (IN) or die "Cannot close $infile : $!";

my %intValidTransgene;
$infile = $valid_int_transgene_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($int, $gene, $transgene) = split/\t/, $line;
  $intValidTransgene{$int}{$gene}{$transgene}++;
}
close (IN) or die "Cannot close $infile : $!";


my %varGene;
$infile = $var_gene_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($var, $wbg) = split/\t/, $line;
#   $var =~ s/\"//g; $wbg =~ s/\"//g;
  if ($varGene{$var}) { $varGene{$var} = 'skip'; }
    else { $varGene{$var} = $wbg; }
}
close (IN) or die "Cannot close $infile : $!";

my %intVar;
$infile = $int_var_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($int, $var) = split/\t/, $line;
if ($int eq $testInt) { print qq(INT $int LINE $line\n); }
#   $var =~ s/\"//g; $int =~ s/\"//g;
  $intVar{$int}{$var}++;
}
close (IN) or die "Cannot close $infile : $!";

my %intPhen;
$infile = $int_phen_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($int, $phen) = split/\t/, $line;
#   $phen =~ s/\"//g; $int =~ s/\"//g;
  $intPhen{$int}{$phen}++;
}
close (IN) or die "Cannot close $infile : $!";

my %ginSeq; my %ginName;
$infile = $gene_names_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($wbg, $seq, $name) = split/\t/, $line;
#   $wbg =~ s/\"//g; $seq =~ s/\"//g; $name =~ s/\"//g;
  $ginSeq{$wbg} = $seq;
  $ginName{$wbg} = $name;
}
close (IN) or die "Cannot close $infile : $!";

my %papPmid;
$infile = $pap_map_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($pap, $pmid) = split/\t/, $line;
  $papPmid{$pap} = $pmid;
}
close (IN) or die "Cannot close $infile : $!";

my %intGeneType;
my %intSuppress;
$infile = $int_gene_type_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($int, $gene, $type, $species) = split/\t/, $line;
  if ($species eq 'Caenorhabditis elegans') { 
      $intGene{$int}{$gene}++;
      if ($intGeneType{$int}{$gene}) { 				# if int-gene already has a connection, skip interaction if it has multiple types
          if ($intGeneType{$int}{$gene} ne $type) { 
            print ERR qq(File $infile : $int $gene has types $type and $intGeneType{$int}{$gene}\n); 
            $intSuppress{$int}++; } }
        else { $intGeneType{$int}{$gene} = $type; } }
    else { $intSuppress{$int}++; }						# skip interactions that refer to non-elegans genes
}
close (IN) or die "Cannot close $infile : $!";

$infile = $int_module_pap_file;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  my ($int, $type, $mod1, $mod2, $mod3, $pap, $brief) = split/\t/, $line;
  next unless $pap;
  next if ($intSuppress{$int});
  if ($mod3 eq 'Neutral') { 
#     print ERR qq(Neutral mod3 in $line\n); 
    next; }
  my $key = $mod1 . 'TAB' . $mod2 . 'TAB' . $mod3;
  unless ($modToPsi{$key}) { print ERR qq($key does not map to psi-mi\n); next; }
  my @tab;
  for (0 .. 41) { push @tab, '-'; }	# initialize tabs
  my $psi = $modToPsi{$key}; $tab[11] = $psi;
  my $ginCount = scalar keys %{ $intGene{$int} };
  if ($ginCount > 2) { 
#     print ERR qq($int has more than 2 genes\n); 
    next; }
  my ($gene1, $gene2) = sort keys %{ $intGeneType{$int} };
  unless ($gene2) { 
#     print ERR qq($int does not have a second gene\n); 
    next; }
  my $type1 = $intGeneType{$int}{$gene1};
  my $type2 = $intGeneType{$int}{$gene2};
  if (($type1 eq 'Affected') && ($type2 eq 'Effector')) { 1; }
    elsif (($type2 eq 'Affected') && ($type1 eq 'Effector')) { ($gene2, $gene1) = ($gene1, $gene2); ($type2, $type1) = ($type1, $type2); }
  $tab[0] = 'wormbase:' . $gene1; $tab[1] = 'wormbase:' . $gene2;
  my @gin1Name = (); my @gin2Name = ();
  if ($ginName{$gene1}) { push @gin1Name, 'wormbase:' . $ginName{$gene1} . '(public_name)';    }
  if ($ginSeq{$gene1})  { push @gin1Name, 'wormbase:' . $ginSeq{$gene1}  . '(sequence_name)';  }
  if ($ginName{$gene2}) { push @gin2Name, 'wormbase:' . $ginName{$gene2} . '(public_name)';    }
  if ($ginSeq{$gene2})  { push @gin2Name, 'wormbase:' . $ginSeq{$gene2}  . '(sequence_name)';  }
  if (scalar @gin1Name > 0) { $tab[4] = join"|", @gin1Name; }
  if (scalar @gin2Name > 0) { $tab[5] = join"|", @gin2Name; }
  $tab[6] = 'psi-mi:"MI:0254"(genetic interference)';
  if ($brief =~ m/^\s+/) { $brief =~ s/^\s+//; }
  if ($brief =~ m/^(.*?\))/) { $tab[7] = $1; }
    elsif ($brief =~ m/^(.*?et al)/) {       $tab[7] = $1; }
    elsif ($brief =~ m/^([\S+]\s[\S+])\s/) { $tab[7] = $1; }
    elsif ($brief =~ m/^([\S+])\s/) {        $tab[7] = $1; }
    elsif ($brief =~ m/^([\S+])/) {          $tab[7] = $1; }
    else { $tab[7] = '-'; print ERR qq($int brief citation does not match : $brief\n); }
  if ($papPmid{$pap}) { 
      $tab[8] = 'pubmed:' . $papPmid{$pap}; }
    else { 
#       $tab[8] = '-'; 
      next; }
  $tab[9]  = 'taxid:6239(caeel)|taxid:6239(Caenorhabditis elegans)';
  $tab[10] = 'taxid:6239(caeel)|taxid:6239(Caenorhabditis elegans)';
  $tab[12] = 'psi-mi:"MI:0487"(wormbase)';
  $tab[13] = 'wormbase:' . $int;
  unless ($interactorType{$key}) { print ERR qq($key does not map to interactorType\n); next; }
  if ($interactorType{$key}{'any'}) { 
      $tab[18] = $interactorType{$key}{'any'}; 
      $tab[19] = $interactorType{$key}{'any'}; }
    else {
      if ($interactorType{$key}{$type1}) { $tab[18] = $interactorType{$key}{$type1}; }
        else { print ERR qq(gene1 $gene1 has type $type1 does not map to interactorType\n); }
      if ($interactorType{$key}{$type2}) { $tab[19] = $interactorType{$key}{$type2}; }
        else { print ERR qq(gene2 $gene2 has type $type2 does not map to interactorType\n); }
    }
  $tab[20] = 'psi-mi:"MI:0250"(gene)';
  $tab[21] = 'psi-mi:"MI:0250"(gene)';
  my $skipBecauseVar = 0;
if ($int eq $testInt) { print qq(HERE $int\n); }
  my @tab25; my @tab26;
  if ($intVar{$int}) { 
if ($int eq $testInt) { 
  print qq(HERE $int\n); 
  foreach my $var (sort keys %{ $intVar{$int} }) { print qq($int VAR $var\n); }
}
    my $varCount = scalar keys %{ $intVar{$int} };
    if ($varCount > 2) { $skipBecauseVar++; }
    foreach my $var (sort keys %{ $intVar{$int} }) {
      my $varGene = $varGene{$var};
if ($int eq $testInt) { 
  print qq(VAR $var VG $varGene\n); 
}
      if ($varGene eq 'skip') { $skipBecauseVar++; }
      if ($varGene eq $gene1) { push @tab25, qq(wormbase:$var); }
      if ($varGene eq $gene2) { push @tab26, qq(wormbase:$var); } } }
  next if ($skipBecauseVar);

  unless ($intValidGiNoOther{$int}) {
    print ERR qq($int not in $valid_gi_int_other_file\n);
    next; }
  if ($intValidGiRnai{$int}{$gene1})    { push @tab25, qq(wormbase:rnai);      }
  if ($intValidGiRnai{$int}{$gene2})    { push @tab26, qq(wormbase:rnai);      }
  if ($intValidTransgene{$int}{$gene1}) { push @tab25, qq(wormbase:transgene); }
  if ($intValidTransgene{$int}{$gene2}) { push @tab26, qq(wormbase:transgene); }
  if (scalar keys @tab25 > 1) { print ERR qq(too many types in column 24 $int $gene1 @tab25\n); }
    elsif ($tab25[0]) { $tab[25] = $tab25[0]; }
  if (scalar keys @tab26 > 1) { print ERR qq(too many types in column 25 $int $gene2 @tab26\n); }
    elsif ($tab26[0]) { $tab[26] = $tab26[0]; }
#   $intValidGiNoOther{$line}++;
#   $intValidGiRnai{$int}{$gene}{$rnai}++;
#   $intValidTransgene{$int}{$gene}{$transgene}++;

  my (@phens) = sort keys %{ $intPhen{$int} };
  if (scalar @phens > 0) { $tab[27] = join"|", @phens; }

  my $line = join"\t", @tab;
  print qq($line\n);
}
close (IN) or die "Cannot close $infile : $!";

close (ERR) or die "Cannot close $errorfile : $!";

__END__



AQL_queries_for_genetic_interactions_Oct_14_2019.txt

WS273_genetic_interaction_gene_interactors.txt
gene	sequence_name	public_name

WS273_genetic_interaction_papers_and_PMIDs.txt
wbpaperIDs	pubmedIDs

WS273_genetic_interactions_and_interactors.txt
wbinteractionID	wbgene	interactor_type	(non_directional|effector|affected)
see 'interactor type mapping' tab in spreadsheet
https://docs.google.com/spreadsheets/d/1DE1Ba3XPd0L2yXYwSq2rY1cmE79VrvDNqCV1Fr-_tS4/edit#gid=0
also use modules

WS273_genetic_interactions_and_phenotypes.txt
wbinteractionID	wbphenotypeID	phenotype_name

WS273_genetic_interactions_and_types_and_papers.txt
wbinteractionID	interaction_type	module1	module2	module3	wbpaperId	briefCitation
see 'interaction type mapping' tab in spreadsheet
ignore interaction_type, use modules and mapping to generate psi-mitab column12

WS273_genetic_interactions_and_variations.txt
wbinteractionID	wbvariation

WS273_variation_interactors_and_genes.txt
wbvariation	wbgene


