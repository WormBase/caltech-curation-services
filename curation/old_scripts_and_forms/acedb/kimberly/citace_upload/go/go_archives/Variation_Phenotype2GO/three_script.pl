#!/usr/bin/perl

# take input file from command line, get ws version from filename
# take latest /home/acedb/ranjana/Variation_Phenotype2GO/variation_phenotype2go_mappings.full.*
# to get phenotype id / phenotype name / goid / go name
# take latest /home2/acedb/ranjana/citace_upload/go_curation/go_dumper_files/phenote_go.ace.*
# to get lines by wbgene to exclude from writing to OU2 
# take /home/azurebrd/public_html/var/work/phenote/ws_current.obo
# to get variation -> wbgene / locus mappings
#
# write all stuff in readable format to 'gene_variation_goterm_WS' . $version;
# write all stuff except excluded lines in .ace format to 'gene_variation_goterm_WS' . $version . ".ace";
# track those new wbgenes and append them to 'genenumbers_variation_phenotype2go' with wbgene count and date.
#
# for Ranjana  2009 08 12
#
# Changed to use :
# my $ph2go_file = 'phenotype2go_mappings.ace';
# my $gobo_file = 'gene_ontology_edit.obo';
# my $phobo_file = 'phenotype_ontology.obo';
# instead of latest /home/acedb/ranjana/Variation_Phenotype2GO/variation_phenotype2go_mappings.full.*
# 2009 09 23


use strict;
use LWP::Simple;
use DBI;
use Jex;

my $date = &getSimpleDate();

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

unless ($ARGV[0]) { die "Need an inputfile : ./three_script.pl inputfile206.ace\n"; }
my $infile = $ARGV[0];
# my $infile2 = $ARGV[1];

my ($version) = $infile =~ m/(\d+)/;


# my (@vp2gomfullfiles) = </home/acedb/ranjana/Variation_Phenotype2GO/variation_phenotype2go_mappings.full.*>;
# my $vp2gomfullfile = pop @vp2gomfullfiles;
# 
# my %phenToGo;
# 
# $/ = "\n";
# open (IN, "<$vp2gomfullfile") or die "Cannot open $vp2gomfullfile : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   my ($phid, $phname, $goid, $goname) = split/\t/, $line;
#   $phenToGo{name}{$phid} = $phname;
#   if ($goid) { $phenToGo{goid}{$phid}{$goid}++; }
#   if ($goname) { $phenToGo{goname}{$goid} = $goname; }
# }
# close (IN) or die "Cannot close $vp2gomfullfile : $!";

my %phenToGo;
# GET phenote2go mappings from phenotype2go_mappings.ace
# GET phenID to phenName from obo
# GET goID to goName from obo

my $ph2go_file = 'phenotype2go_mappings.ace';
my $gobo_file = 'gene_ontology_edit.obo';
my $phobo_file = 'phenotype_ontology.obo';

$/ = "";
open (IN, "<$ph2go_file") or die "Cannot open $ph2go_file : $!";
while (my $para = <IN>) {
  my ($phid) = $para =~ m/(WBPhenotype:\d+)/;
  my (@goid) = $para =~ m/(GO:\d+)/;
  foreach my $goid (@goid) { $phenToGo{goid}{$phid}{$goid}++; }
}
close (IN) or die "Cannot close $ph2go_file : $!";

open (IN, "<$phobo_file") or die "Cannot open $phobo_file : $!";
while (my $para = <IN>) {
  my ($phid) = $para =~ m/id: (.*)/;
  my ($phname) = $para =~ m/name: (.*)/;
  $phenToGo{name}{$phid} = $phname;
}
close (IN) or die "Cannot close $phobo_file : $!";

open (IN, "<$gobo_file") or die "Cannot open $gobo_file : $!";
while (my $para = <IN>) {
  my ($goid) = $para =~ m/id: (.*)/;
  my ($goname) = $para =~ m/name: (.*)/;
  if ($goname) { $phenToGo{goname}{$goid} = $goname; }
}
close (IN) or die "Cannot close $gobo_file : $!";


