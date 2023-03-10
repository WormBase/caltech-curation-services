#!/usr/bin/perl

# grep through two_street for words that may imply institute for Cecilia
# 2004 04 06

use strict;

my $infile = 'two_street';
my %hash;

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ( ($_ =~ m/College/) || ($_ =~ m/Institut/) || ($_ =~ m/University/) || 
       ($_ =~ m/School/) || ($_ =~ m/UC/) || ($_ =~ m/Caltech/) || ($_ =~ m/MIT/) ||
       ($_ =~ m/Foundation/) || ($_ =~ m/Instituto/) || ($_ =~ m/Centre/) || ($_ =~ m/Laboratoire/) ||
       ($_ =~ m/U of/) || ($_ =~ m/Universitaet/) || ($_ =~ m/CNRS/) || ($_ =~ m/UMR/) ||
       ($_ =~ m/Medical Center/) || ($_ =~ m/USDA/) || ($_ =~ m/Exelixis/) || ($_ =~ m/M\.I\.T/) ||
       ($_ =~ m/UNC/) || ($_ =~ m/NASA/) || ($_ =~ m/Wellcome/) || ($_ =~ m/Clinic/) ||
       ($_ =~ m/NCSU/) || ($_ =~ m/NC State/) || ($_ =~ m/ISREC/) || ($_ =~ m/Lab/) ||
       ($_ =~ m/Research/) || ($_ =~ m/BMS/) || ($_ =~ m/Bristol Myers/) || ($_ =~ m/Max-Planck/) ||
       ($_ =~ m/Health/) )
     { 
       my ($joinkey) = $_ =~ m/^(two\d+)/;
       push @{ $hash{$joinkey} }, $_;
     }
}

foreach my $joinkey (sort keys %hash) {
  if (scalar(@{ $hash{$joinkey} }) > 1) { print "DOUBLE $joinkey\n"; }
  foreach (@{ $hash{$joinkey} }) { print; }
}
