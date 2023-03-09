#!/usr/bin/perl

use strict;
use Jex;

my %hash;

unless ($ARGV[0]) { die "You must enter an input file ./rnai_curation_stat.pl input.ace\n"; }
my $infile = $ARGV[0];
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my $rnai = '';
  if ($entry =~ m/^RNAi : \"(WBRNAi\d+)\"/) { $rnai = $1; $hash{rnai}{$rnai}++; }
  if ($entry =~ m/Phenotype.*?\"(WBPhenotype\d+)\"/) { 
    my (@phens) = $entry =~ m/Phenotype.*?\"(WBPhenotype\d+)\"/g;
    foreach my $phen (@phens) { $hash{conn}{$rnai}{$phen}++; } }
}
close (IN) or die "Cannot close $infile : $!";

my $obj_count; my $conn_count;
foreach my $rnai ( keys %{ $hash{rnai} } ) { $obj_count++; }
foreach my $rnai ( keys %{ $hash{conn} } ) { 
  foreach my $phen ( keys %{ $hash{conn}{$rnai} } ) { $conn_count++; } }

my $body = '';
$body .= "There are $obj_count new RNAi objects.\n";
$body .= "There are $conn_count new RNAi-phenotype connections.\n";

my $user = 'rnai_curation_stats';
# my $email = 'pws@its.caltech.edu, garys@its.caltech.edu';
my $email = 'azurebrd@tazendra.caltech.edu';
my $subject = 'RNAi curation stats';
&mailer($user, $email, $subject, $body);



__END__

//RNAi submission WBPaper00028766 Fri Oct  5 13:52:54 2007
//From:		Gary Schindelman
//E-mail:	garys@caltech.edu


///////////////////////////////////////////////////////////////
//	Paper Information: WBRNAi00066002
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066002"
Reference	"WBPaper00028766"
Laboratory	"FR"
Author	"Takacs-Vellai K"
Author	"Vellai T"
Author	"Chen EB"
Author	"Zhang Y"
Author	"Guerry F"
Author	"Stern MJ"
Author	"Muller F"
Date	2006-09-30
Method	"RNAi"


