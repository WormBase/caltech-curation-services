#!/usr/bin/perl

use strict;

my $gafile = 'gene_association.WS257.wb.c_elegans';
my $ptgfile = 'phenotype2go.WS257.wb';

my %genesInGa;
open (IN, "<$gafile") or die "Cannot open $gafile : $!";
while (my $line = <IN>) {
  next unless ($line =~ m/^WB/);
  my (@line) = split/\t/, $line;
  next if ($line[6] eq 'IEA');
  if ($line[8] eq 'P') { $genesInGa{$line[1]}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $gafile : $!";

my %genesPtgNotGa;
open (IN, "<$ptgfile") or die "Cannot open $ptgfile : $!";
while (my $line = <IN>) {
  next unless ($line =~ m/^WB/);
  my (@line) = split/\t/, $line;
  my $gene = $line[1];
  unless ($genesInGa{$gene}) { $genesPtgNotGa{$gene}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $ptgfile : $!";

foreach my $gene (sort keys %genesPtgNotGa) {
  print qq($gene\n);
} # foreach my $gene (sort keys %genesPtgNotGa)



__END__

!gaf-version: 2.0
!Project_name: WormBase
!Contact Email: help@wormbase.org
WB	WBGene00000001	aap-1		GO:0005942	GO_REF:0000033	IBA	PANTHER:PTN000806614	C		Y110A7A.10	gene	taxon:6239	20150227	GO_Central		
WB	WBGene00000001	aap-1		GO:0005942	GO_REF:0000002	IEA	InterPro:IPR001720	C		Y110A7A.10	gene	taxon:6239	20161115	WB		
WB	WBGene00000001	aap-1		GO:0005942	WB_REF:WBPaper00005614|PMID:12393910	IDA		C		Y110A7A.10	gene	taxon:6239	20151214	WB		
WB	WBGene00000001	aap-1		GO:0008286	WB_REF:WBPaper00005614|PMID:12393910	IGI	WB:WBGene00000090	P		Y110A7A.10	gene	taxon:6239	20151214	WB		
WB	WBGene00000001	aap-1		GO:0008286	WB_REF:WBPaper00005614|PMID:12393910	IGI	WB:WBGene00000898	P		Y110A7A.10	gene	taxon:6239	20151214	WB		
WB	WBGene00000001	aap-1		GO:0008286	WB_REF:WBPaper00005614|PMID:12393910	IMP		P		Y110A7A.10	gene	taxon:6239	20060302	WB		
WB	WBGene00000001	aap-1		GO:0008340	WB_REF:WBPaper00005614|PMID:12393910	IMP		P		Y110A7A.10	gene	taxon:6239	20060302	WB		
WB	WBGene00000001	aap-1		GO:0016301	GO_REF:0000038	IEA	UniProtKB-KW:KW-0418	F		Y110A7A.10	gene	taxon:6239	20161022	UniProt		


!gaf-version: 2.0
!Project_name: WormBase
!Contact Email: help@wormbase.org
WB	WBGene00015175	srz-4		GO:0009792	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000001|WBPhenotype:0000050	P		B0414.1	gene	taxon:6239	20161116	WB		
WB	WBGene00015175	srz-4		GO:0009792	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000001|WBPhenotype:0001020	P		B0414.1	gene	taxon:6239	20161116	WB		
WB	WBGene00015235	cdc-26		GO:0009792	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000002|WBPhenotype:0000050	P		B0511.9	gene	taxon:6239	20161116	WB		
WB	WBGene00002717	let-526		GO:0009792	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000003|WBPhenotype:0000050	P		C01G8.9	gene	taxon:6239	20161116	WB		
WB	WBGene00002717	let-526		GO:0002119	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000003|WBPhenotype:0000054	P		C01G8.9	gene	taxon:6239	20161116	WB		
WB	WBGene00002717	let-526		GO:0010171	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000003|WBPhenotype:0000535	P		C01G8.9	gene	taxon:6239	20161116	WB		
WB	WBGene00002717	let-526		GO:0009792	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000003|WBPhenotype:0001020	P		C01G8.9	gene	taxon:6239	20161116	WB		
WB	WBGene00002717	let-526		GO:0009792	WB_REF:WBPaper00004402|PMID:11099033	IEA	WB:WBRNAi00000004|WBPhenotype:0000050	P		C01G8.9	gene	taxon:6239	20161116	WB		
