#!/usr/bin/perl -w
#
# Take the output from cgc_to_endnote.pl and parse into a .ace file.
# Break the abstract into pseudo-80 col stuff.  It's not really because it just
# breaks at the first space after 70, not the last space before 80.  It's close
# but pretty ugly.
#
# pretty quick hack to make brief_citations for cgc #s 4401-4600.  if possible, 
# don't use this again and look at 
# /home/postgres/work/reference/andrei_pm_ace/make_ace.pl instead for a good 
# working method of dealing with Paper Reference data. (samples in this directory
# [/home/postgres/work/reference/cgc_parsing_for_wen] ace_maker.pl)  2002 03 05



use strict;
use diagnostics;

my $infile = '/home/postgres/work/reference/cgc_parsing_for_wen/4401/4401-4600.endnote';
my $outfile = '/home/postgres/work/reference/cgc_parsing_for_wen/4401/4401-4600_brief_citation.ace';

open(OUT, ">$outfile") or die "Cannot open $outfile : $!";
open(IN, "<$infile") or die "Cannot open $infile : $!";

while (<IN>) {
  chomp;
  $_ =~ s/"/\\"/g;
  my ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract) = split/\t/, $_;
  if ($cgc =~ m/\d/) { 		# there's an entry
    print OUT "Paper\t:\t\"\[cgc$cgc\]\"\n";
    my ($last, $init, $brief_title, $author);
    if ($authors) { 
      $authors =~ s/,//g;
      my @authors = split/\/\//, $authors;
      $author = $authors[0];
      ($init, $last) = $author =~ m/^(\w).* (\w+)/;
#       foreach my $author (@authors) {
#         print OUT "Author\t\"$author\"\n";
#       } # foreach my $author (@authors)
    } # if ($authors) 
#     if ($title) { print OUT "Title\t\"$title\"\n"; }
#     if ($year) { print OUT "Year\t\"$year\"\n"; }
    my $brief_title = '';                 # brief title (70 chars or less)
    my @chars = split //, $title;
    if ( scalar(@chars) < 70 ) { $brief_title = $title;
    } else {
      my $i = 0;                          # letter counter (want less than 70)
      my $word = '';                      # word to tack on (start empty, add characters)
      while ( (scalar(@chars) > 0) && ($i < 70) ) {
                                          # while there's characters, and less than 70 been read
        $brief_title .= $word;            # add the word, because still good (first time empty)
        $word = '';                       # clear word for next time new word is used
        my $char = shift @chars;          # read a character to start / restart check
        while ( (scalar(@chars) > 0) && ($char ne ' ') ) {        # while not a space and still chars
          $word .= $char; $i++;           # build word, add to counter (less than 70)
          $char = shift @chars;           # read a character to check if space
        } # while ($_ ne '')              # if it's a space, exit loop
        $word .= ' ';                     # add a space at the end of the word
      } # while ( (scalar(@chars) > 0) && ($i < 70) )
      $brief_title = $brief_title . "....";
    }
    $journal =~ s/Genes & Development/Genes and Development/g;
    print OUT "Brief_citation\t\"$author ($year) $journal. \\\"$brief_title\\\"\"\n";
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
