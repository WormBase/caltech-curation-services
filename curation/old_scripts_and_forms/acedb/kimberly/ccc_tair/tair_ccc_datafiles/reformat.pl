#!/usr/bin/perl

use strict;

my @files = qw( results_2008_ccc_and_genesarabidopsis  results_2008_in_geneassociation  results_2008_not_geneassociation );

foreach my $file (@files) {
  my @data;
  my $count = 0;
  open (IN, "<$file") or die "Cannot open $file : $!"; 
  while (my $line = <IN>) {
    $count++;
    my ($old_num, @stuff) = split/\t/, $line;
    unshift @stuff, $count;
    unshift @stuff, $file;
    $line = join"\t", @stuff;
    push @data, $line;
  }
  close (IN) or die "Cannot close $file : $!"; 
  open (OUT, ">$file") or die "Cannot open $file : $!"; 
  foreach my $line (@data) { print OUT $line; }
  close (OUT) or die "Cannot close $file : $!"; 
}

