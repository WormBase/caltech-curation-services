#!/usr/bin/perl

# get rid of 3rd column, append prefix to second column if there's data there
# check no duplicates of first column, check formatting of first and second
# column data.  2008 04 29

my $infile = '/home/acedb/kimberly/parse_two_tabs/gp2protein189.txt';

my %genes;

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($one, $two, $three) = split/\t/, $line;
  unless ($one =~ m/WB:WBGene\d{8}/) { print "ERR col1 not in format WB:WBGenexxxxxxxx : $line\n"; }
  if ($two) { 
    unless ($two =~ m/.{6}/) { print "ERR col2 not 6 characters : $line\n"; }
    $two = 'UniProtKB:' . $two; }
  $genes{$one}++;
  print "$one\t$two\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $gene (sort keys %genes) {
  if ($genes{$gene} > 1) { print "ERR $gene has $genes{$gene} instances\n"; } }

my $infile2 = 'mart_export_all_genes_WS189.txt';
open (IN, "<$infile2") or die "Cannot open $infile2 : $!";
while (my $line = <IN>) {
  chomp $line;
  my $thing = 'WB:' . $line;
  unless ($genes{$thing}) { print "$line not in $infile\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile2 : $!";
