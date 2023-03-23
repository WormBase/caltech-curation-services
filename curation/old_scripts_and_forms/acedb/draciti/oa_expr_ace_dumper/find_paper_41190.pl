#!/usr/bin/perl

# get expr objects that have this Yanai paper  2012 10 03

use strict;

my $infile = 'expr_pattern.ace.20121003';
my $outfile = 'expr_pattern_WBPaper00041190.ace';

$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
while (my $para = <IN>) {
  if ($para =~ m/WBPaper00041190/) { print OUT "$para"; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
