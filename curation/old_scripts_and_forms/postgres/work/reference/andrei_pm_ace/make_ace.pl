#!/usr/bin/perl -w
#
# Make Paper Reference entries for the PMID papers curated.  
# This will be edited to be a cronjob that runs every week and checks data from 
# the previous 7 days.					- 2002 03 05

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pmids;		# hash of pmids that have been curated
my $acefile = "/home/postgres/work/reference/andrei_pm_ace/pm_reference.ace";
my $errorfile = "/home/postgres/work/reference/andrei_pm_ace/errorfile";

open (ACE, ">$acefile") or die "Cannot create $acefile : $!";
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";

my $result = $conn->exec( "SELECT * FROM cur_curator WHERE joinkey ~ 'pmid';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pmids{$row[0]}++; }
} # while (@row = $result->fetchrow)

foreach my $pmid (sort keys %pmids) { 
  my @ref = qw(ref_title ref_journal ref_volume ref_year); 
  # ref_pages ref_author ref_abstract ref_pmid);
# my @ref = qw(ref_title ref_journal ref_pages ref_volume ref_year ref_author ref_abstract ref_pmid);
  my $result = $conn->exec( "SELECT * FROM ref_author WHERE joinkey = '$pmid';" );
  while (my @row = $result->fetchrow) {		# only goes in loop if there's result to SELECT
    print ACE "Paper :\t\"[$pmid]\"\n";
    my $brief_citation = "Brief_citation\t\"";
    my $title = ''; my $year = '';
    foreach my $ref_field (@ref) {
      $result = $conn->exec( "SELECT * FROM $ref_field WHERE joinkey = '$pmid';" );
      while (@row = $result->fetchrow) {
        if ($row[1]) { 
          my $field = $ref_field; $field =~ s/^ref_//; $field = ucfirst($field);
          $row[1] =~ s/\n/ /gs;
          $row[1] =~ s/"/\\"/g;
          $row[1] =~ s/Genes & Development/Genes and Development/g;
          if ($field eq 'Title') { $title = $row[1]; }
          if ($field eq 'Year') { $year = $row[1]; }
          print ACE "$field\t\"$row[1]\"\n";
        } else { 
          # don't print blank fields
#           print ACE "$pmid : $ref_field : NONE\n";
        } 
      } # while (@row = $result->fetchrow)
    } # foreach my $ref_field (@ref)
    $result = $conn->exec( "SELECT * FROM ref_pages WHERE joinkey = '$pmid';" );
    while (@row = $result->fetchrow) {
      if ($row[1]) { 
        $row[1] =~ s/\-/\"\t\"/g;
        print ACE "Page\t\"$row[1]\"\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
    $result = $conn->exec( "SELECT * FROM ref_author WHERE joinkey = '$pmid';" );
    while (@row = $result->fetchrow) {
      if ($row[1]) { 
        $row[1] =~ s/,//g;
        my @authors = split/\/\//, $row[1];
        foreach my $author (@authors) {
          print ACE "Author\t\"$author\"\n";
        } # foreach my $author (@authors)
        my $author = $authors[0];
        my ($init, $last) = $author =~ m/^(\w).* (\w+)/;
        $brief_citation .= $last . " " . $init;
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
    my @chars = split //, $title;
    my $brief_title = '';                 # brief title (70 chars or less)
  
    if ( scalar(@chars) < 70 ) { $brief_title = $title;
    } else {
      my $i = 0;                          # letter counter (want less than 70)
      my $word = '';                      # word to tack on (start empty, add characters)
      while ( (scalar(@chars) > 0) && ($i < 70) ) {
                                          # while there's characters, and less than 70 been read
        $brief_title .= $word;            # add the word, because still good (first time empty)
        $word = '';                       # clear word for next time new word is used
        my $char = shift @chars;          # read a character to start / restart check
        while ( (scalar(@chars) > 0) && ($char ne ' ') ) {	# while not a space and still chars
          $word .= $char; $i++;           # build word, add to counter (less than 70)
          $char = shift @chars;           # read a character to check if space
        } # while ($_ ne '')              # if it's a space, exit loop
        $word .= ' ';                     # add a space at the end of the word
      } # while ( (scalar(@chars) > 0) && ($i < 70) )
      $brief_title = $brief_title . "....";
    } # else # if ( scalar(@chars) < 70 ) 
    $brief_citation .= " ($year) WBG. \\\"$brief_title\\\"\"\n";
    print ACE "$brief_citation";
    $result = $conn->exec( "SELECT * FROM ref_abstract WHERE joinkey = '$pmid';" );
    while (@row = $result->fetchrow) {
      if ($row[1]) { 
        print ACE "Abstract\t\"\[$pmid\]\"\n\n"; 
        print ACE "LongText\t:\t\"\[$pmid\]\"\n";
        print ACE $row[1] . "\n";        # output the value
        print ACE "***LongTextEnd***\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
    print ACE "\n";
#     if ($row[0]) { print "R : $pmid : $row[0] : $row[1]\n"; delete $pmids{$pmid}; }
#     else { print "R : $pmid\n"; }		# this is pointless, only here if SELECT worked
# 						# so will always have a $row[0]
  } # while (@row = $result->fetchrow)
  if ($pmids{$pmid}) { print "NOPE : $pmid\n"; }
} # foreach my $pmid (sort keys %pmids)

foreach $_ (sort keys %pmids) {
#   print "UNMATCHED : $_\n"; 
} # foreach $_ (sort keys %pmids)



# ref_abstract
# ref_author
# ref_cgc
# ref_checked_out
# ref_hardcopy
# ref_html
# ref_journal
# ref_lib
# ref_med
# ref_pages
# ref_pdf
# ref_pmid
# ref_reference_by
# ref_tif
# ref_title
# ref_volume
# ref_year

close (ACE) or die "Cannot close $acefile : $!";
close (ERR) or die "Cannot close $errorfile : $!";
