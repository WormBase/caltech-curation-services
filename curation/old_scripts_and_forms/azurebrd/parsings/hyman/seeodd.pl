#!/usr/bin/perl -w

# $infile = "hyman.old";
$infile = "hyman.txt";

open (IN, $infile) or die "Cannot open $infile : $!";

$/ = "";

while (<IN>) {
  ($a, @lala) = split /\n/, $_;
  print "$a\n";
}


while (<IN>) {
  chomp;
  if ($_ =~ m/^Author/) { }
  elsif ($_ =~ m/^$/) { }
  elsif ($_ =~ m/^Date/) { }
  elsif ($_ =~ m/^RNAi/) { }
  elsif ($_ =~ m/^Predicted Gene/) { }
  elsif ($_ =~ m/^Primers/) { }
  elsif ($_ =~ m/^Position/) { }
  elsif ($_ =~ m/^Laboratory/) { }
  elsif ($_ =~ m/^PCR_product/) { }
  elsif ($_ =~ m/^Phenotype/) { }
  elsif ($_ =~ m/^Progeny/) { 
    ($a, $b) = split(":", $_);
    print "$b\n";
  }
  else { print; }
}
