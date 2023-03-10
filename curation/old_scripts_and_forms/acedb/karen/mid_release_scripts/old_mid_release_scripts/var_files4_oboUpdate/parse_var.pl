#!/usr/bin/perl

# try to get 
# select g, g->gene, g->gene->public_name, g->reference from g in class variation where exists_tag g->allele
# select v, v->gene, v->gene->public_name, v->reference from v in class variation where exists_tag v->transposon_insertion and exists v->gene
# for Karen.  2013 02 25


use strict;
use warnings;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my %genes;

my $result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $genes{"WBGene$row[0]"} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $genes{"WBGene$row[0]"} = $row[1]; }
  


my $allele_file = 'allele_output';
my $transp_file = 'transposon_output';

open (ALL, ">$allele_file") or die "Cannot create $allele_file : $!";
open (TRP, ">$transp_file") or die "Cannot create $transp_file : $!";

$/ = "";
my $infile = 'Variations.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my $has_allele; my $has_gene; my $has_transposon;
  if ($para =~ m/\nAllele\s*\n/ms) { $has_allele++; }
  if ($para =~ m/\nGene\s*\"WBGene\d+\"/ms) { $has_gene++; }
  if ($para =~ m/\nTransposon_insertion\s*\"/ms) { $has_transposon++; }
  next unless ($has_allele || ($has_gene && $has_transposon));
  my ($obj) = $para =~ m/Variation : "(WBVar\d+)"/;
  my (@genes) = $para =~ m/\nGene\s+"(WBGene\d+)"/g;
  my (@references) = $para =~ m/\nReference\s+"(WBPaper\d+)"/g;
  my $genes = join", ", @genes;
  my @loci; 
  foreach my $gene (@genes) { 
    my $locus = ''; if ($genes{$gene}) { $locus = $genes{$gene}; }
    push @loci, $locus; }
  my $loci = join", ", @loci;
  my $refs = join", ", @references;
  if ($has_allele) { print ALL "$obj\t$genes\t$loci\t$refs\n"; }
  if ($has_gene && $has_transposon) { print TRP "$obj\t$genes\t$loci\t$refs\n"; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

close (ALL) or die "Cannot close $allele_file : $!";
close (TRP) or die "Cannot close $transp_file : $!";

