#!/usr/bin/perl

# Raymond wants text with *neuron* case insensitive for a grant proposal.  2021 05 21

use strict;

$/ = "";
my $infile = 'anat_func.ace';

my $posCount = 0;
my $negCount = 0;

my $posfile = 'neuron.ace';
my $negfile = 'not_neuron.ace';
open (POS, ">$posfile") or die "Cannot create $posfile : $!";
open (NEG, ">$negfile") or die "Cannot create $negfile : $!";

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  if ($entry =~ m/neuron/i) { 
    print POS qq($entry);
    $posCount++;
  } else {
    print NEG qq($entry);
    $negCount++;
  }
}
close (IN) or die "Cannot open $infile : $!";

print qq($posCount entries with 'neuron'\n);
print qq($negCount entries without 'neuron'\n);

close (POS) or die "Cannot close $posfile : $!";
close (NEG) or die "Cannot close $negfile : $!";
