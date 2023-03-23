#!/usr/bin/perl

use strict;
use diagnostics;

my %genes;
my $infile = 'WBPaper00037950.tr.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($gene, @junk) = split/\t/, $line;
  if ($gene =~ m/WBGene\d+/) { $genes{$gene}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

print 'Database : "Wormviz"' . "\n";
print 'Name    "Wormviz"' . "\n";
print 'URL     "http:\/\/www.vanderbilt.edu\/wormdoc\/wormmap\/Welcome.html"' . "\n";
print 'URL_constructor "http:\/\/jsp.weigelworld.org\/wormviz\/tileviz.jsp?experiment=wormviz&normalization=absolute&probesetcsv=%s"' . "\n\n";


my $counter = 1030000;
foreach my $gene (sort keys %genes) {
  if ($genes{$gene} > 1) { print "Multiple $genes{$gene} for $gene\n"; }
  print qq(Expr_pattern : "Expr$counter"\nGene\t"$gene"\nPattern\t"Tiling arrays expression graphs"\nReference\t"WBPaper00037950"\nTiling Array\nDB_INFO\t"Wormviz" "id" "$gene"\n\n);
  $counter++;
} # foreach my $gene (sort keys %genes)
