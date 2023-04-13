#!/usr/bin/perl

# parse stuff for Kimberly according to her wiki
# http://wiki.wormbase.org/index.php/SOP_for_generating_GO_files_for_citace_and_GO_consortium_uploads#Generating_a_Gene_Association_File_from_UniProtKB_with_a_1:1_WBGene:Protein_Mapping:_2014-08-12
# 2014 08 12


use strict;
use diagnostics;

my $good2;
my $good4;
my $pruned4;

my %uniUsed;										# these have already had an output that maps to a WBGene

my $arbitraryUp = 10000000;

my %uniSum;
my $infile = 'uniprot_summary.wb';
open (UNI, "<$infile") or die "Cannot open $infile : $!";
my $junk = <UNI>;
while (my $line = <UNI>) {
  chomp $line;
  my @line = split/\t/, $line;
  my $entry = $line[0]; my $status = $line[2]; my $length = $line[6];
  if ($status eq 'reviewed') { $length += $arbitraryUp; }
  $uniSum{"UniProtKB:$entry"} = $length;
} # while (my $line = <UNI>)
close (UNI) or die "Cannot close $infile : $!";

$infile = 'gp2protein.wb';
open (GP2, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <GP2>) {
  chomp $line;
  my ($wbg, $unis) = split/\t/, $line;
  my (@unis) = split/;/, $unis;
  my %values;
  foreach my $uni (@unis) {
    unless ($uniSum{$uni}) { print "NO VALUE $uni in uniprot_summary.wb\n"; next; }
    my $length = $uniSum{$uni};
    $values{$length} = $uni;
  } # foreach my $uni (@unis)
  my $count = 0;
  foreach my $length ( sort {$b<=>$a} keys %values ) {
    $count++;
    my $uni = $values{$length};
    $uniUsed{$uni}++;								# this value will have been added to some output
    my $status = 'unreviewed';
    if ($length > $arbitraryUp) { $status = 'reviewed'; $length -= $arbitraryUp; }
    if ($count < 2) {
      $good2 .= qq($wbg\t$uni\n);
      $good4 .= qq($wbg\t$uni\t$status\t$length\n);
    } else {
      $pruned4 .= qq($wbg\t$uni\t$status\t$length\n);
    } 
  }
} # while (my $line = <GP2>)
close (GP2) or die "Cannot close $infile : $!";

foreach my $uni (sort keys %uniSum) {
  next if $uniUsed{$uni};
  my $length = $uniSum{$uni};
  my $status = 'unreviewed';
  if ($length > $arbitraryUp) { $status = 'reviewed'; $length -= $arbitraryUp; }
  $pruned4 .= qq(\t$uni\t$status\t$length\n);
} # foreach my $uni (sort keys %uniSum)

my $single = 'gp2protein_single.wb';
my $singlefull = 'gp2protein_single_status.wb';
my $pruned = 'gp2protein_pruned.wb';

open (OUT, ">$single") or die "Cannot create $single : $!";
print OUT $good2;
close (OUT) or die "Cannot close $single : $!";

open (OUT, ">$singlefull") or die "Cannot create $singlefull : $!";
print OUT $good4;
close (OUT) or die "Cannot close $singlefull : $!";

open (OUT, ">$pruned") or die "Cannot create $pruned : $!";
print OUT $pruned4;
close (OUT) or die "Cannot close $pruned : $!";


__END__

uniprot_summary.wb
Entry	Entry name	Status	Protein names	Gene names	Organism	Length
P41932	14331_CAEEL	reviewed	14-3-3-like protein 1 (Partitioning defective protein 5)	par-5 ftt-1 M117.2	Caenorhabditis elegans	248
Q20655	14332_CAEEL	reviewed	14-3-3-like protein 2	ftt-2 F52D10.3	Caenorhabditis elegans	248
Q09543	2AAA_CAEEL	reviewed	Probable serine/threonine-protein phosphatase PP2A regulatory subunit (Protein phosphatase PP2A regulatory subunit A)	paa-1 F48E8.5	Caenorhabditis elegans	590
Q19341	3HAO_CAEEL	reviewed	3-hydroxyanthranilate 3,4-dioxygenase (EC 1.13.11.6) (3-hydroxyanthranilate oxygenase) (3-HAO) (3-hydroxyanthranilic acid dioxygenase) (HAD)	haao-1 K06A4.5	Caenorhabditis elegans	281
Q9XTI0	3HIDH_CAEEL	reviewed	Probable 3-hydroxyisobutyrate dehydrogenase, mitochondrial (HIBADH) (EC 1.1.1.31)	B0250.5	Caenorhabditis elegans	299
Q09315	5NT3_CAEEL	reviewed	Putative cytosolic 5'-nucleotidase 3 (EC 3.1.3.5) (Putative pyrimidine 5'-nucleotidase)	F25B5.3	Caenorhabditis elegans	376
Q17761	6PGD_CAEEL	reviewed	6-phosphogluconate dehydrogenase, decarboxylating (EC 1.1.1.44)	T25B9.9	Caenorhabditis elegans	484
O18229	6PGL_CAEEL	reviewed	Putative 6-phosphogluconolactonase (6PGL) (EC 3.1.1.31)	Y57G11C.3	Caenorhabditis elegans	269
Q19124	A16L1_CAEEL	reviewed	Autophagic-related protein 16.1	atg-16.1 F02E8.5	Caenorhabditis elegans	578

gp2protein.wb
WB:WBGene00000001	UniProtKB:G5EDP9
WB:WBGene00000002	UniProtKB:Q19834
WB:WBGene00000003	UniProtKB:Q19151
WB:WBGene00000004	UniProtKB:O17395
WB:WBGene00000005	UniProtKB:Q7YXH5
WB:WBGene00000006	UniProtKB:H2KZG9;UniProtKB:H2KZH0;UniProtKB:Q5TKB5
WB:WBGene00000007	UniProtKB:B2D6M4;UniProtKB:Q22397
WB:WBGene00000008	UniProtKB:O44832
WB:WBGene00000009	UniProtKB:Q94197
WB:WBGene00000010	UniProtKB:Q56VY0;UniProtKB:Q9NA91

