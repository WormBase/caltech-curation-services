#!/usr/bin/perl

# grab phenotypes from lethal file and print any lines on the other file that
# match any of those phenotypes.  for Carol  2006 09 11

use strict;

my $obo_file = 'lethal_phenotypes_WS165.obo';
# my $phens_file = 'WBRNAi_phenotype_gene_excluding_Not_0001179_WBPhen2_WS165';
my $phens_file = 'Gene_RNAi_phenotype_results';	# second carol set

my %let;		# lethal phenotypes
open (IN, "<$obo_file") or die "Cannot open $obo_file : $!";
while (<IN>) { if ($_ =~ m/(WBPhenotype\d+)/) { $let{$1}++; } } # while (<IN>)
close (IN) or die "Cannot close $obo_file : $!";

open (IN, "<$phens_file") or die "Cannot open $phens_file : $!";
while (<IN>) { 
  if ($_ =~ m/(WBPhenotype\d+)/) { 
    if ($let{$1}) { print; } } }
close (IN) or die "Cannot close $phens_file : $!";
