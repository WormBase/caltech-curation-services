#!/usr/bin/perl

# take xml from lisa, get the chapter, section, and paragraph location (count
# them) add location to index.para file, create file named as id (next highest
# number in index.para) and write that paragraph to it in the paras/ directory.
# when done with all paragraphs in a file, move file to used_xmls/ directory.
# 2004 06 09

use strict;

my $indexfile = 'index.para';

my $para_dir = 'paras';
my $used_dir = 'used_xmls';

my @xmls = </home/azurebrd/work/parsings/eimear/lisa_xml/*.xml>;

my $counter = 0;
open (IND, "<$indexfile") or die "Cannot open $indexfile : $!";
while (<IND>) { 
  ($counter, my @stuff) = split/\t/, $_;
} # while (<IND>)
close (IND) or die "Cannot close $indexfile : $!"; 

open (IND, ">>$indexfile") or die "Cannot open $indexfile : $!";

foreach my $xml (@xmls) {
  print "XML $xml\n";
  $/ = undef;
  open (IN, "<$xml") or die "Cannot open $xml : $!";
  my $xml_file = <IN>;
  close (IN) or die "Cannot close $xml : $!"; 

  my $chapter_count = 0; my $section_count = 0; my $para_count = 0;
  my (@chapters) = $xml_file =~ m/<chapter>(.*?)<\/chapter>/sg;
  foreach my $chapter (@chapters) {
    $chapter_count++;
    my (@sections) = $chapter =~ m/<section>(.*?)<\/section>/sg;
    foreach my $section (@sections) {
      $section_count++;
      my (@paras) = $section =~ m/<para>(.*?)<\/para>/sg;
      foreach my $para (@paras) {
        unless ($para =~ m/\S/) { next; }
        $counter++;
        $para_count++;
        print IND "$counter\t$xml\t$chapter_count\t$section_count\t$para_count\n";
        open (PAR, ">paras/$counter") or die "Cannot create para/$counter : $!";
        $para =~ s/\s+/ /g;
        print PAR "$para\n";
        close (PAR) or die "Cannot close para/$xml : $!";
      } # foreach my $para (@paras)
    } # foreach my $section (@sections)
  } # foreach my $chapter (@chapters)

  `mv $xml used_xmls/`;  
} # foreach my $xml (@xmls)

close (IND) or die "Cannot close $indexfile : $!"; 
