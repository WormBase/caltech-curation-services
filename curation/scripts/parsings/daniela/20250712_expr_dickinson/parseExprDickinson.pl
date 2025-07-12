#!/usr/bin/env perl

# parse dickinson set for Daniela
# specs here https://docs.google.com/document/d/160Xz4iEsE9vd8RDWMHXIQJazXFnMH63Y00WuqfpZoDE/edit?tab=t.0
# source file here https://drive.google.com/drive/u/1/folders/16IN-NehhtMmwoRArtqpLn0ReVzZTsgSj
# 2025 07 12


use strict;
use JSON;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use Jex;
use Dotenv -load => '/usr/lib/.env';

my $infile = 'cleaned_filenames.txt';
my $expr_id = 2040000;
my $pic_id = 1200000;

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
# WBGene00016495_WBPaper00068221.jpg
  if ($line =~ m/(WBGene\d+)_(WBPaper\d+)\.jpg/) {
    my $wbgene = $1;
    my $wbpaper = $2;
    my $wbexprId = 'Expr' . $expr_id;
    my $wbpicId = 'WBPicture000' . $pic_id;
    $expr_id++;
    $pic_id++;
    print<<EndOfText;
Expr_pattern : "$wbexprId"
Reference\t"$wbpaper"
Gene\t"$wbgene"
Reflects_endogenous_expression_of		"$wbgene"
RNAseq 
Ribosome_profiling 
Pattern		"Translational efficiency and RNA abundance/Ribosome occupancy across early embryonic stages (1-cell to 8-cell). For each developmental stage, translational efficiency was calculated as the ratio between ribosome footprint reads and mRNA abundance after normalization. A detailed description of the experimental methods and analysis can be found in: Shukla Y, Ghatpande V, Hu CF, Dickinson DJ, Cenik C. Landscape and regulation of mRNA translation in the early C. elegans embryo. Cell Rep. 2025 June 24;44(6):115778. doi: 10.1016/j.celrep.2025.115778. PMID: 40450690"

Picture : "$wbpicId"
Reference	"$wbpaper"
Description	"Translational efficiency and RNA abundance/Ribosome occupancy for the indicated gene. The upper panel (A) shows translational efficiency (TE) profiles across early embryonic stages (1-cell to 8-cell). The red line represents the target gene of interest, while gray dashed lines show reference genes with established translational behaviors: lem-2 (High TE), gpd-4 (housekeeping gene), and nos-2 (Low TE). TE values are normalized using centered log-ratio transformation. The lower panel (B) displays corresponding RNA abundance (blue) and ribosome footprint (orange) profiles for the target gene across early embryonic stages. Values represent centered log-ratio transformed read counts, showing the relative changes in transcript levels and ribosome occupancy. Data was obtained through ribosome profiling (RIbo-ITP) and RNA-seq of staged C. elegans embryos. For each developmental stage, translational efficiency was calculated as the ratio between ribosome footprint reads and mRNA abundance after normalization. A detailed description of the experimental methods and analysis can be found in: Shukla Y, Ghatpande V, Hu CF, Dickinson DJ, Cenik C. Landscape and regulation of mRNA translation in the early C. elegans embryo. Cell Rep. 2025 June 24;44(6):115778. doi: 10.1016/j.celrep.2025.115778. PMID: 40450690" 
Name	"$line"
Expr_pattern	"$wbexprId"
Contact		"WBPerson22974"
Person_name	"Dan Dickinson"

EndOfText
  }
  else { print STDERR qq(skipping $line\n); }
}

close (IN) or die "Cannot close $infile : $!";

__END__
