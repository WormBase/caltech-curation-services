#!/usr/bin/perl

$sequences = "hyman.sequences";
$hymanold = "hyman.old";
$outfile = "missingsequences";

open (SEQ, "$sequences") or die "Cannot open $sequences : $!";
open (HYM, "$hymanold") or die "Cannot open $hymanold : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<SEQ>) {
  if ($_ =~ m/^RNAi TH:.*? (\d{1,}) (\d{1,})$/) {
    $position = "${1}" . "-" . "${2}";
# print "$position\n";
    $HoA{$position}++;
  }
}

while (<HYM>) {
  if ($_ =~ m/^Position: .*?: (\d{1,}-\d{1,})$/) {
    $position = $1;
# print "$position\n";
    $HoA{$position}++;
  }
}

foreach $_ (sort keys %HoA) {
  if ($HoA{$_} != 2) { print OUT "$_, $HoA{$_}\n"; }
}

close (SEQ) or die "Cannot close $sequences : $!";
close (HYM) or die "Cannot close $hymanold : $!";
close (OUT) or die "Cannot close $outfile : $!";
