#!/usr/bin/perl

# script to match existing acedb med papers with cgc papers based on various
# title volume page first author   for eimear.  2003 10 13
#
# adapted to only use cgc's for daniel.  2004 02 18

use strict;
use diagnostics;

my %hash;
my %all_med;		# hash of medline papers, key med number

# my $infile = 'cgc_med_papers.ace';
my $infile = 'citacePersonPaper20040218.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  next unless ( ($entry =~ m/^Paper : \"\[cgc/) || ($entry =~ m/^Paper : \"\[pmid/) );

# ONE : find completely same entry  :  Gives Person or Sequence only entries
#   $entry =~ s/^Paper : \"\[(.*?)\]\"\n//g;
#   push @{ $hash{$entry} }, $1;

# TWO : titles match
  next unless ($entry =~ m/Title/);
  my ($title) = $entry =~ m/Title\t \"(.*?)\"/;
  my ($paper) = $entry =~ m/Paper : \"\[(.*?)\]\"/;
#   push @{ $hash{$title} }, $paper;
  if ($paper =~ m/med/) { $all_med{$paper}++; }

# THREE : volume and title match
  next unless ($entry =~ m/Volume/);
  my ($volume) = $entry =~ m/Volume\t \"(.*?)\"/;
  my $key = $volume . $title;
#   push @{ $hash{$key} }, $paper;

# FOUR : page and volume and title match
  next unless ($entry =~ m/Page/);
  my ($page) = $entry =~ m/Page(?:\s+)\"(.*?)\"/;
  $key = "$volume $page $title";
#   push @{ $hash{$key} }, $paper;

# FIVE : first author and page and volume and title match
  next unless ($entry =~ m/Author/);
  my ($author) = $entry =~ m/Author(?:\s+)\"(.*?)\"/;
  $key = "$author ";		# don't understand why get errors if in one line 
  $key .= "$volume $page $title";
#   push @{ $hash{$key} }, $paper;

# SIX : first author and page and volume match
  $key = "$author ";		# don't understand why get errors if in one line 
  $key .= "$volume $page";
#   push @{ $hash{$key} }, $paper;

# SEVEN : first author and page and volume and 10chars of title match
  $title = lc($title);
  $title =~ s/caenorhabditis/c./g;
  $title =~ s/\.//g;
  my $title30 = $title;
  if ($title =~ m/.{30}/) { ($title30) = $title =~ m/^(.{30})/g; }
  $key = "$author ";		# don't understand why get errors if in one line 
  $key .= "$volume $page $title30";
#   push @{ $hash{$key} }, $paper;

} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $entry (sort keys %hash) {
  if (scalar( @{ $hash{$entry} }) > 1) { 
    foreach (@ {$hash{$entry}}) { 
      print "$_\n"; 
      delete $all_med{$_}; 
    }
    print "$entry\n\n"; 
  }
} # foreach my $entry (sort keys %hash)

# foreach my $med_left (sort keys %all_med) {
#   print "$med_left\n";
# } # foreach my $med_left (sort keys %all_med)
