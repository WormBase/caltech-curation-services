#!/usr/bin/perl

# for ruihua to parse Michael's papers.ace for paper types.  2009 03 04

use strict;

$/ = "";
my $infile = 'papers.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($pap) = $para =~ m/Paper : \"(WBPaper\d+)\"/;
  my ($type) = $para =~ m/Type\s+\"(.*?)\"/;
  print "$pap\t$type\n";
}
close (IN) or die "Cannot close $infile : $!";