///////////////////////////////////////////////////////////////
//	Probe Information: WBRNAi00066002 probe_1
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066002"
Homol_homol	"F31E3:RNAi"
Sequence	"yk219d9"
DNA_text	"aaaagagttcgcaattccctggttcgagcatctcttcctacctgaatttccaactcgaagtgttatcaacgagaaaagttttgtggtaggaactattttcattcacttatttttttttcaaaatgaaatataatttcagttagaaagacagcttggtcgtggttcatttggtgttgtttattgtgccagtgcaattcatgattcagagaggaagtttgctatcaaaatgcaagaaaaaagggagatcatttcaaaacgagccgttttacaggtcaaacgagaagctagtatacaggtttgccagcaagacgttacatccgatcattcacattttcagcgtcttcttccttctcatccattcatcgccagaacttattctacgtggcagacacgtactcatctctattctttactacagtacccaactggttcaactggtgacttgttttcagtatggaggcaacggggatctctttcagaagctgctattaggttgattggagcagagttagcatcagctattggtaatataataacggttatgtaagaaattcggtgttttattttcagatttcctacaccagaatgacgtgatctatcgagatgtaaaactggaaaatgtagttctagatcaatggggtcacgccttgctaattgattttggtttggcaaaaaagctgaaacaaggttctagtaccggaacaatatgtggaacattacaatacatgtcacctgacgtggcatctggtggaacatattctcattatgttgattggtggtcattaggtgtactcttgcatattttattaactggaatatatccatatccaaattcagaagccacacatcatgctaatttaaagtaagttcacatcacagattttagaataatctcttatgcttttcagattcattgactacagtactcctataggatgttcacgtgaattcgccaaccttatggatagagtgagttcagaaactcggaaaaaaacgttaatatcattagtttcagatgttagcagtttccataacccatcgtttatgctcattcactgttcttcacgcccatccatttttccgatccattgacttttcgaaattggaacaaaaagattacacacctgcagcggaaattggtaacgctgaatatgatacttatcacaaaagtgaggacgcgttggatgatgctttgttcaaggaaaattatgatgtgagttgcggaagaaatgtaatttttgcagtattgccggttttttggtaatctgccaaattattgaaaaattgaactttttgagaaactcggtgcattcttgcatgtttaaattctacaatttttgaatatttattcatcagttaaatataaaactgtgaaaatattttttcgatcgacttccaatattatgaaaggtgaaaactgagtaattgccattttgacagcaaattaaaatttcactatctgacctcaaaaactaaatatgcaaatcaaatattatatttcagttcgaccgttttgactatttcaatgatcgattctaatgtgatgcatatcgatttgagggttggaatgaaaacgagctctttttattgctccgtcactctcttttactctgtgataaaataccctgttaccatcatcatcaattcacttttctgtatgatacgggcgctaataaatattttacaacatgcttgatttcccacagatttcgtttaaacatatatcataaccatcaaatgggatgttctacatgtagaacaaattatactttcttccaataaatacagaattaaaaatttcctaaataaatatgaactgttttgggattttttacacttattttcaaggctgcgataagaacggtcaaactttcataaaaaattgaaatatctggaaaagtggagatacaagcagtactcagtaataccctgaagcttattttatttcctagttaggtgttaaatatttcttaagctaagaatttcgtaaatcgatttatttataaatctagctatgtaaacatagtcatggagatatgcctacattcctacgcattcgatgcagctgagggtttggcagatttcctttaacttgatgatcgtaaccttttcaactccttcgcaaaaaaatagggtaaccgtaaatgcataaatctacccttatctaggtaccatcaaatagctcacgcataagataggaatctgacaatagtatgaaaacattactgagaagcttactttcggtcttcagtgtagaaacataaataccttcctttgggccgtctacgtctaatttgtcgttaggccgttactcggtattcaaaacgagttacacccacggtaggcacgcagatgggcctttccgtaactgagtggaagatactcgatttagcacttaatttactgtatattttctgattcaaattctagaccactatgtatttcttcaactcatcaatcattccccgcttctcactttaaaaaaaaaataataataacaatatggttgagttgacccaaagccgtaacaacaacggtcatttccatcggctggctgtgtggtcgagggaaggatccattacaatcgcaataaatgcggattcaaagcgcaaaatccctgcgtctcccttcaattgttcaatgtctaatagttcttctggcagatgatacgtcctcacaacatctggcctttccttccttccactgctacaaacacacatagcaaaggtcatctcctgatgtctctaggtctcttcgagtaaatgaagagggtctttctctgttgtttcgaaggaaccgctacgctgacacgcgacgcacgtcaaatgtcaacttgtcttcgttcgacgtctccccccaacgtcgttttcgtgtatatccatcttttttcgagacgtttttattccgtttttgcggaagggtgttgttttgagttattgatccctttgtttttcgacaagaaccgtttgatgtaaaagttaatatcaagtgacagatcctgatggatcctgtcagattatggtaggatagtatactttttatagtgagtgaactgacactaggttggcaagagtatacctatctacacatttgctcaaacaaaaataaccttactacaataatgggaagcgctagaaattgtgcaaccaccgacctaacacatcttattttacgcacaattttggctccattacggcctgcccaaatattcgtggtataatagaatctatgtctattccatacattatggctatactaaaatgtcgaaataagattttgaattctatttttttaatcaaaagttattttactattcagttttcacttatcaaatgtttatcataataaactatcttcaaatctgactttctttgaaatttcgatcctaccacatgaggcaatgtatttttgggaaaattcacaccagatcttccgaacacctactaattcaaggtcatttcctcttctttgtttctaaatttctccttcaaaactttcagtttttaattcaaatttttaacttttttttagaatctaattattaatttcagaaaatggtggggacacacccagccaatctcagcgagcttttagacgccgtcttgaaaataaatgagcaaactttggatgataatgacagtgcaaagtgagttttttgtttttagtttttgagatttggtttttgaaagaaattcagaagacgagccataatttttggagatctagaaagttgttttcaattttagtaatagtttgtgaaaatattcaaaaatgataaaatttttgagaacatctccacagtatattttccaaaacctaaaattttatttctttcagaaaacaagagctacaatgtcatcccatgcgtcaagccctattcgatgttctctgtgaaacaaaagaaaaaacagtactgacagttcgtaatcaagtggacgaaactccagaagatcctcaattaatgcgacttgataatatgttagtggcggaaggcgttgcaggaccagataaaggaggttcattaggaagtgatgcaagtggaggtgatcaggctgattatagacaaaagcttcaccagattcgagttttgtacaatgaagagctgagaaagtatgaggaggtacgctattttcaaaagcaaaaactcagatctgactcaacattgtttaattgaaatttagttttttttgtgagtgttcgcgaaaaaaaaggtccgaataaaaactaaaaatattttttcaggcttgtaacgaattcacgcaacacgtgaggtctctgctgaaggatcaatcacaagttcgcccaatagcacataaggaaatcgaacgaatggtttatataatccaacgaaaattcaatggaattcaagttcaactcaaacaatccacatgtgaggccgtcatgatcctcagaagcaggttccttgatgcccgccgtaaacggcgaaacttttcgaaacaagcgacagaagtgcttaatgaatatttctatggacacctctcaaatccatacccatcagaagaagcaaaagaagatctcgcaaggcagtgcaatattacagtatctcaggtatcattataaaatttattcgttttttttgcatagtacctatcgaaggctctatataataagtcttgctcaaattttttagaatagctattaatagttctattcatttcggacgtaatgaaactatgaattattctgaatgttcacaactttgtcatattttttgtggcagtcgaaaatgataatgaaaatgtttagaaaataattttttaaaaacattgtcacaccttaaacttttttttcaaaatgttcactttcaggtttccaattggtttggaaataaacgaattcgctacaagaaaaatatggcaaaagctcaagaggaagccagtatgtatgctgccaaaaagaatgctcatgtaacattaggaggtatggctggaaatccatacggaatgcttcctggtgctgcagccgctgctggcctattaaatccctacaatcctatgaatattcccggacaagacacattgcatatgggaatgccaccctttgatttatcggtatataatccacaattggtgagtactattagtctttacagtttcaattttaaatactctctttccagatggccgcagctcaataccaacaacaaatggacaatgctgataaaaattcataaataatactcagccagttggtaatattgaaatctcaaccaatcatcccatctaccatcacacaatcttgctttcttctcaatcgaattcccgatcaatctcgttctggttattctgttagaccatcgacttttttgtatttttctttccaaccagcttgtcctttcttgaattttttacttgcacagacaca"	"yk219d9"

