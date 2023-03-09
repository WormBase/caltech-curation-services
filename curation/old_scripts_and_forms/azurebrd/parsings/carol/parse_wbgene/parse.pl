#!/usr/bin/perl

# Date: Thu, 04 Jan 2007 13:04:47 -0800
# From: Carol Bastiani <bastiani@its.caltech.edu>
# To: Juancarlos Chan <azurebrd@mark.ugcs.caltech.edu>
# Subject: compare two lists
# 
# Hi Juancarlos,
# If you have time, could you remove all lines from Gene_cgcname_allele_01-2007_2
# that are
# lacking the 2nd column (cgc name).  Then could you delete any lines in
# Gene_cgcname_allele_01-2007_2 that do not have a name in the third column that
# matches one
# of the names in allele_names_01-2007 list?
# 
# Thanks very much,
# Carol
#
# 2007 01 04


my $infile = 'allele_names_01-2007';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) { chomp; $hash{$_}++; }
close (IN) or die "Cannot close $infile : $!";

$infile = 'Gene_cgcname_allele_01-2007_2';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { 
  chomp $line;
  my @stuff = split/\t/, $line;
  next unless $stuff[1];
  next unless ($hash{$stuff[2]});
  print "$line\n";
}
close (IN) or die "Cannot close $infile : $!";
