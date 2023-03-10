#!/usr/bin/perl -w 

# parse the WS file with timestamps to make a mapping of RNAi objects to curators.  2012 03 23
#
# added second file with 8 objects that have no paper.  2012 03 26

use strict;
use diagnostics;

my @bad;
my %map;
my %curators;

my %toWBPerson;

$toWBPerson{"andrei"}   = 'WBPerson480';
$toWBPerson{"chris"}    = 'WBPerson2987';
$toWBPerson{"gary"}     = 'WBPerson557';
$toWBPerson{"igor"}     = 'WBPerson22';
$toWBPerson{"kimberly"} = 'WBPerson1843';
$toWBPerson{"raymond"}  = 'WBPerson363';
$toWBPerson{"wen"}      = 'WBPerson101';

$/ = "";
my @files = qw(WS231RNAiwithTimeStamp.ace RNAi_No_REF_withTimeStamp.ace);
foreach my $infile (@files) {
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $para = <IN>) {
    my ($id, $curator) = ('', '');
    next unless ($para =~ m/RNAi : \"(WBRNAi\d+)\"/);
    $id = $1;
    if ($para =~ m/Experiment\t \-O \"\d{4}\-\d{2}\-\d{2}_\d{2}:\d{2}:\d{2}_([a-z]+)\" /) { $curator = $1; $map{$id} = $toWBPerson{$curator}; push @{ $curators{$curator} }, $id; }
      else { push @bad, $para; }
  } # while (my $para = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@files)

if (scalar(@bad) > 0) { foreach my $bad (@bad) { print "ERR : $bad\n\n"; } }

foreach my $id (sort keys %map) { print "$id\t$map{$id}\n"; }

# foreach my $curator (sort keys %curators) {
#   my $ids = join", ", @{ $curators{$curator} };
#   print "$curator\n";
# #   print "$curator\t$ids\n";
# }




__END__


// data dumped from keyset display

RNAi : "WBRNAi00000145" -O "2001-08-07_08:04:39_lstein"
History_name	 -O "2004-12-05_11:10:25_igor" "KK:AH6.5" -O "2004-12-05_11:10:25_igor"
Homol	 -O "2010-04-30_17:10:26_gary" Homol_homol -O "2010-04-30_17:10:26_gary" "AH6:RNAi" -O "2010-04-30_17:10:26_gary"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" DNA_text -O "2005-01-22_12:55:26_raymond" "atatcagcccgattatgcataccagnggaaaggctacgactccaacgaaggtcaccctcaagcaacgaaatgtggctggttccatgatgtgcctctccaatactggacgcgatttanaggcaggaggtgatttcaaccatccggaaatcaatgaaaacgatttaccaccacacttganacggattcgcagaggcaatccacctgtaaccagaagtcgtccatctttcagtacgaaatggacatcagtggagaacctcggtctgcgaggacactattagggcgtactttaccactccanattgctcactcgtgtatcatttctgtacaaaagccatttcttctcaaattccaaaaatccatccatagacttacgctctgacctctatcacacaaatctctaatcaaaaggcttctaa" -O "2005-01-22_12:55:26_raymond" "BE228114" -O "2005-01-22_12:55:26_raymond"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" Sequence -O "2005-01-22_12:55:26_raymond" "BE228114" -O "2005-01-22_12:55:26_raymond"
Uniquely_mapped	 -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Laboratory -O "2004-12-05_11:10:25_igor" "KK" -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Piano F" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Schetter AJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Mangone M" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Stein LD" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Kemphues KJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Date -O "2004-12-05_11:10:25_igor" 2000-10-21 -O "2004-12-05_11:10:25_igor"
Supporting_data	 -O "2005-09-09_16:18:22_raymond" Movie -O "2005-09-09_16:18:22_raymond" "http:\/\/www.rnai.org\/movies\/OT\/sp12c2-1.mov" -O "2005-09-09_16:18:22_raymond"
Supporting_data	 -O "2005-09-09_16:18:22_raymond" Movie -O "2005-09-09_16:18:22_raymond" "http:\/\/www.rnai.org\/movies\/OT\/sp12c2-01.mov" -O "2005-09-09_16:18:22_raymond"
Supporting_data	 -O "2005-09-09_16:18:22_raymond" Movie -O "2005-09-09_16:18:22_raymond" "http:\/\/www.rnai.org\/movies\/OT\/sp12c2-101.mov" -O "2005-09-09_16:18:22_raymond"
Species	 -O "2010-08-26_16:14:33_gary" "Caenorhabditis elegans" -O "2010-08-26_16:14:33_gary"
Reference	 -O "2004-12-05_11:10:25_igor" "WBPaper00004540" -O "2004-12-05_11:10:25_igor"
Phenotype	 -O "2006-05-03_11:55:20_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Remark -O "2006-05-05_12:49:52_igor" "\% penetrance range" -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2006-05-03_11:55:20_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Penetrance -O "2006-05-05_12:49:52_igor" Range -O "2006-05-05_12:49:52_igor" 80 -O "2006-05-05_12:49:52_igor" 100 -O "2006-05-05_12:49:52_igor"
Remark	 -O "2004-12-05_11:10:25_igor" "Embryonic lethal\; AB or P1 spindle orientation aberrant" -O "2004-12-05_11:10:25_igor"
Method	 -O "2004-12-05_11:10:25_igor" "RNAi" -O "2004-12-05_11:10:25_igor"

RNAi : "WBRNAi00000146" -O "2001-08-07_08:04:39_lstein"
History_name	 -O "2004-12-05_11:10:25_igor" "KK:B0041.4" -O "2004-12-05_11:10:25_igor"
Homol	 -O "2010-04-30_17:10:26_gary" Homol_homol -O "2010-04-30_17:10:26_gary" "B0041:RNAi" -O "2010-04-30_17:10:26_gary"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" DNA_text -O "2005-01-22_12:55:26_raymond" "ccggatgggaaagctccgcaaccgtcaacacaagcagaagctcggaccagttgttatctacggacaagatgctgagtgcgctcgtgccttccgcaacatcccaggagtcgatgtcatgaatgttgagagactcaaccttctcaagctcgccccaggaggacatctcggacgtcttatcatctggaccgagtctgccttcaagaagcttgataccatctacggaaccaccgttgccaactcttctcaactcaagaagggatggtctgtcccactcccaatcatggccaactccgacttctcccgcatcatccgttccgaagaggtcgttaaggctatcagagctccaaagaagaacccagtgcttccaaaggtccaccgcaacccactcaagaagagaaccctcttgtacaagttgaacccatatgcttctatcctccgcanggcttcaaaggccaacgtgaanaaataagtattctgtgttgataaacttttttgttaatcaaaa" -O "2005-01-22_12:55:26_raymond" "BE228041" -O "2005-01-22_12:55:26_raymond"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" Sequence -O "2005-01-22_12:55:26_raymond" "BE228041" -O "2005-01-22_12:55:26_raymond"
Uniquely_mapped	 -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Laboratory -O "2004-12-05_11:10:25_igor" "KK" -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Piano F" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Schetter AJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Mangone M" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Stein LD" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Kemphues KJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Date -O "2004-12-05_11:10:25_igor" 2000-10-21 -O "2004-12-05_11:10:25_igor"
Species	 -O "2010-08-26_16:14:33_gary" "Caenorhabditis elegans" -O "2010-08-26_16:14:33_gary"
Reference	 -O "2004-12-05_11:10:25_igor" "WBPaper00004540" -O "2004-12-05_11:10:25_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Remark -O "2006-05-05_12:49:52_igor" "\% penetrance range" -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Penetrance -O "2006-05-05_12:49:52_igor" Range -O "2006-05-05_12:49:52_igor" 80 -O "2006-05-05_12:49:52_igor" 100 -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000689" -O "2006-05-05_12:49:52_igor"
Remark	 -O "2004-12-05_11:10:25_igor" "Embryonic lethal\; embryos arrest at different stages\; catastrophic one-cell arrest\; egg production ceases in injected animal." -O "2004-12-05_11:10:25_igor"
Method	 -O "2004-12-05_11:10:25_igor" "RNAi" -O "2004-12-05_11:10:25_igor"

RNAi : "WBRNAi00000147" -O "2001-08-07_08:04:39_lstein"
History_name	 -O "2004-12-05_11:10:25_igor" "KK:B0250.1" -O "2004-12-05_11:10:25_igor"
Homol	 -O "2010-04-30_17:10:26_gary" Homol_homol -O "2010-04-30_17:10:26_gary" "B0250:RNAi" -O "2010-04-30_17:10:26_gary"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" DNA_text -O "2005-01-22_12:55:26_raymond" "cctntggagcctcnggtaactacgccccgtcatcgcccacaacccagacccnagaagacacgtattcgcctcccatcctnngccaagaaggtcgttcaatcggtcaaccgcgccatgattggactcgtcgctggaggaggacgtaccgacaagccacttctcaaggctggacgctcataccacangtncanggcaaagagaaacagctggccacagtgtcagaggagttgccatgaatccagtcgaacatccccacggnggaggtnaccatcaacatnttggacatccatccaccgtcanaagagacgccagtgccggaaagaaggttggacttatcgccgccgccgnaccngaagaattcgcggaggaaangccagcnaattcaccaaggaggagaacc" -O "2005-01-22_12:55:26_raymond" "BE228129" -O "2005-01-22_12:55:26_raymond"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" Sequence -O "2005-01-22_12:55:26_raymond" "BE228129" -O "2005-01-22_12:55:26_raymond"
Uniquely_mapped	 -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Laboratory -O "2004-12-05_11:10:25_igor" "KK" -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Piano F" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Schetter AJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Mangone M" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Stein LD" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Kemphues KJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Date -O "2004-12-05_11:10:25_igor" 2000-10-21 -O "2004-12-05_11:10:25_igor"
Species	 -O "2010-08-26_16:14:33_gary" "Caenorhabditis elegans" -O "2010-08-26_16:14:33_gary"
Reference	 -O "2004-12-05_11:10:25_igor" "WBPaper00004540" -O "2004-12-05_11:10:25_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Remark -O "2006-05-05_12:49:52_igor" "\% penetrance range" -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Penetrance -O "2006-05-05_12:49:52_igor" Range -O "2006-05-05_12:49:52_igor" 80 -O "2006-05-05_12:49:52_igor" 100 -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000689" -O "2006-05-05_12:49:52_igor"
Remark	 -O "2004-12-05_11:10:25_igor" "Embryonic lethal\; egg production ceases in injected animal\; catastrophic one-cell arrest" -O "2004-12-05_11:10:25_igor"
Remark	 -O "2004-12-05_11:10:25_igor" "Mapping of BE228129 to SUPERLINK_CB_V does not represent the best hit. It was carried out using BLAT_EST_OTHER method" -O "2005-01-22_12:55:26_raymond"
Method	 -O "2004-12-05_11:10:25_igor" "RNAi" -O "2004-12-05_11:10:25_igor"

RNAi : "WBRNAi00000148" -O "2001-08-07_08:04:39_lstein"
History_name	 -O "2004-12-05_11:10:25_igor" "KK:B0464.1" -O "2004-12-05_11:10:25_igor"
Homol	 -O "2010-04-30_17:10:26_gary" Homol_homol -O "2010-04-30_17:10:26_gary" "B0464:RNAi" -O "2010-04-30_17:10:26_gary"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" DNA_text -O "2005-01-22_12:55:26_raymond" "aaggnagaggattcgtggagatcatggctccaaaaattatctctgcgccaagtgagggtggagccaatgttttcgaagtttcctatttcaaaggatccgcctacttggctcaatctccacaactctataagcaaatggctattgccggagattttgaaaaggtctacactattggtccagtattccgtgctgaanattctaacacccatcgtcatatgaccgagttcgttggacttgacttggaaatggccttcaacttccattatcacgaggttatggaaaccattgcanaagtgctcacccagatgttcaaaggtcttcaacaaaactatcaagatgagatcgcagccgttggaaatcaatatccagctgagccattccagttctgcgagccaccacttattttaaaatatcctgatgcaatcactcttctccgtgagaatggaattgaaatcggagacgaagatgatctgtccgacccagtgggagaaagttcctcggaaaattggtgaaggagaagtntagcaccgacttntacgtgctcgacaagttnccacttnctggtcggccatttacaccatgccanacgcttcncgatgaaccgttnttca" -O "2005-01-22_12:55:26_raymond" "BE228064" -O "2005-01-22_12:55:26_raymond"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" Sequence -O "2005-01-22_12:55:26_raymond" "BE228064" -O "2005-01-22_12:55:26_raymond"
Uniquely_mapped	 -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Laboratory -O "2004-12-05_11:10:25_igor" "KK" -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Piano F" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Schetter AJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Mangone M" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Stein LD" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Kemphues KJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Date -O "2004-12-05_11:10:25_igor" 2000-10-21 -O "2004-12-05_11:10:25_igor"
Species	 -O "2010-08-26_16:14:33_gary" "Caenorhabditis elegans" -O "2010-08-26_16:14:33_gary"
Reference	 -O "2004-12-05_11:10:25_igor" "WBPaper00004540" -O "2004-12-05_11:10:25_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Remark -O "2006-05-05_12:49:52_igor" "\% penetrance range" -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000050" -O "2006-05-05_12:49:52_igor" Penetrance -O "2006-05-05_12:49:52_igor" Range -O "2006-05-05_12:49:52_igor" 80 -O "2006-05-05_12:49:52_igor" 100 -O "2006-05-05_12:49:52_igor"
Phenotype	 -O "2004-12-05_11:10:25_igor" "WBPhenotype:0000689" -O "2006-05-05_12:49:52_igor"
Remark	 -O "2004-12-05_11:10:25_igor" "Embryonic lethal\; embryos arrest at different stages\; catastrophic one-cell arrest\; egg production ceases in injected animal." -O "2004-12-05_11:10:25_igor"
Method	 -O "2004-12-05_11:10:25_igor" "RNAi" -O "2004-12-05_11:10:25_igor"

RNAi : "WBRNAi00000149" -O "2001-08-07_08:04:39_lstein"
History_name	 -O "2004-12-05_11:10:25_igor" "KK:C02F5.1" -O "2004-12-05_11:10:25_igor"
Homol	 -O "2010-04-30_17:10:26_gary" Homol_homol -O "2010-04-30_17:10:26_gary" "C02F5:RNAi" -O "2010-04-30_17:10:26_gary"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" DNA_text -O "2005-01-22_12:55:26_raymond" "gctgctaagaggtctcgataagatggctgtcgttcaaaaagaactagaaaagctgagaagtcttcctccatcacgcgaagagagcgggaaaatccgaaaggagtggatggagatgaagcantgggaattcgaccagaaaatgaaagcactccgaaatgtncgctcaaacatgattgcacttcgttcanagaaaaatgctctcgaaatgaaagtcgcggaanaacacgagaagtttgcccagaggaacgatttgaanaaaagtcgaatgctggtgttctctaaggctgttaanaaaattgtgaacttctaatgccgccttcacccttcccttgcntcaggcctacaatacttctgatgctcatataattctttacctaatgngccatatattttagtt" -O "2005-01-22_12:55:26_raymond" "BE228117" -O "2005-01-22_12:55:26_raymond"
Sequence_info	 -O "2005-01-22_12:55:26_raymond" Sequence -O "2005-01-22_12:55:26_raymond" "BE228117" -O "2005-01-22_12:55:26_raymond"
Uniquely_mapped	 -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Laboratory -O "2004-12-05_11:10:25_igor" "KK" -O "2004-12-05_11:10:25_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Piano F" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Schetter AJ" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Mangone M" -O "2006-05-26_22:52:44_igor"
Experiment	 -O "2004-12-05_11:10:25_igor" Author -O "2006-05-26_22:52:44_igor" "Stein LD" -O "2006-05-26_22:52:44_igor"
