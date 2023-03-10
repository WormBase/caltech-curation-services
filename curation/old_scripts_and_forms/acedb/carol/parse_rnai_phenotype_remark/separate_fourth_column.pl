#!/usr/bin/perl

# Check if there's data in the fourth column.  If so, print to one file, if not
# to the other.  Create outfiles named same as input ending in .withFourth or
# .withoutFourth  2006 02 17

use strict;

unless ($ARGV[0]) { print "You need to choose an inputfile\n./separate_fourth_column.pl inputfile_name\n"; die; }

my $infile = $ARGV[0];

my $withfile = $infile . ".withFourth";
my $withoutfile = $infile . ".withoutFourth";

open (WI, ">$withfile") or die "Cannot create $withfile : $!";
open (WO, ">$withoutfile") or die "Cannot create $withoutfile : $!";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my @line = split/\t/, $line;
  if ($line[3]) { print WI $line; }
    else { print WO $line; }
} # while (<IN>)

close (IN) or die "Cannot closer $infile : $!";
close (WI) or die "Cannot closer $withfile : $!";
close (WO) or die "Cannot closer $withoutfile : $!";
