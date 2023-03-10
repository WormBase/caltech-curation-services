#!/usr/bin/perl

use strict;

my %hash;
my $infile = 'out';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($wb, $name) = split/\t/, $line;
  push @{ $hash{$name} }, $wb;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $name (sort keys %hash) {
  if ( scalar(@{ $hash{$name} }) > 1 ) { 
    my $blah = join", ", @{ $hash{$name} };
    print "There are " . scalar(@{ $hash{$name} }) . " names $name : " . $blah . "\n";  }
} # foreach my $name (sort keys %hash)