Homol_data : "F31E3:RNAi"
Sequence	"F31E3"
RNAi_homol	"WBRNAi00066002"	"RNAi_primary"	100	13856	19240	1	5385

Sequence : "F31E3"
Homol_data	"F31E3:RNAi"	1	22896


///////////////////////////////////////////////////////////////
//	Experimental Information: WBRNAi00066002
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066002"
Strain	"N2"
Delivered_by	"Bacterial_feeding"
Phenotype	"WBPhenotype0000220"
Phenotype	"WBPhenotype0000700"
Species	"Caenorhabditis elegans"
Phenotype	"WBPhenotype0000220"	Remark	"failure to execute secondary vulval cell fate"
Phenotype	"WBPhenotype0000700"	Range	10
Phenotype	"WBPhenotype0000700"	Low


///////////////////////////////////////////////////////////////
//	Paper Information: WBRNAi00066003
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066003"
Reference	"WBPaper00028766"
Laboratory	"FR"
Author	"Takacs-Vellai K"
Author	"Vellai T"
Author	"Chen EB"
Author	"Zhang Y"
Author	"Guerry F"
Author	"Stern MJ"
Author	"Muller F"
Date	2006-09-30
Method	"RNAi"


///////////////////////////////////////////////////////////////
//	Probe Information: WBRNAi00066003 probe_1
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066003"
Homol_homol	"C07H6:RNAi"
DNA_text	"atgaccacatcaacatcaccgtcatccacagatgcaccgagagctacagctcctgaatcaagctcttcgtcttcatcctcatcttcttcatcatcatccacatcttctgtgggtgcatctggaattccatcatcttctgaattatcgagtacaattggatatgatccaatgacagcgtctgctgcactttctgctcattttggaagttattatgatccgactagttcttctcaaattgcttcatattttgcctcaagtcaaggactgggaggtcctcaatatccaatactcggagatcagtcactatgctataatccatcagtaacaagtacccatcacgactggaagcacctggaaggagacgatgatgatgataaggatgatgacaagaaaggcatcagtggtgatgacgatgatatggataagaattcaggcggtgcagtgtatccatggatgacacgtgttcattcaactacaggaggttcacgcggcgagaagcgacaacgaacagcatacacaaggaatcaagtattagagctggaaaaggaatttcatacacacaaatatctgacgaggaagcgtagaattgaagtagctcattcattgatgcttaccgaaagacaagtcaaaatttggtttcaaaatcgacgaatgaagcacaaaaaagaaaataaggataaaccaatgacacctccgatgatgccatttggtgcaaatctaccattcggtccattccggttcccacttttcaatcaattctag"	"probe_1:C07H6"

