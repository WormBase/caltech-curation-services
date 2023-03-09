#!/usr/bin/perl
#
# modified code (seqpaperparser.pl) to first-pass take author_timestamp_WS60.ace, and create
# author_timestamp_clean.ace, with only the useful tags, data, and timestamps in tab-delimited
# format.  that which does not match, goes to the errorfile.seqpaperparsertimestamped.
# then does as seqpaperparser.pl and creates the author_timestamp_junk.ace, and
# author_timestamp_not_junk.ace, which separates the entries that only have useless info.
# then creates author_timestamp_contact.ace, which filters down to solely the useful contact info
# from the author_timestamp_not_junk.ace.
#
# Note : does not account for comments (-C) manually fixed them form the source
# author_timestamp_WS60.ace for the few mentions in the errorfile.seqpaperparsertimestamped.

use strict;
use diagnostics;

my $authorfile = "/home/azurebrd/work/parsings/authorperson/filesources/author_timestamp_WS60.ace";
my $authorclean = "/home/azurebrd/work/parsings/authorperson/filesources/author_timestamp_clean.ace";
my $author_contact = "/home/azurebrd/work/parsings/authorperson/filesources/author_timestamp_contact.ace";
my $author_not_junk = "/home/azurebrd/work/parsings/authorperson/filesources/author_timestamp_not_junk.ace";
my $author_junk = "/home/azurebrd/work/parsings/authorperson/filesources/author_timestamp_junk.ace";
my $errorfile = "/home/azurebrd/work/parsings/authorperson/errors/errorfile.seqpaperparsertimestamped";

open (IN, "<$authorfile") or die "Cannot open $authorfile : $!";
open (OUT, ">$authorclean") or die "Cannot open $authorclean : $!";
open (ERR, ">$errorfile") or die "Cannot open $errorfile : $!";

while (<IN>) {
  chomp;
  if ($_ =~ m/^\s*$/) { print OUT "$_\n"; }
  elsif ($_ =~ m/^(Author) : "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Also_known_as)\s+-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Full_name)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Laboratory)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Old_lab)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Paper)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Sequence)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^(Keyword)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^Address\s+\-O "[^"]+" (Mail)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^Address\s+\-O "[^"]+" (Phone)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^Address\s+\-O "[^"]+" (Fax)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  elsif ($_ =~ m/^Address\s+\-O "[^"]+" (E_mail)\s+\-O "[^"]+" "([^"]+)" -O "([^"]+)"$/) { print OUT "$1\t$2\t"; if ($3 eq 'original') { print OUT "1970-01-01_0:0:0\n" } else { print OUT "$3\n"; } }
  else { print ERR "can't parse : $_\n" };
} # while (<IN>)

close (IN) or die "Cannot close $authorfile : $!";
close (OUT) or die "Cannot close $authorclean : $!";

open (IN, "<$authorclean") or die "Cannot open $authorclean : $!";
open (OUT, ">$author_contact") or die "Cannot create $author_contact : $!";
open (NOT, ">$author_not_junk") or die "Cannot create $author_not_junk : $!";
open (JUN, ">$author_junk") or die "Cannot create $author_junk : $!";

{
  local $/ = "";
  my $entry;
  $entry = <IN>; $entry = <IN>;
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
close (ERR) or die "Cannot close $errorfile : $!";
