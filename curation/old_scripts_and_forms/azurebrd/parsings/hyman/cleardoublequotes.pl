#!/usr/bin/perl
# hack to get rid off double doublequotes.

$infile = "hyman.old.parsed";
$outfile = "hyman.old.parsed.2";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

while (<IN>) {
  $_ =~ s/\"\"/\"/g;
  print OUT;
}

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