Homol_data : "C07H6:RNAi"
Sequence	"C07H6"
RNAi_homol	"WBRNAi00066003"	"RNAi_primary"	100	45375	45461	762	676
RNAi_homol	"WBRNAi00066003"	"RNAi_primary"	100	45995	46045	675	625
RNAi_homol	"WBRNAi00066003"	"RNAi_primary"	100	46090	46235	624	479
RNAi_homol	"WBRNAi00066003"	"RNAi_primary"	100	48916	49093	478	301
RNAi_homol	"WBRNAi00066003"	"RNAi_primary"	100	50660	50959	300	1

Sequence : "C07H6"
Homol_data	"C07H6:RNAi"	1	55169


///////////////////////////////////////////////////////////////
//	Experimental Information: WBRNAi00066003
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066003"
Delivered_by	"Bacterial_feeding"
Phenotype	"WBPhenotype0000216"
Species	"Caenorhabditis elegans"
Phenotype	"WBPhenotype0000216"	NOT
Phenotype	"WBPhenotype0000216"	Remark	"observed only 1 anchor cell, as in wildtype"


///////////////////////////////////////////////////////////////
//	Paper Information: WBRNAi00066004
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066004"
Reference	"WBPaper00028766"
Laboratory	"FR"
Author	"Takacs-Vellai K"
Author	"Vellai T"
Author	"Chen EB"
Author	"Zhang Y"
Author	"Guerry F"
Author	"Stern MJ"
Author	"Muller F"
Date	2006-09-30
Method	"RNAi"


///////////////////////////////////////////////////////////////
//	Probe Information: WBRNAi00066004 probe_1
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066004"
Homol_homol	"C08C3:RNAi"
DNA_text	"atgagcatgtatcctggatggacaggcgacgattcgtactgggcgggcgccggcacaacggcttcttctcaatccgcatcatccggcacatctgcttcagcatcgtctagtgctgccgctgctgctgctgccaataatttgaaaacctacgaactctacaatcacacctacatgaacaatatgaaacatatgcttgctgccggttggatggataattcatcaaatccattcgcctataacccacttcaagcaacatctgcaaattttggtgaaactagaacttcaatgccagcaatctcgcaaccagtatttccatggatgaagatgggcggtgcaaaaggtggagaatcaaaacgcactcgtcagacatattcaagaagtcaaacattggaattagaaaaggaatttcattatcacaaatacttgactaggaaacgtcggcaagaaatttcagaaacattgcatttgactgaaagacaagtaaaaatctggttccaaaatcgtcgtatgaaacacaaaaaagaggcaaaaggagaaggtggaagcaatgaatcagatgaagaatcaaatcaagatgagcaaaatgaacaacattcttcttga"	"probe_1:C08C3"

Homol_data : "C08C3:RNAi"
Sequence	"C08C3"
RNAi_homol	"WBRNAi00066004"	"RNAi_primary"	100	2273	2395	603	481
RNAi_homol	"WBRNAi00066004"	"RNAi_primary"	100	3395	3543	480	332
RNAi_homol	"WBRNAi00066004"	"RNAi_primary"	100	7108	7211	331	228
RNAi_homol	"WBRNAi00066004"	"RNAi_primary"	100	7897	7979	227	145
RNAi_homol	"WBRNAi00066004"	"RNAi_primary"	100	8249	8392	144	1

