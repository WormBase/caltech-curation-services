#!/usr/bin/perl
# This takes the results from the pre-parsed data and gets the Sequence entries.

$infile = "hyman.txt";
$outfile = "hyman.sequences";

$/ = "";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<IN>) {
  if ($_ =~ m/^Sequence/) { print OUT; $i++; }
}
print $i ."\n";

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
