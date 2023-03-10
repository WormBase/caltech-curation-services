#!/usr/bin/perl

# find what's so different between dumps based on lines in a ``paragraph''   2010 04 19

use strict;

my $smallfile = 'testdb.dump.201004280200';
my $bigfile = 'testdb.dump.201004270200';

$/ = "";

my %hash;

open (IN, "<$bigfile") or die "Cannot open $bigfile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  $hash{big}{$lines[0]} = scalar(@lines);
} # while (my $para = <IN>)
close (IN) or die "Cannot close $bigfile : $!";

open (IN, "<$smallfile") or die "Cannot open $smallfile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  $hash{small}{$lines[0]} = scalar(@lines);
} # while (my $para = <IN>)
close (IN) or die "Cannot close $smallfile : $!";

foreach my $header (sort keys %{ $hash{big} }) {
  if ($hash{big}{$header} ne $hash{small}{$header}) { 
    my $diff = $hash{big}{$header} - $hash{small}{$header};
    if ( ($diff > 99) || ($diff < -99) ) {
      print "$header B $hash{big}{$header} S $hash{small}{$header} E\n";
    }
  }
} # foreach my $header (sort keys %{ $hash{big} })
