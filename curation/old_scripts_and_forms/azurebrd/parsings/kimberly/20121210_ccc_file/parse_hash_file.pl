#!/usr/bin/perl

# hash into col1 => unique col2 with ;-separation.  for kimberly 2012 12 10

use strict;
use warnings;

my %hash;

my $infile = 'file_ccc.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($one, $two) = split/\t/, $line;
  $hash{$one}{$two}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $one (sort keys %hash) {
  my $two = join";", sort keys %{ $hash{$one} };
  print "$one\t$two\n";
} # foreach my $one (sort keys %hash)