Sequence : "C08C3"
Homol_data	"C08C3:RNAi"	1	44025


///////////////////////////////////////////////////////////////
//	Experimental Information: WBRNAi00066004
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066004"
Genotype	"CDH-3::GFP"
Delivered_by	"Bacterial_feeding"
Phenotype	"WBPhenotype0000216"
Species	"Caenorhabditis elegans"
Phenotype	"WBPhenotype0000216"	Range	5
Phenotype	"WBPhenotype0000216"	Low
Phenotype	"WBPhenotype0000216"	Remark	"two anchor cells observed"


///////////////////////////////////////////////////////////////
//	Paper Information: WBRNAi00066005
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066005"
Reference	"WBPaper00028766"
Laboratory	"FR"
Author	"Takacs-Vellai K"
Author	"Vellai T"
Author	"Chen EB"
Author	"Zhang Y"
Author	"Guerry F"
Author	"Stern MJ"
Author	"Muller F"
Date	2006-09-30
Method	"RNAi"


///////////////////////////////////////////////////////////////
//	Probe Information: WBRNAi00066005 probe_1
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066005"
Homol_homol	"C07H6:RNAi"
DNA_text	"atgaccacatcaacatcaccgtcatccacagatgcaccgagagctacagctcctgaatcaagctcttcgtcttcatcctcatcttcttcatcatcatccacatcttctgtgggtgcatctggaattccatcatcttctgaattatcgagtacaattggatatgatccaatgacagcgtctgctgcactttctgctcattttggaagttattatgatccgactagttcttctcaaattgcttcatattttgcctcaagtcaaggactgggaggtcctcaatatccaatactcggagatcagtcactatgctataatccatcagtaacaagtacccatcacgactggaagcacctggaaggagacgatgatgatgataaggatgatgacaagaaaggcatcagtggtgatgacgatgatatggataagaattcaggcggtgcagtgtatccatggatgacacgtgttcattcaactacaggaggttcacgcggcgagaagcgacaacgaacagcatacacaaggaatcaagtattagagctggaaaaggaatttcatacacacaaatatctgacgaggaagcgtagaattgaagtagctcattcattgatgcttaccgaaagacaagtcaaaatttggtttcaaaatcgacgaatgaagcacaaaaaagaaaataaggataaaccaatgacacctccgatgatgccatttggtgcaaatctaccattcggtccattccggttcccacttttcaatcaattctag"	"probe_1:C07H6"

Homol_data : "C07H6:RNAi"
Sequence	"C07H6"
RNAi_homol	"WBRNAi00066005"	"RNAi_primary"	100	45375	45461	762	676
RNAi_homol	"WBRNAi00066005"	"RNAi_primary"	100	45995	46045	675	625
RNAi_homol	"WBRNAi00066005"	"RNAi_primary"	100	46090	46235	624	479
RNAi_homol	"WBRNAi00066005"	"RNAi_primary"	100	48916	49093	478	301
RNAi_homol	"WBRNAi00066005"	"RNAi_primary"	100	50660	50959	300	1

Sequence : "C07H6"
Homol_data	"C07H6:RNAi"	1	55169


///////////////////////////////////////////////////////////////
//	Experimental Information: WBRNAi00066005
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066005"
Genotype	"lin-12(n137)"
Delivered_by	"Bacterial_feeding"
Phenotype	"WBPhenotype0000269"
Species	"Caenorhabditis elegans"
Phenotype	"WBPhenotype0000269"	Remark	"suppresses the Multivulva phenotype of lin-12(n137) gain-of-function mutants from 100 percent Muv to 33 percent"


///////////////////////////////////////////////////////////////
//	Paper Information: WBRNAi00066006
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066006"
Reference	"WBPaper00028766"
Laboratory	"FR"
Author	"Takacs-Vellai K"
Author	"Vellai T"
Author	"Chen EB"
Author	"Zhang Y"
Author	"Guerry F"
Author	"Stern MJ"
Author	"Muller F"
Date	2006-09-30
Method	"RNAi"


