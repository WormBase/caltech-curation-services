#!/usr/bin/perl

$infile = "maeda_rnai3.ace";
# $outfile = "remarks";

open(IN, "$infile") or "die cannot close $infile : $!";
# open(OUT, ">$outfile") or "die cannot close $outfile : $!";

while (<IN>) {
  $j++;
  if ($_ =~ m/^Predicted_gene\s+\"([A-Z].*)\"/) {
    print "$1\n";
  }
  # if ( ($_ =~ m/^Remark\s+\"[A-Z]/) && ($_ !~ m/(\"F1 |\"P0 |\"L\d[- ]|no ORF name is assigned)/) ) {
    # $_ =~ s/Remark/Predicted_gene/g; 
    # print OUT;
    # print;
    # print "$j\n";
    # $i++;
  # } else {
    # print OUT;
  # }
}
# print "$i\n";
# print "$k\n";

close (IN) or die "Cannot close $outfile : $!";
# close (OUT) or die "Cannot close $outfile : $!";
