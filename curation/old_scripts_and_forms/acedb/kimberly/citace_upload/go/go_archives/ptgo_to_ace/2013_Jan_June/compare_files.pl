#!/usr/bin/perl

# compare postgres dump with tony's ptgo file to see what's in one and not in the other.  suppress Date_last_updated since only the one file has it.  2013 04 02


use strict;

my $gpfile = 'gp_association.ace';
my $pgfile = 'go.ace.20130228.102422';

my %pg; my %gp;
$/ = "";
open (IN, "<$gpfile") or die "Cannot open $gpfile : $!";
while (my $para = <IN>) { 
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  foreach (@lines) { 
    next if ($_ =~ m/Date_last_updated/);
    $gp{$header}{$_}++; }
} # while my ($para = <IN>)
close (IN) or die "Cannot close $gpfile : $!";

open (IN, "<$pgfile") or die "Cannot open $pgfile : $!";
while (my $para = <IN>) { 
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  foreach (@lines) { 
    next if ($_ =~ m/Date_last_updated/);
    $pg{$header}{$_}++; }
} # while my ($para = <IN>)
close (IN) or die "Cannot close $pgfile : $!";
$/ = "\n";

foreach my $header (sort keys %pg) { 
  foreach my $line (sort keys %{ $pg{$header} } ) { 
    unless ($gp{$header}{$line}) { print "IN PG NOT GP $header : $line\n"; } } }

foreach my $header (sort keys %gp) { 
  foreach my $line (sort keys %{ $gp{$header} } ) { 
    unless ($pg{$header}{$line}) { print "IN GP NOT PG $header : $line\n"; } } }

