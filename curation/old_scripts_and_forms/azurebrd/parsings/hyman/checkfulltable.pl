#!/usr/bin/perl

$infile = "fulltable";
$outfile = "fulltableout";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<IN>) {
  ($a, $predgene, $junk, $phen, $junk2) = split("\t", $_);
  $HoA{$predgene}++;
}

foreach $_ (sort keys %HoA) {
  if ($HoA{$_} > 1) { print OUT "$_, $HoA{$_}\n"; }
}

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
