#!/usr/bin/perl

# remap YH to Interaction objects based on previously generated assignYhIntID.txt  2012 02 25

use strict;

my %map;

my $mapfile = 'assignYhIntID.txt';
open (IN, "<$mapfile") or die "Cannot open $mapfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($yh, $int) = split/\t/, $line;
  my $yhline = qq(YH : "$yh");
  my $intline = qq(Interaction : "$int");
  $map{$yhline} = $intline;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $mapfile : $!";

$/ = "";
my $infile = 'Object_source_files/Citace_Minus_YH_objects.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  my @lines = split/\n/, $obj;
  if ($map{$lines[0]}) { $lines[0] = $map{$lines[0]}; }
  $obj = join"\n", @lines;
  print "$obj\n\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";
