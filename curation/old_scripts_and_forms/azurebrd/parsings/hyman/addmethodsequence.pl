#!/usr/bin/perl 
# This takes in from edit1.ace and writes to the entries a Sequence and Method
# entry outputting to edit2.ace.

$infile = "edit1.ace";
$outfile = "edit2.ace";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

$/ = "";

while (<IN>) {
  if ($_ =~ m/^Sequence/) { print OUT; }
  if ($_ =~ m/^RNAi/) {
    ($a, @rest) = split("\n", $_);
    @lines = split("\n", $_);
    foreach $_ (@lines) {
      if ($_ =~ m/^Predicted_gene (.*?)\.\d{1,}.*?$/) {
        $sequence = $1; print "$sequence \n";
      }
    }
    print OUT "$a\n";
    print OUT "Method \t RNAi\n";
    print OUT "Sequence \t $sequence\n";
    foreach $_ (@rest) {
      print OUT "$_\n";
    }
    print OUT "\n";
  }
}
