#!/usr/bin/perl

# For Kimberly, count how many something of other have a C, F, P, or any-at-all 
# entry.  She thought we should deal with IEA and non-IEA differently, but 
# turns out some have both types of entries, so just stripping the last letter
# of all entries instead.  2005 03 08

use strict;
use diagnostics;

my %theHash;

# my %checkHash;	# check that IEAs don't overlap others

# my $infile = 'thing';
# my $infile = '/home/azurebrd/work/parsings/ranjana/go_bad_tabs/gene_association.wb';
my $infile = 'gene_association3.wb';

# This was to check whether there were any on column 3 that had IEA and non-IEA,
# since this is so, will now treat IEAs and non-IEAs the same, that is : strip
# last letter from column 3 regardless of what is.
#
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) {
#   my ($a, $b, $identifier, $d, $e, $f, $evidence, $h, $type) = split/\t/, $line;
#   $identifier = lc($identifier);
# # print "BEFORE $identifier\n";
#   $identifier =~ s/(\.\d+)[a-z]+/$1/;	# always strip letter for checking
# # print "AFTER $identifier\n";
#   if ($evidence eq 'IEA') {
#     $checkHash{$identifier}{'IEA'}++;
#     if ($checkHash{$identifier}{'notIEA'}) { print "ERROR $identifier has not-IEA and IEA\n"; }
#   } else {
#     $checkHash{$identifier}{'notIEA'}++;
#     if ($checkHash{$identifier}{'IEA'}) { print "ERROR $identifier has IEA and not-IEA\n"; }
#   }
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $infile : $!";

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my ($a, $b, $identifier, $d, $e, $f, $evidence, $h, $type) = split/\t/, $line;
  $identifier = lc($identifier);
  $identifier =~ s/(\.\d+)[a-z]+/$1/;	# always strip letter regardless of whether IEA or not
#   if ($evidence eq 'IEA') { $identifier =~ s/(\.\d+)[a-z]+/$1/; }
  $theHash{$type}{$identifier}++;
  $theHash{"any"}{$identifier}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $type (sort keys %theHash) {
  print "$type : " . scalar(keys %{ $theHash{$type} }) . "\n";
} # foreach my $type (sort keys %theHash)
