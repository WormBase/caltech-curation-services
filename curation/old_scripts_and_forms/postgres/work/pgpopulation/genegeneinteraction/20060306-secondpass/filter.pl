#!/usr/bin/perl

# Take full list from textpresso, and list of wbpapers already done, and make
# a filtered list of new sentences only.  2006 03 08

my $both_file = 'wbboth2';
my $full_file = 'full_20060307.txt';
my $filtered_file = 'filter_20060307.txt';

my %done;
open (IN, "<$both_file") or die "Cannot open $both_file : $!";
while (<IN>) { if ($_ =~ m/PAP (WBPaper\d+)/) { $done{$1}++; } }
close (IN) or die "Cannot close $both_file : $!";

open (IN, "<$full_file") or die "Cannot open $full_file : $!";
open (OUT, ">$filtered_file") or die "Cannot open $filtered_file : $!";
while (my $line = <IN>) { 
  if ($line =~ m/^\S+(WBPaper\d+) :/) {
    unless ($done{$1}) { print OUT $line; } } }
close (IN) or die "Cannot close $full_file : $!";
close (OUT) or die "Cannot close $filtered_file : $!";