my %exclude;
my (@excludefile) = </home2/acedb/ranjana/citace_upload/go_curation/go_dumper_files/phenote_go.ace.*>;
my $excludefile = pop @excludefile;
$/ = "";
open (IN, "<$excludefile") or die "Cannot open $excludefile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $head = shift @lines;
  my ($wbg) = $head =~ m/(WBGene\d+)/;
  foreach my $line (@lines) { $exclude{$wbg}{$line}++; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $excludefile : $!";
$/ = "\n";

$/ = "";
my %varToGene;
my $obofile = "/home/azurebrd/public_html/var/work/phenote/ws_current.obo";
open (IN, "<$obofile") or die "Cannot open $obofile : $!";
while (my $para = <IN>) {
  if ($para =~ m/id: (.*)/) { 
    my $id = $1;
    if ($para =~ m/allele: \"(WBGene\d+)\t(.*)\"/) { 
      $varToGene{$id}{wbgene} = $1;
      $varToGene{$id}{locus} = $2; } }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $obofile : $!";
$/ = "\n";


# my $outfile = 'gene_variation_goterm_WS' . $version;
# my $outacefile = 'gene_variation_goterm_WS' . $version . ".ace";
my $outfile2 = 'gene_variation_goterm_' . $date;
my $outfile3 = 'gene_variation_goterm_nomappings_' . $date;
my $outacefile = 'gene_variation_goterm_' . $date . ".ace";
open (OU3, ">$outfile3") or die "Cannot open $outfile3 : $!";
open (OU2, ">$outfile2") or die "Cannot open $outfile2 : $!";
open (OUT, ">$outacefile") or die "Cannot open $outacefile : $!";

my %newGenes;
my %geneData;
my %goid_paper_annotations;
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  next if ($para =~ m/\"\tNOT\t/);			# skip NOT
  next unless ($para =~ m/WBPaper/);			# must have paper evidence
  next unless ($para =~ m/Variation : \"(.*?)\"/);	# only use variations
  my $var = $1;
  next unless ( $varToGene{$var}{wbgene} );		# only real entries, ws_current.obo behind WS
  my ($phid) = $para =~ m/(WBPhenotype:\d+)/;
  my $pap = '';
  if ($para =~ m/Paper_evidence\t\"(WBPaper\d+)\"/) { $pap = $1; }

  my $para1 = '';
#   print OUT "Gene: $varToGene{$var}{wbgene}\n";
  $para1 .= "\ncgc name/cosmid name: $varToGene{$var}{locus}\n";
  $para1 .= "Variation: $var\n";
  $para1 .= "Phenotype_ID: $phid\n";
  $para1 .= "Phenotype_name: $phenToGo{name}{$phid}\n";
  $para1 .= "Paper_evidence: $pap\n";
  my (@goids) = sort keys %{ $phenToGo{goid}{$phid} };
  my $goids = join", ", @goids;
  my @gonames;
  foreach (@goids) { push @gonames, $phenToGo{goname}{$_}; }
  my $gonames = join", ", @gonames;
  $para1 .= "GO_term_ID: $goids\n";
  $para1 .= "GO_term_name: $gonames\n";
  $para1 .= "Evidence_code: IMP\n";
#   $para1 .= "\n";
  if ($goids) {
    $geneData{'two'}{$varToGene{$var}{wbgene}} .= $para1; }
  else {
    $geneData{'three'}{$varToGene{$var}{wbgene}} .= $para1; }
 
  my $para = '';
  foreach my $goid (@goids) {
    if ($pap) {
      my $line = "GO_term\t\"$goid\"\t\"IMP\"\tPaper_evidence\t\"$pap\"";
      unless ($exclude{$line}) { $para .= "$line\n"; } }
    my $line = "GO_term\t\"$goid\"\t\"IMP\"\tVariation_evidence\t\"$var\"";
    unless ($exclude{$line}) { $para .= "$line\n"; }
  }
  if ($para) {
    $newGenes{$varToGene{$var}{wbgene}}++;
    my (@pairs) = $para =~ m/\"GO:(\d+\".*?Paper_evidence\s+\"WBPaper\d+)\"/g;
    foreach (@pairs) { 
      my ($goid, $paper) = $_ =~ m/^(\d+).*?(\d+)$/g; $goid_paper_annotations{$goid}{$paper}{$varToGene{$var}{wbgene}}++; }
#     print OU2 "Gene: \"$varToGene{$var}{wbgene}\"\n";
#     print OU2 "$para\n"; 
    $geneData{'one'}{$varToGene{$var}{wbgene}} .= $para; }

} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my $goid_paper_annotations = 0;
my $goid_paper_gene_annotations = 0;
foreach my $goid (keys %goid_paper_annotations) {
  foreach my $paper (keys %{ $goid_paper_annotations{$goid} }) {
    $goid_paper_annotations++; 
    foreach my $gene (keys %{ $goid_paper_annotations{$goid}{$paper} }) {
      $goid_paper_gene_annotations++; } } }

foreach my $gene (sort keys %{ $geneData{'one'} }) {
  print OUT "Gene : \"$gene\"\n$geneData{'one'}{$gene}\n\n";
}

foreach my $gene (sort keys %{ $geneData{'two'} }) {
  print OU2 "Gene : \"$gene\"\n$geneData{'two'}{$gene}\n\n";
}
foreach my $gene (sort keys %{ $geneData{'three'} }) {
  print OU3 "Gene : \"$gene\"\n$geneData{'three'}{$gene}\n\n";
}


close (OU3) or die "Cannot close $outfile3 : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
close (OUT) or die "Cannot close $outacefile : $!";

my %gop;	# wbgenes curated in postgres from worm-go phenote
my %gin;	# wbgene -> locus
my $result = $dbh->prepare( "SELECT * FROM gop_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gop{$row[1]}++; }
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gin{"WBGene$row[0]"} = $row[1]; }

my $date = &getSimpleDate();
my $count = 0; my $output = '';

foreach my $gene (sort keys %newGenes) {
  next if ($gop{$gene});				# skip if already in postgres
  $count++;						# count each wbgene added
  $output .= "${gene}/$gin{$gene}\n";			# add the wbgene/locus
} # foreach my $gene (sort keys %newGenes)
my $appendfile = 'genenumbers_variation_phenotype2go';	# append to this file
open (OU4, ">>$appendfile") or die "Cannot open $appendfile : $!";
print OU4 "GOID - paper annotations count $goid_paper_annotations\n";
print OU4 "GOID - paper - gene annotations count $goid_paper_gene_annotations\n";
print OU4 "\n$date\n$count new wbgenes\n$output\n";
close (OU4) or die "Cannot close $appendfile : $!";



__END__

Variation : "a83"
Phenotype	"WBPhenotype:0000255"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000255"	Paper_evidence	"WBPaper00002087"
Phenotype	"WBPhenotype:0000255"	Remark	"Defects in dye filling."	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000255"	Remark	"Defects in dye filling."	Paper_evidence	"WBPaper00002087"
Phenotype	"WBPhenotype:0000255"	Remark	"Defects in dye filling."
Phenotype	"WBPhenotype:0000255"	"Recessive"	Curator_confirmed	"WBPerson48"
Phenotype	"WBPhenotype:0000255"	"Recessive"	Paper_evidence	"WBPaper00002087"

Variation : "a83"
Phenotype	"WBPhenotype:0000478"	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000478"	Paper_evidence	"WBPaper00000932"
Phenotype	"WBPhenotype:0000478"	NOT	Curator_confirmed	"WBPerson712"
Phenotype	"WBPhenotype:0000478"	NOT	Paper_evidence	"WBPaper00000932"

