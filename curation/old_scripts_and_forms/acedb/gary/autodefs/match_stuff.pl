#!/usr/bin/perl

# match 2nd column of file one with 1st or 2nd column in file 2 (case
# insensitive, split on spaces) and create a 5 column file of concat.
# For Gary.  2009 07 07

use strict;

my $onefile = 'undeftermuseme.csv';
my $twofile = 'wormatlas_glossary.csv';

my %hash;
open (IN, "<$twofile") or die "Cannot open $twofile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($a, $b, $junk) = split/\t/, $line;
  ($a) = $a =~ m/^\"(.*?)\"$/;
  ($b) = $b =~ m/^\"(.*?)\"$/;
  $a = lc($a);
  $b = lc($b);
  my (@words) = split/\s+/, $a;
  foreach my $word (@words) { if ($word) { $hash{$word}{$line}++; } }
  (@words) = split/\s+/, $b;
  foreach my $word (@words) { if ($word) { $hash{$word}{$line}++; } }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $twofile : $!";

open (IN, "<$onefile") or die "Cannot open $onefile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($a, $b) = split/\t/, $line;
  ($b) = $b =~ m/^\"(.*?)\"$/;
  $b = lc($b);
  my (@words) = split/\s+/, $b;
  my $match = 0;
  foreach my $word (@words) { 
    next unless ($word);
    if ($hash{$word}) {
      foreach my $other (sort keys %{ $hash{$word} } ) {
        print "$line\t$other\n"; 
        $match++;
      }
    }
  }
  unless ($match) { print "$line\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $onefile : $!";
