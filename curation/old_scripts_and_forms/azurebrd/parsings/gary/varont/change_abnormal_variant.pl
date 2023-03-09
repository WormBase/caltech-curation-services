#!/usr/bin/perl

# copy abnormal names to synonyms with NARROW [] and change them to variant
# 2008 09 29

use strict;

# my $infile = 'PhenOnt.obo';
# my $outfile = 'VarOnt.obo';
my $infile = 'extravaront.obo';
my $outfile = 'changedvaront.obo';

$/ = "";

open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my @lines = split/\n/, $para;
  foreach my $line (@lines) {
    if ($line =~ m/name:\s+(.*?abnormal.*?)/) { 
      my $syn = $1;
      push @lines, "synonym: \"$1\" NARROW \[\]";
      $line =~ s/abnormal/variant/g; } }
  my $para = join"\n", @lines;
  print OUT "$para\n\n"; 
} # while (my $para = <IN>)

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
