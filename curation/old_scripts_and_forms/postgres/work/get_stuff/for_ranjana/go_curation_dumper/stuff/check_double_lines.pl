#!/usr/bin/perl

# check that no lines are repeated in the go.go file.
# for Ranjana  2005 03 31

my $infile = $ARGV[0];

my %lines;

open(IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  $lines{$_}++;
} # while (<IN>)
close(IN) or die "Cannot close $infile : $!";

foreach my $line (sort keys %lines) {
  if ($lines{$line} > 1) {
    print "TOO MANY $lines{$line} : $line";
  }
} # foreach my $line (sort keys %lines)
