#!/usr/bin/perl

use strict;

if ($ARGV[0]) { print "input file is $ARGV[0]\n"; }
else { die "Need to enter an inputfile : ./count_gene_paper.pl <inputfile>\n"; }

my %gene;
my %papers;
$/ = "";
my $infile = $ARGV[0];
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my $gene;
  if ($para =~ m/Gene : \"(WBGene\d+)\"\n/) { $gene = $1; }
  if ($para =~ m/WBPaper\d+/) { 
    my (@papers) = $para =~ m/(WBPaper\d+)/g; 
    $gene{$gene} = scalar(@papers);
    foreach my $paper (@papers) { $papers{$paper}++; } }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

my @all_papers = keys %papers;
print "There are " . scalar(@all_papers) . " unique paper in $infile\n"; 
print "Gene\tUnique Papers in that Gene\n";
foreach my $gene (sort keys %gene) {
  print "$gene\t$gene{$gene}\n";
} # foreach my $gene (sort keys %gene)

