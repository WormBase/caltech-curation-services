#!/usr/bin/perl

use strict;

my $infile = 'filtered_akas.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my %last; my %first; my %middle;

  my ($person) = $entry =~ m/^Person\tWBPerson(\d+)/;
  my @lines = split/\n/, $entry;
  foreach my $line (@lines) {
    if ($line =~ m/first/) { 
      my ($value) = $line =~ m/first\t(.*) -O /;
      $first{$value}++;
      my ($init) = $value =~ m/^(\w)/;
      $first{$init}++;
    }
    if ($line =~ m/middle/) { 
      my ($value) = $line =~ m/middle\t(.*) -O /;
      $middle{$value}++;
      my ($init) = $value =~ m/^(\w)/;
      $middle{$init}++;
    }
    if ($line =~ m/last/) { 
      my ($value) = $line =~ m/last\t(.*) -O /;
      $last{$value}++;
    }
  } # foreach my $line (@lines)
  my %aka_hash;		# filter output of name compinations
  my $possible = '';
  foreach my $last (sort keys %last) {
    foreach my $first (sort keys %first) {
      if (%middle) { 
        foreach my $middle (sort keys %middle) {
          $possible = "$first"; $aka_hash{$possible}++;
          $possible = "$middle"; $aka_hash{$possible}++;
          $possible = "$last"; $aka_hash{$possible}++;
          $possible = "$last $first"; $aka_hash{$possible}++;
          $possible = "$last $middle"; $aka_hash{$possible}++;
          $possible = "$last $first $middle"; $aka_hash{$possible}++;
          $possible = "$last $middle $first"; $aka_hash{$possible}++;
          $possible = "$first $last"; $aka_hash{$possible}++;
          $possible = "$middle $last"; $aka_hash{$possible}++;
          $possible = "$first $middle $last"; $aka_hash{$possible}++;
          $possible = "$middle $first $last"; $aka_hash{$possible}++;
        } # foreach my $middle (sort keys %middle)
      } else { 
        $possible = "$first"; $aka_hash{$possible}++;
        $possible = "$last"; $aka_hash{$possible}++;
        $possible = "$last $first"; $aka_hash{$possible}++;
        $possible = "$first $last"; $aka_hash{$possible}++;
      }
    } # foreach my $first (sort keys %first)
  }
  print "Person\tWBPerson$person\n";
  foreach my $aka_entry (sort keys %aka_hash) { print "$aka_entry\n"; }
  print "\n";
} # while (<IN>)
$/ = "\n";
