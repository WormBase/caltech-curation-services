#!/usr/bin/perl

# For Daniela 
# for all the terms that have 'Ce' as suffix in the 'name' line
# name: embryo Ce
# add a line to the object as follows
# synonym: "name_without_the_suffix" BROAD []
# in this case it will be 
# synonym: "embryo" BROAD []
# 2016 07 12


use strict;

my $infile = 'worm_development.obo';
my $outfile = 'worm_development.obo.out';

open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
while (my $line = <IN>) {
  print OUT $line;
  if ($line =~ m/^name: (.*?) Ce$/) { print OUT qq(synonym: "$1" BROAD []\n); }
} # while ($line = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