///////////////////////////////////////////////////////////////
//	Probe Information: WBRNAi00066006 probe_1
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066006"
Homol_homol	"F31E3:RNAi"
Sequence	"yk219d9"
DNA_text	"aaaagagttcgcaattccctggttcgagcatctcttcctacctgaatttccaactcgaagtgttatcaacgagaaaagttttgtggtaggaactattttcattcacttatttttttttcaaaatgaaatataatttcagttagaaagacagcttggtcgtggttcatttggtgttgtttattgtgccagtgcaattcatgattcagagaggaagtttgctatcaaaatgcaagaaaaaagggagatcatttcaaaacgagccgttttacaggtcaaacgagaagctagtatacaggtttgccagcaagacgttacatccgatcattcacattttcagcgtcttcttccttctcatccattcatcgccagaacttattctacgtggcagacacgtactcatctctattctttactacagtacccaactggttcaactggtgacttgttttcagtatggaggcaacggggatctctttcagaagctgctattaggttgattggagcagagttagcatcagctattggtaatataataacggttatgtaagaaattcggtgttttattttcagatttcctacaccagaatgacgtgatctatcgagatgtaaaactggaaaatgtagttctagatcaatggggtcacgccttgctaattgattttggtttggcaaaaaagctgaaacaaggttctagtaccggaacaatatgtggaacattacaatacatgtcacctgacgtggcatctggtggaacatattctcattatgttgattggtggtcattaggtgtactcttgcatattttattaactggaatatatccatatccaaattcagaagccacacatcatgctaatttaaagtaagttcacatcacagattttagaataatctcttatgcttttcagattcattgactacagtactcctataggatgttcacgtgaattcgccaaccttatggatagagtgagttcagaaactcggaaaaaaacgttaatatcattagtttcagatgttagcagtttccataacccatcgtttatgctcattcactgttcttcacgcccatccatttttccgatccattgacttttcgaaattggaacaaaaagattacacacctgcagcggaaattggtaacgctgaatatgatacttatcacaaaagtgaggacgcgttggatgatgctttgttcaaggaaaattatgatgtgagttgcggaagaaatgtaatttttgcagtattgccggttttttggtaatctgccaaattattgaaaaattgaactttttgagaaactcggtgcattcttgcatgtttaaattctacaatttttgaatatttattcatcagttaaatataaaactgtgaaaatattttttcgatcgacttccaatattatgaaaggtgaaaactgagtaattgccattttgacagcaaattaaaatttcactatctgacctcaaaaactaaatatgcaaatcaaatattatatttcagttcgaccgttttgactatttcaatgatcgattctaatgtgatgcatatcgatttgagggttggaatgaaaacgagctctttttattgctccgtcactctcttttactctgtgataaaataccctgttaccatcatcatcaattcacttttctgtatgatacgggcgctaataaatattttacaacatgcttgatttcccacagatttcgtttaaacatatatcataaccatcaaatgggatgttctacatgtagaacaaattatactttcttccaataaatacagaattaaaaatttcctaaataaatatgaactgttttgggattttttacacttattttcaaggctgcgataagaacggtcaaactttcataaaaaattgaaatatctggaaaagtggagatacaagcagtactcagtaataccctgaagcttattttatttcctagttaggtgttaaatatttcttaagctaagaatttcgtaaatcgatttatttataaatctagctatgtaaacatagtcatggagatatgcctacattcctacgcattcgatgcagctgagggtttggcagatttcctttaacttgatgatcgtaaccttttcaactccttcgcaaaaaaatagggtaaccgtaaatgcataaatctacccttatctaggtaccatcaaatagctcacgcataagataggaatctgacaatagtatgaaaacattactgagaagcttactttcggtcttcagtgtagaaacataaataccttcctttgggccgtctacgtctaatttgtcgttaggccgttactcggtattcaaaacgagttacacccacggtaggcacgcagatgggcctttccgtaactgagtggaagatactcgatttagcacttaatttactgtatattttctgattcaaattctagaccactatgtatttcttcaactcatcaatcattccccgcttctcactttaaaaaaaaaataataataacaatatggttgagttgacccaaagccgtaacaacaacggtcatttccatcggctggctgtgtggtcgagggaaggatccattacaatcgcaataaatgcggattcaaagcgcaaaatccctgcgtctcccttcaattgttcaatgtctaatagttcttctggcagatgatacgtcctcacaacatctggcctttccttccttccactgctacaaacacacatagcaaaggtcatctcctgatgtctctaggtctcttcgagtaaatgaagagggtctttctctgttgtttcgaaggaaccgctacgctgacacgcgacgcacgtcaaatgtcaacttgtcttcgttcgacgtctccccccaacgtcgttttcgtgtatatccatcttttttcgagacgtttttattccgtttttgcggaagggtgttgttttgagttattgatccctttgtttttcgacaagaaccgtttgatgtaaaagttaatatcaagtgacagatcctgatggatcctgtcagattatggtaggatagtatactttttatagtgagtgaactgacactaggttggcaagagtatacctatctacacatttgctcaaacaaaaataaccttactacaataatgggaagcgctagaaattgtgcaaccaccgacctaacacatcttattttacgcacaattttggctccattacggcctgcccaaatattcgtggtataatagaatctatgtctattccatacattatggctatactaaaatgtcgaaataagattttgaattctatttttttaatcaaaagttattttactattcagttttcacttatcaaatgtttatcataataaactatcttcaaatctgactttctttgaaatttcgatcctaccacatgaggcaatgtatttttgggaaaattcacaccagatcttccgaacacctactaattcaaggtcatttcctcttctttgtttctaaatttctccttcaaaactttcagtttttaattcaaatttttaacttttttttagaatctaattattaatttcagaaaatggtggggacacacccagccaatctcagcgagcttttagacgccgtcttgaaaataaatgagcaaactttggatgataatgacagtgcaaagtgagttttttgtttttagtttttgagatttggtttttgaaagaaattcagaagacgagccataatttttggagatctagaaagttgttttcaattttagtaatagtttgtgaaaatattcaaaaatgataaaatttttgagaacatctccacagtatattttccaaaacctaaaattttatttctttcagaaaacaagagctacaatgtcatcccatgcgtcaagccctattcgatgttctctgtgaaacaaaagaaaaaacagtactgacagttcgtaatcaagtggacgaaactccagaagatcctcaattaatgcgacttgataatatgttagtggcggaaggcgttgcaggaccagataaaggaggttcattaggaagtgatgcaagtggaggtgatcaggctgattatagacaaaagcttcaccagattcgagttttgtacaatgaagagctgagaaagtatgaggaggtacgctattttcaaaagcaaaaactcagatctgactcaacattgtttaattgaaatttagttttttttgtgagtgttcgcgaaaaaaaaggtccgaataaaaactaaaaatattttttcaggcttgtaacgaattcacgcaacacgtgaggtctctgctgaaggatcaatcacaagttcgcccaatagcacataaggaaatcgaacgaatggtttatataatccaacgaaaattcaatggaattcaagttcaactcaaacaatccacatgtgaggccgtcatgatcctcagaagcaggttccttgatgcccgccgtaaacggcgaaacttttcgaaacaagcgacagaagtgcttaatgaatatttctatggacacctctcaaatccatacccatcagaagaagcaaaagaagatctcgcaaggcagtgcaatattacagtatctcaggtatcattataaaatttattcgttttttttgcatagtacctatcgaaggctctatataataagtcttgctcaaattttttagaatagctattaatagttctattcatttcggacgtaatgaaactatgaattattctgaatgttcacaactttgtcatattttttgtggcagtcgaaaatgataatgaaaatgtttagaaaataattttttaaaaacattgtcacaccttaaacttttttttcaaaatgttcactttcaggtttccaattggtttggaaataaacgaattcgctacaagaaaaatatggcaaaagctcaagaggaagccagtatgtatgctgccaaaaagaatgctcatgtaacattaggaggtatggctggaaatccatacggaatgcttcctggtgctgcagccgctgctggcctattaaatccctacaatcctatgaatattcccggacaagacacattgcatatgggaatgccaccctttgatttatcggtatataatccacaattggtgagtactattagtctttacagtttcaattttaaatactctctttccagatggccgcagctcaataccaacaacaaatggacaatgctgataaaaattcataaataatactcagccagttggtaatattgaaatctcaaccaatcatcccatctaccatcacacaatcttgctttcttctcaatcgaattcccgatcaatctcgttctggttattctgttagaccatcgacttttttgtatttttctttccaaccagcttgtcctttcttgaattttttacttgcacagacaca"	"yk219d9"

