#!/usr/bin/env perl

# phenotype_history.html.bk has 13GB of data, but less than a month ago it was only 20MB
# This splits file into lines smaller than 100000 characters into a filtered file, and
# lines larger into their own files for someone to look at.  Those files have a ton of 
# junk characters in the middle of some text.  2024 03 27

use strict;

# my $infile = '/usr/caltech_curation_files/pub/cgi-bin/data/phenotype_history.html';
my $infile = '/usr/caltech_curation_files/pub/cgi-bin/data/phenotype_history.html.bk';

my $outfile = 'filtered';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $count = 0;
open (IN, "<$infile") or die "Cannot open $infile :$!";
while (my $line = <IN>) {
  chomp $line;
  $count++;
  my $len = length($line);
  if ($len > 100000) {
    print qq(HUGE\t$count\t$len\n);
    my $linefile = 'lines/' . $count . '_' . $len;
    open (LIN, ">$linefile") or die "Cannot create $linefile : $!";
    print LIN qq($line\n);
    close (LIN) or die "Cannot close $linefile : $!";
  } else {
    print OUT qq($line\n);
  }
  if ($count % 1000 == 0) { 
    print qq($count\t$len\n);
  }
#   last if ($count > 200);
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile :$!";

close (OUT) or die "Cannot close $outfile : $!";
