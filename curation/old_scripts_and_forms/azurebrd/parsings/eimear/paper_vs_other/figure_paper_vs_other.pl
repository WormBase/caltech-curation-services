#!/usr/bin/perl

# see /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/xref_tables

# take list from eimear, create 6 xref tables to connect wbpapers with other
# types (and self).  2004 09 15

use strict;

my $infile = '/home/acedb/public_html/paper2wbpaper.txt';

my %hash;

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if (/cgc/) { $hash{cgc}{$_}++; } 

  elsif (/pmid/) { $hash{pmid}{$_}++; } 
  elsif (/PMID/) { $hash{pmid}{$_}++; } 
  elsif (/med/) { $hash{med}{$_}++; } 

  elsif (/wm/) { $hash{wm}{$_}++; } 

  elsif (/wbg/) { $hash{wbg}{$_}++; } 
  elsif (/wb/) { $hash{wbg}{$_}++; } 

  elsif (/cam/) { $hash{cam}{$_}++; } 
  elsif (/CSHS/) { $hash{oth}{$_}++; } 
  elsif (/isbn/) { $hash{oth}{$_}++; } 
  else { print "ERROR $_\n"; }
}

# joinkey (wpap)  wpap (duplicates)  cgc  pmid  wm  wbg  other  last_timestamp   orig_timestap
