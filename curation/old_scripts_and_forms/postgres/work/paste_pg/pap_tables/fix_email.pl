#!/usr/bin/perl

use strict;
my $infile = 'pap_possible';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  my @lines = split /\t/, $_;
  print "$lines[0]\t$lines[1]\t\\N\t$lines[3]";
}
