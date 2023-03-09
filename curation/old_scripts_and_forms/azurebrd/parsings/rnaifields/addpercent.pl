#!/usr/bin/perl

$infile = "rnaiout";
$outfile = "rnaiout2";

open(IN, "$infile") or die "Cannot open $infile : $!";
open(OUT, ">$outfile") or die "Cannot open $outfile : $!";

while (<IN>) {
  print OUT;
  if ($_ =~ m/^Phenotype\s+(\"\w\w\w\")\s+Penetrance\s\d+/) {
    print OUT "Phenotype\t$1\tRemark\t\"\%penetrance\"\n";
  }
}
    
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";

