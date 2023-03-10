#!/usr/bin/perl

use strict;

my $infile = '/home/postgres/work/pgdumps/testdb.dump.latest';

my $count = 0;

my $start = 4577882;
my $end = 4578316;


open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  $count++;
  if ( ($count > $start) && ($count < $end) ) { print $line; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

