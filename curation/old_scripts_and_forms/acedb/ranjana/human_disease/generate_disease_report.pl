#!/usr/bin/perl -w

# from .ace file, sort by doid and count genes / papers / disease_relevance  2016 03 10

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $date = &getSimpleDate();

my %doToName;
$result = $dbh->prepare( "SELECT * FROM obo_name_humando ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $doToName{$row[0]} = $row[1]; } }

my %hash;
my @disTables = qw( diseaserelevance wbgene humandoid paperexpmod variation strain transgene diseasemodeldesc modgene modmolecule modother modvariation modstrain modtransgene );
foreach my $table (@disTables) { 
  $result = $dbh->prepare( "SELECT * FROM dis_$table ;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      if ($table eq 'humandoid') {
        my (@doids) = $row[1] =~ m/(DOID:\d+)/g;
        foreach my $doid (@doids) {
          $hash{$table}{dtp}{$doid}{$row[0]}++; } }
      $hash{$table}{ptd}{$row[0]} = $row[1]; } }
} # foreach my $table (@disTables) 

my $outfile = 'disease_report_' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $count = 0; my %sort;
foreach my $doid (sort keys %{ $hash{humandoid}{dtp} }) {
#   $count++; last if ($count > 1);
  my $doName = $doToName{$doid} || '';
  my %data;
  foreach my $pgid (sort keys %{ $hash{humandoid}{dtp}{$doid} }) {
    my $gene   = $hash{wbgene}{ptd}{$pgid} || '';
    if ($gene) { $data{gene}{$gene}++; }
    my $strain   = $hash{strain}{ptd}{$pgid} || '';
    if ($strain) { $data{strain}{$strain}++; }
    my $transgene   = $hash{transgene}{ptd}{$pgid} || '';
    if ($transgene) { $data{transgene}{$transgene}++; }
    my $variation   = $hash{variation}{ptd}{$pgid} || '';
    if ($variation) { $data{variation}{$variation}++; }
    my $disr   = $hash{diseaserelevance}{ptd}{$pgid} || '';
    if ($disr) { $data{disr}{$disr}++; }
    my $dism   = $hash{diseasemodeldesc}{ptd}{$pgid} || '';
    if ($dism) { $data{dism}{$disr}++; }
    my $modother   = $hash{modother}{ptd}{$pgid} || '';
    if ($modother) { $data{modother}{$disr}++; }
    my $paps   = $hash{paperexpmod}{ptd}{$pgid} || '';
    if ($paps) {
      my (@paps) = $paps =~ m/(WBPaper\d+)/g;
      foreach my $paper (@paps) { $data{paps}{$paper}++; } }
    my $modgene   = $hash{modgene}{ptd}{$pgid} || '';
    if ($modgene) {
      my (@modgene) = $modgene =~ m/(WBGene\d+)/g;
      foreach my $modgene (@modgene) { $data{modgene}{$modgene}++; } }
    my $modstrains   = $hash{paperexpmod}{ptd}{$pgid} || '';
    if ($modstrains) {
      my (@modstrain) = $modstrains =~ m/(WBStrain\d+)/g;
      foreach my $paper (@modstrain) { $data{modstrain}{$paper}++; } }
    my $modtransgenes   = $hash{paperexpmod}{ptd}{$pgid} || '';
    if ($modtransgenes) {
      my (@modtransgene) = $modtransgenes =~ m/(WBTransgene\d+)/g;
      foreach my $paper (@modtransgene) { $data{modtransgene}{$paper}++; } }
    my $modvariations   = $hash{paperexpmod}{ptd}{$pgid} || '';
    if ($modvariations) {
      my (@modvariation) = $modvariations =~ m/(WBVar\d+)/g;
      foreach my $paper (@modvariation) { $data{modvariation}{$paper}++; } }
  } # foreach my $pgid (sort keys %{ $hash{humandoid}{dtp}{$doid} })
  my $geneCount = scalar keys %{ $data{gene} };
  my $strainCount = scalar keys %{ $data{strain} };
  my $transgeneCount = scalar keys %{ $data{transgene} };
  my $variationCount = scalar keys %{ $data{variation} };
  my $disrCount = scalar keys %{ $data{disr} };
  my $dismCount = scalar keys %{ $data{dism} };
  my $papsCount = scalar keys %{ $data{paps} };
  my $modgeneCount = scalar keys %{ $data{modgene} };
  my $modotherCount = scalar keys %{ $data{modother} };
  my $modstrainCount = scalar keys %{ $data{modstrain} };
  my $modtransgeneCount = scalar keys %{ $data{modtransgene} };
  my $modvariationCount = scalar keys %{ $data{modvariation} };
  my $line = qq($doid\t$doName\tgene count $geneCount\tstrain count $strainCount\ttransgene count $transgeneCount\tvariation count $variationCount\tpaper count $papsCount\tmod other count $modotherCount\tmod gene count $modgeneCount\tmod strain count $modstrainCount\tmod transgene count $modtransgeneCount\tmod variation count $modvariationCount\tDis Model count $disrCount\tDis Rel count $disrCount\n);
  $sort{$geneCount}{$line}++;
} # foreach my $doid (sort keys %{ $hash{humandoid}{dtp} })
foreach my $geneCount (sort {$b<=>$a} keys %sort) {
  foreach my $line (sort keys %{ $sort{$geneCount} }) {
    print OUT qq($line);
  } # foreach my $line (sort keys %{ $sort{$geneCount} })
} # foreach my $geneCount (sort {$a<=>$b} keys %sort)
close (OUT) or die "Cannot close $outfile : $!";

