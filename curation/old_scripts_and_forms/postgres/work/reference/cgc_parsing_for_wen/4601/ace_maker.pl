#!/usr/bin/perl -w
#
# Take the output from cgc_to_endnote.pl and parse into a .ace file.
# Break the abstract into pseudo-80 col stuff.  It's not really because it just
# breaks at the first space after 70, not the last space before 80.  It's close
# but pretty ugly.

use strict;
use diagnostics;

my $infile = '/home/postgres/work/reference/cgc_parsing_for_wen/4601-4968.endnote';
my $outfile = '/home/postgres/work/reference/cgc_parsing_for_wen/4601-4968.ace';

open(OUT, ">$outfile") or die "Cannot open $outfile : $!";
open(IN, "<$infile") or die "Cannot open $infile : $!";

while (<IN>) {
  chomp;
  $_ =~ s/"/\\"/g;
  my ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract) = split/\t/, $_;
  if ($cgc =~ m/\d/) { 		# there's an entry
    print OUT "Paper\t:\t\"\[cgc$cgc\]\"\n";
    if ($authors) { 
      $authors =~ s/,//g;
      my @authors = split/\/\//, $authors;
      foreach my $author (@authors) {
        print OUT "Author\t\"$author\"\n";
      } # foreach my $author (@authors)
    } # if ($authors) 
    if ($title) { print OUT "Title\t\"$title\"\n"; }
    if ($journal) { print OUT "Journal\t\"$journal\"\n"; }
    if ($volume) { print OUT "Volume\t\"$volume\"\n"; }
    if ($pages) {
      $pages =~ s/\-/\"\t\"/g;
      print OUT "Page\t\"$pages\"\n"; 
#       unless ($pages =~ m/\-/) { 
#         print OUT "Page\t\"$pages\"\n"; 
#       } else { 
#         my @pages = split /\-/, $pages;
#         foreach my $page (@pages) {
#           print OUT "Page\t\"$page\"\n"; 
#         } # foreach my $page (@pages)
#       }
    } # if ($pages)
    if ($year) { print OUT "Year\t\"$year\"\n"; }
#     if ($abstract) { print OUT "Abstract\t\"$abstract\"\n"; }
    if ($abstract) { 
      print OUT "Abstract\t\"\[cgc$cgc\]\"\n\n"; 
      print OUT "LongText\t:\t\"\[cgc$cgc\]\"\n";
#       print OUT "$abstract\n";
      my $newword; my $i = 0;		# prepare new word and counter for newlines
      my @chars = split //, $abstract;	# split into characters
      while (scalar(@chars) > 0) {	# while there are characters unaccounted for
        $_ = shift @chars;		# get the character
        $i++; $newword .= $_;		# up the counter, append to new word
        if (($i > 70) && ($_ eq ' ')) { $i = 0; $newword .= "\n"; }
					# if more than 70 characters and a
					# space, reset counter and add a newline
      } # while (@chars)		# until all characters are accounted
      print OUT $newword . "\n";	# output the value
      print OUT "***LongTextEnd***\n";
    }
    print OUT "\n";
  } # if ($cgc)
} # while (IN)

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";

# Paper : "[wbg1.2p5a]"
# Title    "Growth of gram quantities of nematodes"
# Journal  "Worm Breeder's Gazette"
# Page     "5" -C "a"
# Volume   "1" "2"
# Year     1976
# Author   "Schachat FH"
# Brief_citation   "Schachat FH (1976) WBG. \"Growth of gram quantities of
# nematodes\""
# Abstract         "[wbg1.2p5a]"
# 
# 
# LongText : "[wbg1.2p5a]"
# Nematodes can be grown conveniently in gram quantities on plates.  
# Using the Cambridge bacterial strain, NA22 and increasing the amount 
# of Bactopeptone in NGM media from 0.25% to 2% in 0.25 steps results in 
# an approximately linear increase in yield on 8.5 cm diameter petri 
# dishes.  The settled volumes are 0.03 ml to 0.22 ml of worms per plate 
# for 0.25% and 2%, respectively.  N2, E675, and E190 have been grown 
# this way.
# 
# 
# Reference       :       "[cgc3]"
# Author                  "AbdulKader N"
# Author                  "Brun J"
# Title                   "Induction, detection and
# isolation of temperature-sensitive lethal and/or sterile mutants in
# nematodes. I. The free-living nematode C. elegans."
# Journal                 "Revue de Nematologie"
# Volume                  "1"
# Page                    "27"    "37"
# Year                    "1978"  
# Abstract                "Applying a series of techniques intended to
# induce, detect and isolate lethal and/or sterile temperature-sensitive
# mutants, specific to the self-fertilizing hermaphrodite nematode
# Caenorhabditis elegans, Bergerac strain, 25 such mutants have been
# found.  Optimal conditions for the application of mutagenic treatment and
# the detection of such mutations are discussed."
