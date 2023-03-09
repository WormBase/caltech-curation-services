#!/usr/bin/perl
# This prog checks to see if all Sequence entries have entries

$infile = "edit2.ace";

open (IN, "$infile") or die "Cannot open $infile";

while (<IN>) {
  print if /^Sequence/;
}
