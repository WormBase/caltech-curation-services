#!/usr/bin/perl
# this file catches rnai data mistakenly put into Phenotype Description

$infile = "hyman.old";

open (IN, "$infile") or die "Cannot open $infile : $!";

while (<IN>) {
  if ($_ =~ m/^Phenotype Description: \d{3}[A-Za-z]\d{1,2}.*\b/) {
    print; $i++;
  }
}
print "$i\n";
