#!/usr/bin/perl
# This takes the results from the pre-parsed data and gets the Sequence entries.

$infile = "hyman.old";
$outfile = "hyman.position";

$/ = "";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<IN>) {
  @stuff = split("\n", $_);
  foreach $_ (@stuff) {
    if ($_ =~ m/^Position/m) { $i++; $j++; print "$_\n";}
    else { print OUT; $j++;}
  }
}
print "what the hell $i $j \n";

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
