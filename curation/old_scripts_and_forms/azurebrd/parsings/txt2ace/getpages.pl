#!/usr/bin/perl
#
# Program to find pages from txt files

$sampletext = sampletext;

open (TEXT, "$sampletext") || die "cannot open $textfile : $!";

while (<TEXT>) {
  if ($_ =~ m/\D+(\d+)\-(\d+)\./) { 
    $muk = "$1-$2\n";
    print $muk;
    # $diff = $2 - $1;
    # if (($diff < 0) || ($diff > 100)) { #print "$1 : $2\n"; 
#print; }
    # print;
  }
}

close (TEXT) || die "cannot close $textfile : $!";
