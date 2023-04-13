#!/usr/bin/perl

# convert uniprot stuff to WB  
# http://wiki.wormbase.org/index.php/SOP_for_generating_GO_files_for_citace_and_GO_consortium_uploads#Generating_a_gene_association_file_.28since_Nov_2013.29_for_GOC_upload
# for Kimberly.  2014 08 05


use strict;
use diagnostics;

my %uniToWb;
my $mapfile = 'gp2protein.wb';
open (IN, "<$mapfile") or die "Cannot open $mapfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($wbg, $unip) = split/\t/, $line;
  next unless $unip;
  my ($wbgene) = $wbg =~ m/(WBGene\d+)/;
  my (@unip) = split/;/, $unip;
  foreach (@unip) { $_ =~ s/UniProtKB://; $uniToWb{$_} = $wbgene; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $mapfile : $!";

my $infile = '9.C_elegans.goa';
my $outfile = $infile . '.out';
my $errfile = $infile . '.err';
my $output = '';
my $errors = '';

open (IN, "<$infile") or die "Cannot open $infile : $!";
my $line = <IN>; $output .= $line;
while (my $line = <IN>) {
  chomp $line;
  my (@line) = split/\t/, $line;
  my $hasError = '';
  if ($line[0] eq 'UniProtKB') {
    $line[0] = 'WB';
    if ($uniToWb{$line[1]}) { $line[1] = $uniToWb{$line[1]}; }
      else { $hasError .= "ERROR col2 $line[1] does not map to WBGene\n"; }
    if ($line[11] eq 'protein') { $line[11] = 'gene'; }
      else { $hasError .= "ERROR col12 $line[11] does not say protein\n"; }
    my $line = join"\t", @line; 
    if ($hasError) {
        $errors .= "$hasError";
        $errors .= "$line\n"; }
      else { 
        $output .= "$line\n"; }
  } # if ($line[0] eq 'UniProtKB')
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

open (ERR, ">$errfile") or die "Cannot create $errfile : $!";
print ERR $errors;
close (ERR) or die "Cannot close $errfile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $output;
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

!gaf-version: 2.0
UniProtKB	A0A9R9	wht-7		GO:0005524	GO_REF:0000002	IEA	InterPro:IPR003439	F	Protein WHT-7, isoform b	A0A9R9_CAEEL|wht-7|CELE_Y42G9A.6|Y42G9A.6	protein	taxon:6239	20140705	InterPro		
UniProtKB	A0A9R9	wht-7		GO:0006200	GO_REF:0000002	IEA	InterPro:IPR003439	P	Protein WHT-7, isoform b	A0A9R9_CAEEL|wht-7|CELE_Y42G9A.6|Y42G9A.6	protein	taxon:6239	20140705	GOC		
UniProtKB	A0A9R9	wht-7		GO:0016020	GO_REF:0000002	IEA	InterPro:IPR013525	C	Protein WHT-7, isoform b	A0A9R9_CAEEL|wht-7|CELE_Y42G9A.6|Y42G9A.6	protein	taxon:6239	20140705	InterPro		
UniProtKB	A0A9R9	wht-7		GO:0016887	GO_REF:0000002	IEA	InterPro:IPR003439	F	Protein WHT-7, isoform b	A0A9R9_CAEEL|wht-7|CELE_Y42G9A.6|Y42G9A.6	protein	taxon:6239	20140705	InterPro		
UniProtKB	A0A9S2	CELE_Y38F2AR.12		GO:0003824	GO_REF:0000002	IEA	InterPro:IPR003692	F	Protein Y38F2AR.12, isoform a	A0A9S2_CAEEL|CELE_Y38F2AR.12|Y38F2AR.12	protein	taxon:6239	20140705	InterPro		
UniProtKB	A0A9S2	CELE_Y38F2AR.12		GO:0008152	GO_REF:0000002	IEA	InterPro:IPR002821	P	Protein Y38F2AR.12, isoform a	A0A9S2_CAEEL|CELE_Y38F2AR.12|Y38F2AR.12	protein	taxon:6239	20140705	GOC		
UniProtKB	A0A9S2	CELE_Y38F2AR.12		GO:0008152	GO_REF:0000002	IEA	InterPro:IPR003692	P	Protein Y38F2AR.12, isoform a	A0A9S2_CAEEL|CELE_Y38F2AR.12|Y38F2AR.12	protein	taxon:6239	20140705	GOC		
UniProtKB	A0A9S2	CELE_Y38F2AR.12		GO:0016787	GO_REF:0000002	IEA	InterPro:IPR002821	F	Protein Y38F2AR.12, isoform a	A0A9S2_CAEEL|CELE_Y38F2AR.12|Y38F2AR.12	protein	taxon:6239	20140705	InterPro		
UniProtKB	A0AAC1	dlc-3		GO:0005875	GO_REF:0000002	IEA	InterPro:IPR001372	C	Protein DLC-3, isoform b	A0AAC1_CAEEL|dlc-3|CELE_Y10G11A.2|Y10G11A.2	protein	taxon:6239	20140705	InterPro		
