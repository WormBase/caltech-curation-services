#!/usr/bin/perl

use strict;
use diagnostics;

my $raymond_file = "/home/postgres/work/pgpopulation/datafromoldform/raymond.txt";
my $wen_file = "/home/postgres/work/pgpopulation/datafromoldform/wen_from_athena.txt";

my %rayhash;
my %wenhash;
my %allhash;

open(RAY, "<$raymond_file") or die "Cannot open $raymond_file : $!";
$/ = "";
while (<RAY>) {
  if ($_ =~ m/pubID :\s+"(.*)"/) {
    my $temp = $1;
    $temp = uc($temp);
    unless ( ($temp =~ m/TEST/) || ($temp =~ m/N\/A/) ) { $rayhash{$temp}++; $allhash{$temp}++; }
  } # if ($_ =~ m/pubID :\s+"(.*)"/) 
} # while (<RAY>) 
$/ = "\n";
close(RAY) or die "Cannot close $raymond_file : $!";

open(WEN, "<$wen_file") or die "Cannot open $wen_file : $!";
$/ = "";
while (<WEN>) {
  if ($_ =~ m/pubID :\s+"(.*)"/) {
    my $temp = $1;
    $temp = uc($temp);
    unless ( ($temp =~ m/TEST/) || ($temp =~ m/N\/A/) ) { $wenhash{$temp}++; $allhash{$temp}++; }
  } # if ($_ =~ m/pubID :\s+"(.*)"/) 
} # while (<WEN>) 
$/ = "\n";
close(WEN) or die "Cannot close $wen_file : $!";

print "Ray : " . scalar(keys %rayhash) . "\n";
# foreach $_ (sort keys %rayhash) {
#   print $_ . "\n";
#   if ($rayhash{$_} > 1) { print $_ . "\t" . $rayhash{$_} . "\n"; }
# } # foreach $_ (sort keys %rayhash) 

print "Wen : " . scalar(keys %wenhash) . "\n";
# foreach $_ (sort keys %wenhash) {
#   print $_ . "\n";
# } # foreach $_ (sort keys %wenhash) 

print "All : " . scalar(keys %allhash) . "\n";
