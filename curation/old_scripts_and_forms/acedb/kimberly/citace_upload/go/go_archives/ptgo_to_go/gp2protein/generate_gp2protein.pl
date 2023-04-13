#!/usr/bin/perl

# generate gp2protein.wb for Kimberly.  2014 08 06

use strict;
use diagnostics;

my $infile = '6239.idmapping';
my $outfile = 'gp2protein.wb';

my %wbgToUni;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($uniprot, $col2, $gene) = split/\t/, $line;
  if ($gene =~ m/WBGene\d+/) { $wbgToUni{"WB:$gene"}{"UniProtKB:$uniprot"}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
foreach my $gene (sort keys %wbgToUni) {
  my $uni = join";", sort keys %{ $wbgToUni{$gene} };
  print OUT "$gene\t$uni\n";
} # foreach my $gene (sort keys %wbgToUni)
close (OUT) or die "Cannot close $outfile : $!";

__END__

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

A0A9R9	EMBL	FO081373
A0A9R9	EMBL-CDS	CCD71159.1
A0A9R9	EnsemblGenome	Y42G9A.6
A0A9R9	GI	115532732
A0A9R9	GI	351063116
A0A9R9	GeneID	175864
A0A9R9	HOGENOM	HOG000046080
A0A9R9	KEGG	cel:CELE_Y42G9A.6
A0A9R9	NCBI_TaxID	6239
A0A9R9	NextBio	890048
A0A9R9	RefSeq	NP_001040882.1
A0A9R9	RefSeq_NT	NM_001047417.2
A0A9R9	STRING	6239.Y42G9A.6a
A0A9R9	UCSC	Y42G9A.6b.3
A0A9R9	UniGene	Cel.9802
A0A9R9	UniParc	UPI00004B76B6
A0A9R9	UniProtKB-ID	A0A9R9_CAEEL
A0A9R9	UniRef100	UniRef100_H2L028
A0A9R9	UniRef50	UniRef50_H2L028
A0A9R9	UniRef90	UniRef90_H2L028
A0A9R9	WormBase	WBGene00021535
A0A9R9	WormBase_PRO	CE39827
A0A9R9	WormBase_TRS	Y42G9A.6b
A0A9R9	eggNOG	COG1131
A0A9S0	EMBL	FO080861
A0A9S0	EMBL-CDS	CCD67297.1
A0A9S0	GI	115533040
A0A9S0	GI	351059703
A0A9S0	GeneID	4363074
A0A9S0	KEGG	cel:CELE_Y55F3BR.10
A0A9S0	NCBI_TaxID	6239
A0A9S0	NextBio	959715
A0A9S0	RefSeq	NP_001041040.1
A0A9S0	RefSeq_NT	NM_001047575.1
A0A9S0	UCSC	Y55F3BR.10
A0A9S0	UniGene	Cel.33911
A0A9S0	UniParc	UPI000052BCD6
A0A9S0	UniProtKB-ID	A0A9S0_CAEEL
A0A9S0	UniRef100	UniRef100_A0A9S0
A0A9S0	UniRef50	UniRef50_A0A9S0
A0A9S0	UniRef90	UniRef90_A0A9S0
A0A9S0	WormBase	WBGene00044742
A0A9S0	WormBase_PRO	CE22531
A0A9S0	WormBase_TRS	Y55F3BR.10
