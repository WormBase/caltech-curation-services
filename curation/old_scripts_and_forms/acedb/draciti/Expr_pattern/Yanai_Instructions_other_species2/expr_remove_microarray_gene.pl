#!/usr/bin/perl

# remove ", WBGene\d+" from Microarray_results lines in .ace files, from backup file.  2015 01 06

use strict;

my @files = qw( expr_briggsae.ace expr_japonica.ace expr_remanei.ace );

foreach my $file (@files) {
  my $outfile = $file;
  my $infile = $file . '.backup';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
  while (my $line = <IN>) {
    if ($line =~ m/Microarray_results.*?(, WBGene\d+)"/) { $line =~ s/$1//g; }
    print OUT $line;
  } # while (my $line = <IN>)
  close (OUT) or die "Cannot close $outfile : $!";
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $file (@files)

