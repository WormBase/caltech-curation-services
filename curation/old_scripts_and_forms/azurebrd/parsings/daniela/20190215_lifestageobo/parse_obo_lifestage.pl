#!/usr/bin/perl

use strict;

my %orphans;
my $listfile = 'list';
open (IN, "<$listfile") or die "Cannot open $listfile : $!";
while (my $line = <IN>) { chomp $line; $line =~ s/_/:/; $orphans{$line}++; }
close (IN) or die "Cannot close $listfile : $!";

$/ = "";
my $obofile = 'worm_development.obo';
open (IN, "<$obofile") or die "Cannot open $obofile : $!";
while (my $entry = <IN>) {
  my $wbls = '';
  if ($entry =~ m/id: (WBls:\d+)/) { 
    $wbls = $1;
    if ($orphans{$wbls}) { 
      chomp $entry;
      $entry .= qq(\nis_a: WBls:0000075 ! worm life stage\n\n);
  } }
  print "$entry";
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $obofile : $!";
