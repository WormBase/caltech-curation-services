#!/usr/bin/perl

use strict;
use diagnostics;

my $good = 'good';
my $input = 'test_names';

my %good; 

open (GOO, "<$good") or die "Cannot open $good : $!";
while (<GOO>) {
  chomp;
  my ($name, $number) = $_ =~ m/^(.*?)shows\t.*?\t(WBPerson\d+)/;
  $name =~ s/\s+$//g;
  $good{$name} = $number;
} # while (<GOO>)
close (GOO) or die "Cannot close $good : $!";

open (INP, "<$input") or die "Cannot open $input : $!";
while (<INP>) {
  chomp;
  if ($_ =~ m/^(Trained.*? )(.*)$/) {
    if ($good{$2}) { print "$1$good{$2}\n"; }
  } elsif ($_ =~ m/\w/) {
    print "$good{$_}\n";
  } else { 
    print "\n";
  }
} # while (<INP>)
close (INP) or die "Cannot close $input : $!";
