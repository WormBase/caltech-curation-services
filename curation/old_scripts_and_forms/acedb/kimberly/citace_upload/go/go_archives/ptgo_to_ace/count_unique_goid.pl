#!/usr/bin/perl

# count unique goids in infile for Kimberly and Ranjana.  2013 12 09

use strict;

my %hash;
my $infile = 'gp_association.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/(GO:\d+)/) {
    my (@goids) = $line =~ m/(GO:\d+)/g;
    foreach (@goids) { $hash{$_}++; }
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my $count = scalar keys %hash;
print "There are $count unique GOIDs in $infile\n";
