#!/usr/bin/perl -w

# get the journal list from pubmed, and the journal list from .ace from wen.
# compare and generate a .ace file with full_name and other_name from pubmed
# with ace heading.  generate bad.txt for non-matches.  2002 08 26

use strict;
use diagnostics;
use LWP::Simple;

my @list = qw(2 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
# my @list = qw(J); 

my %pubmedJournal; 
my %pubmedAbbrev;

my %ace;

sub getPubMed {
  foreach my $list (@list) {
    my $page = get "http://www.ncbi.nlm.nih.gov/entrez/journals/noprov/loftext_noprov_$list.html";
    my @journals = $page =~ m/<LI>\n(.*?)\n<UL>/gm;
    foreach my $journal (@journals) { 
  #     print "J : $journal : J\n"; 
      my ($pm, $abbrev) = $journal =~ m/^(.*?) \((.*?)\)$/;
      if ($abbrev =~ m/\(/) { $abbrev =~ s/^.*\(//g; }
  #     print "PM : $pm : AB : $abbrev\n";
      my $key = lc($pm);
      $key =~ s/\&/and/g;
      $key =~ s/the //g;
      $key =~ s/\.//g;
      my $key2 = lc($abbrev);
      $key2 =~ s/\&/and/g;
      $key2 =~ s/the //g;
      $key2 =~ s/\.//g;
      print "KEY : $key : PM : $pm : AB : $abbrev\n";
      $pubmedJournal{$key} = $pm;
      $pubmedAbbrev{$key} = $abbrev;
      $pubmedJournal{$key2} = $pm;
      $pubmedAbbrev{$key2} = $abbrev;
    } # foreach my $journal (@journals) 
  } # foreach my $list (@list)
} # sub getPubMed

sub getAce {
# my %count;
  my $infile = 'l_journal.ace';
  undef $/;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $ace = <IN>;
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";
  my @journals = $ace =~ m/"(.*)"/gm;
# print "COUNT @{ [ scalar(@journals) ] } COUNT\n";
  foreach my $journal (@journals) {
    my $key = lc($journal);
    $key =~ s/\&/and/g;
    $key =~ s/the //g;
    $key =~ s/\.//g;
    $ace{$key} = $journal;
#     $count{$key}++;
#     print "KEY2 : $key : ACE : $journal\n";
  } # foreach my $jounal (@journals)
#   print "ACE @{ [ scalar(keys %ace) ] } ACE\n";
#   foreach (sort keys %count) { if ($count{$_} > 1) { print "C $_ : $count{$_} C\n"; } }
} # sub getAce

&getAce();
&getPubMed();

my $good = 'good.ace';
my $bad = 'bad.txt';

open (GOO, ">$good") or die "Cannot open $good : $!";
open (BAD, ">$bad") or die "Cannot open $bad : $!";

foreach my $ace (sort keys %ace) {
  if ($pubmedJournal{$ace}) {
#     print GOO "ACE $ace{$ace} PM $pubmedJournal{$ace} AB $pubmedAbbrev{$ace}\n";
    print GOO "Journal : \"$ace{$ace}\"\n";
    print GOO "Full_name\t\"$pubmedJournal{$ace}\"\n";
    print GOO "Other_name\t\"$pubmedAbbrev{$ace}\"\n\n";
  } else {
    print BAD "\"$ace{$ace}\" has no match\n";
  }
} # foreach my $ace (sort keys %ace)

close (GOO) or die "Cannot close $good : $!";
close (BAD) or die "Cannot close $bad : $!";
