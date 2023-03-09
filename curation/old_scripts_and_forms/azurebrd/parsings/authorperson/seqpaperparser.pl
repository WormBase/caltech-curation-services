#!/usr/bin/perl
#
# parse the full authors file out of Paper and Sequence
# create author_junk, which are the authors with only paper and/or sequence and/or keyword information
# create author_non_junk, which are the remainder (authors with more than just paper or sequence or
# keyword info)
# open author_non_junk, and create author_contact.ace, which has just the contact info of those
# authors.

use strict;
use diagnostics;

my $authorfile = "/home/azurebrd/work/parsings/authorperson/filesources/authors_WS60.ace";
my $author_contact = "/home/azurebrd/work/parsings/authorperson/filesources/author_contact.ace";
my $author_not_junk = "/home/azurebrd/work/parsings/authorperson/filesources/author_not_junk.ace";
my $author_junk = "/home/azurebrd/work/parsings/authorperson/filesources/author_junk.ace";

open (IN, "<$authorfile") or die "Cannot open $authorfile : $!";
open (OUT, ">$author_contact") or die "Cannot create $author_contact : $!";
open (NOT, ">$author_not_junk") or die "Cannot create $author_not_junk : $!";
open (JUN, ">$author_junk") or die "Cannot create $author_junk : $!";

{
  local $/ = "";
  my $entry;
  while ($entry = <IN>) { 
    my %tags;
    my @line = split/\n/, $entry;
    foreach (@line) { 
      my @words = split/\s+/, $_;
      $tags{$words[0]}++;
    } # foreach (@line) 
    if ( ($tags{Mail}) || ($tags{Also_known_as}) || ($tags{Full_name}) || ($tags{Phone}) || ($tags{Fax}) 
	|| ($tags{E_mail}) || ($tags{Mail}) || ($tags{Laboratory}) ) { 	# good entry
      print NOT $entry;
    } else {
      print JUN $entry;
    }
  } # while (<IN>) 
} # naked block for local $/ = "";

close (NOT) or die "Cannot close $author_not_junk : $!";
open (NOT, "<$author_not_junk") or die "Cannot open $author_not_junk : $!";

while (<NOT>) {
  print OUT unless ($_ =~ m/^(Seq|Pap|Key)/);
} # while (<NOT>)

close (IN) or die "Cannot close $authorfile : $!";
close (OUT) or die "Cannot close $author_contact : $!";
close (JUN) or die "Cannot close $author_junk : $!";
close (NOT) or die "Cannot close $author_not_junk : $!";
