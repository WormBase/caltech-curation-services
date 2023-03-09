#!/usr/bin/perl

$infile = "maeda_rnai.ace";
$outfile = "maeda_rnai3.ace";

open(IN, "$infile") or "die cannot close $infile : $!";
open(OUT, ">$outfile") or "die cannot close $outfile : $!";

while (<IN>) {
  $j++;
  if ($_ =~ m/^Remark\s+\"\d?[A-Z]+\d+([A-Z]+)?(\d+)?([A-Z]+)?(\d+)?\.[A-Za-z0-9]+/) {
    $_ =~ s/Remark/Predicted_gene/g; 
    print OUT;
    print "$j\n";
    $i++;
  } else {
    print OUT;
  }
}
print "$i\n";

close (IN) or die "Cannot close $outfile : $!";
close (OUT) or die "Cannot close $outfile : $!";