Homol_data : "F31E3:RNAi"
Sequence	"F31E3"
RNAi_homol	"WBRNAi00066006"	"RNAi_primary"	100	13856	19240	1	5385

Sequence : "F31E3"
Homol_data	"F31E3:RNAi"	1	22896


///////////////////////////////////////////////////////////////
//	Experimental Information: WBRNAi00066006
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066006"
Strain	"GS956"
Delivered_by	"Bacterial_feeding"
Phenotype	"WBPhenotype0001278"
Species	"Caenorhabditis elegans"
Gene_regulation	"WBPaper00028766_lin-12.a"


///////////////////////////////////////////////////////////////
//	Paper Information: WBRNAi00066007
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066007"
Reference	"WBPaper00028766"
Laboratory	"FR"
Author	"Takacs-Vellai K"
Author	"Vellai T"
Author	"Chen EB"
Author	"Zhang Y"
Author	"Guerry F"
Author	"Stern MJ"
Author	"Muller F"
Date	2006-09-30
Method	"RNAi"


///////////////////////////////////////////////////////////////
//	Probe Information: WBRNAi00066007 probe_1
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066007"
Homol_homol	"C07H6:RNAi"
DNA_text	"atgaccacatcaacatcaccgtcatccacagatgcaccgagagctacagctcctgaatcaagctcttcgtcttcatcctcatcttcttcatcatcatccacatcttctgtgggtgcatctggaattccatcatcttctgaattatcgagtacaattggatatgatccaatgacagcgtctgctgcactttctgctcattttggaagttattatgatccgactagttcttctcaaattgcttcatattttgcctcaagtcaaggactgggaggtcctcaatatccaatactcggagatcagtcactatgctataatccatcagtaacaagtacccatcacgactggaagcacctggaaggagacgatgatgatgataaggatgatgacaagaaaggcatcagtggtgatgacgatgatatggataagaattcaggcggtgcagtgtatccatggatgacacgtgttcattcaactacaggaggttcacgcggcgagaagcgacaacgaacagcatacacaaggaatcaagtattagagctggaaaaggaatttcatacacacaaatatctgacgaggaagcgtagaattgaagtagctcattcattgatgcttaccgaaagacaagtcaaaatttggtttcaaaatcgacgaatgaagcacaaaaaagaaaataaggataaaccaatgacacctccgatgatgccatttggtgcaaatctaccattcggtccattccggttcccacttttcaatcaattctag"	"probe_1:C07H6"

Homol_data : "C07H6:RNAi"
Sequence	"C07H6"
RNAi_homol	"WBRNAi00066007"	"RNAi_primary"	100	45375	45461	762	676
RNAi_homol	"WBRNAi00066007"	"RNAi_primary"	100	45995	46045	675	625
RNAi_homol	"WBRNAi00066007"	"RNAi_primary"	100	46090	46235	624	479
RNAi_homol	"WBRNAi00066007"	"RNAi_primary"	100	48916	49093	478	301
RNAi_homol	"WBRNAi00066007"	"RNAi_primary"	100	50660	50959	300	1

Sequence : "C07H6"
Homol_data	"C07H6:RNAi"	1	55169


///////////////////////////////////////////////////////////////
//	Experimental Information: WBRNAi00066007
///////////////////////////////////////////////////////////////

RNAi : "WBRNAi00066007"
Strain	"GS956"
Delivered_by	"Bacterial_feeding"
Phenotype	"WBPhenotype0001278"
Species	"Caenorhabditis elegans"
Gene_regulation	"WBPaper00028766_lin-12.b"


