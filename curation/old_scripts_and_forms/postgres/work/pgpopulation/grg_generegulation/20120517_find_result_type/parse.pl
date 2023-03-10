#!/usr/bin/perl

# in GR_OA.ace look for Does_not_regulate Positive_regulate Negative_regulate without subtags afterward.
# in backup/ look for entries with grg_result, but not grg_anat_term grg_lifestage grg_subcellloc grg_subcellloc_text

use strict;

my %hash;
my @files = qw( result anat_term lifestage subcellloc subcellloc_text name );

foreach my $filename (@files) {
  my $file = 'backup/grg_' . $filename . '.pg';
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($pgid, $data, $timestamp) = split/\t/, $line;
    $hash{$pgid}{$filename} = $data;
  } # while (my $line = <IN>)
  close (IN) or die "Cannot open $file : $!";
} # foreach my $file (@files)

my %filter;
foreach my $pgid (sort keys %hash) {
  my $name; my $result;
  if ($hash{$pgid}{name}) { $name = $hash{$pgid}{name}; } 
    else { print "ERR no name for $pgid\n"; }
  if ($hash{$pgid}{result}) { 
    $result = $hash{$pgid}{result}; 
    my $hasOther = 0;
    if ($hash{$pgid}{anat_term}) { $hasOther++; }
    if ($hash{$pgid}{lifestage}) { $hasOther++; }
    if ($hash{$pgid}{subcellloc}) { $hasOther++; }
    if ($hash{$pgid}{subcellloc_tex}) { $hasOther++; }
    unless ($hasOther) { $filter{$name}{$result}++; }
  }
} # foreach my $pgid (sort keys %hash)

foreach my $objName (sort keys %filter) {
  my $types = join", ", sort keys %{ $filter{$objName} };
  print "$objName\t$types\n";
} # foreach my $objName (sort keys %filter)

__END__

my %aceHash;
my @single = qw( Does_not_regulate Positive_regulate Negative_regulate );
$/ = "";
my $infile = 'GR_OA.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($header, @lines) = split/\n/, $para;
  my $objName = '';
  if ($header =~ m/Gene_regulation : "(.*?)"/) { $objName = $1; }
  foreach my $line (@lines) { 
    foreach my $single (@single) {
      if ($line =~ m/^$single\s*$/) { $aceHash{$objName}{$single}++; }
  } }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $objName (sort keys %aceHash) {
  my $types = join", ", sort keys %{ $aceHash{$objName} };
  print "$objName\t$types\n";
} # foreach my $objName (sort keys %aceHash)

__END__

Gene_regulation : "cgc1664_mec-3.a"

