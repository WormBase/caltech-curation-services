#!/usr/bin/perl -w

# read data from postgresql, store already in into a hash.  read new data from asn1 
# file; parse and print to errorfile if errors or already in pg database.  2002 05 22
#
# added ref_comment for endnoter.cgi 2002 06 25
#
# added system("/home/postgres/work/pgpopulation/cgc_pmid_automatic/wrapper.pl");
# to run the xref crosslinker wrapper at the end of the new population
#
# updated all the pg tables to grant all permissions to acedb for andrei 2003 03 30
#
# added line :
#      if ($title{$key} =~ m/\" ,.*\n\s*trans/) { $title{$key} =~ s/\" ,.*$//g; }
# to get rid of ``trans'' tag in title data from translated titles.  2003 10 02
#
# added lines :
#      if ($author !~ m/[a-z]/) { &mailDaniel($author, $key); }
#      elsif ($author =~ m/[^\w\-\']/) { &mailDaniel($author, $key); }
#      else { 1; }
# to check that author has non-capitals and doesn't have odd charcters, else
# email daniel the author and the pmid number.  2003 10 02
#
# added \ before ' and " for title and for ' for authors so that postgres
# can add them.  2003 10 02
#
# &mailDaniel was emailing him for each bad entry, changed to add to variable
# and send him once for all bad entries.  2003 11 12
#
# created ref_origtime for Eimear.  2004 01 15
#
# changed the way it parses the file because pubmed has a slightly different format.
# 2004 10 06

use strict;
use diagnostics;
use Fcntl;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

use Jex; 	# mailer

  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pgPmid;			# hash of pmids already in pg

my (%pmid, %title, %authors, %abstract, %journal, %pages, %year, %volume);
				# hashes for data by pmid
my ($pmid, $title, $authors, $abstract, $journal, $pages, $year, $volume);
				# counters
my $errorfile = "errorfile_asn1";
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";


&populatePgPmid();

my $daniel_body = '';		# what to email to daniel;

my $infile = "/home/postgres/work/pgpopulation/andreipubmedrecords/medline_2003feb05_asn1.fcgi";
				# initialize file name
my $file = $ARGV[0];		# get from command line
# my $infile = "/home/postgres/work/pgpopulation/andreipubmedrecords/medline_may22_asn1.fcgi";
$infile = $file;
# if ($file) { $infile = "/home/postgres/work/pgpopulation/andreipubmedrecords/$file"; }

open (IN, "<$infile") or die "Cannot open $infile : $!";
$/ = "";			# read paragraphs
while (<IN>) { 
  chomp;
  my $key;
#   unless ($_ =~ m/pmid (\d+) /) 
  unless ($_ =~ m/pmid (\d+)/) { 
    print ERR "No pmid : $_\n";
  } else {
    $key = $1; $pmid++; 
    $pmid{$key} = $key;

#     unless ($_ =~ m/title {[\s\n]*name "(.*?)"[ \n]}/s) 
    unless ($_ =~ m/title {[\s\n]*name "(.*?)"/s) { 
      print ERR "No title pmid : $key\n";
      $title{$key} = 'NULL';
    } else {
      $title++;
#     print "$key : $1\n"; 
      if ($1) { $title{$key} = $1; } else { $title{$key} = 'NULL'; }
      if ($title{$key} =~ m/\" ,.*\n\s*trans/) { $title{$key} =~ s/\" ,.*$//g; }
      $title{$key} =~ s/\'/\\'/g;
      $title{$key} =~ s/\"/\\"/g;
    } # unless ($_ =~ m/title {[\s\n]* name "(.*?)"[ \n]}/s) 
  
#     unless ($_ =~ m/authors {[\s\n]*names[\s\n]*ml {[\s\n]*(".*?") }/s) { # }
    unless ($_ =~ m/authors {[\s\n]*names[\s\n]*ml {(.*?)}/s) { # }
      print ERR "No author pmid : $key\n";
      $authors{$key} = 'NULL';
    } else {
      $authors++;
      my @authors = $1 =~ m/"(.*?)"/gs;
      foreach (@authors) { $_ =~ s/ /, /g; }
      my $author = join "\/\/", @authors;
#       print "$key : $author\n";
      $authors{$key} = $author;
      if ($author !~ m/[a-z]/) { $daniel_body .= "$author\t$key\n"; }
      elsif ($author =~ m/[^\w\-\']/) { $daniel_body .= "$author\t$key\n"; }
      else { 1; }
      $authors{$key} =~ s/\'/\\'/g;
    } # if ($_ =~ m/authors {[\s\n]*names[\s\n]*ml {[\s\n]*"(.*?)" }/s) # }

#     unless ($_ =~ m/ {4}abstract "(.*?)" ,/s) 
    unless ($_ =~ m/ {4}abstract "(.*?)",/s) {
      print ERR "No abstract pmid : $key\n";
      $abstract{$key} = 'NULL';
    } else {
      $abstract++;
      $abstract{$key} = $1;
    } # unless ($_ =~ m/ {4}abstract "(.*?)" ,/s)

#     unless ($_ =~ m/ml-jta "(.*?)" ,/s)
    unless ($_ =~ m/ml-jta "(.*?)",/s) {
      print ERR "No journal pmid : $key\n";
      $journal{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $journal++;
      $journal{$key} = $jour;
    } # unless ($_ =~ m/ml-jta "(.*?)" ,/s)
  
#     unless ($_ =~ m/volume "(.*?)" ,/s)
    unless ($_ =~ m/volume "(.*?)",/s) {
      print ERR "No volume pmid : $key\n";
      $volume{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $volume++;
      $volume{$key} = $jour;
    } # unless ($_ =~ m/volume "(.*?)" ,/s)
  
#     unless ($_ =~ m/pages "(.*?)" ,/s)
    unless ($_ =~ m/pages "(.*?)",/s) {
      print ERR "No pages pmid : $key\n";
      $pages{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $pages++;
      $pages{$key} = $jour;
    } # unless ($_ =~ m/pages "(.*?)" ,/s)
  
#     unless ($_ =~ m/year (\d+) ,/s)
    unless ($_ =~ m/year (\d+),/s) {
      print ERR "No year pmid : $key\n";
      $year{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $year++;
      $year{$key} = $jour;
    } # unless ($_ =~ m/year "(.*?)" ,/s)
  
  } # unless ($_ =~ m/pmid (\d+) /) 
} # while (<IN>)
print "pmid : $pmid\n";
print "title : $title\n";
print "authors : $authors\n";
print "abstract : $abstract\n";
print "journal : $journal\n";
print "pages : $pages\n";
print "year : $year\n";
print "volume : $volume\n\n";

foreach $_ (sort {$a <=> $b} keys %pmid) {
  unless ($pmid{$_}) { 
    print "pmid error : $_\n"; 
  } else { 
    if ($pgPmid{$pmid{$_}}) { 		# if already in, print ERROR, don't insert to pg
      print "ERROR : Double : $pmid{$_} ignored\n"; 
      print ERR "ERROR : Double : $pmid{$_} ignored\n"; 
    } else { 				# if new, insert
      print "pmid : $pmid{$_}\n"; 
      my $result = $conn->exec( "INSERT INTO ref_pmid VALUES ('pmid$_', '$pmid{$_}')");
      $result = $conn->exec( "INSERT INTO ref_origtime VALUES ('pmid$_')");
		# original timestamp for Eimear  2004 01 15

      if ($title{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_title VALUES ('pmid$_', '$title{$_}')");
        $result = $conn->exec( "INSERT INTO ref_checked_out VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_reference_by VALUES ('pmid$_', 'Andrei Petcherski')");
        $result = $conn->exec( "INSERT INTO ref_comment VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_hardcopy VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_tif VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_tif_pdf VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_pdf VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_lib_pdf VALUES ('pmid$_', NULL)");
        $result = $conn->exec( "INSERT INTO ref_html VALUES ('pmid$_', NULL)");
        print "title : $title{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_title VALUES ('pmid$_', NULL)");
        print "title : missing\n"; 
      }
  
      if ($authors{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_author VALUES ('pmid$_', '$authors{$_}')");
        print "authors : $authors{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_author VALUES ('pmid$_', NULL)");
        print "authors : missing\n"; 
      }
  
      if ($abstract{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_abstract VALUES ('pmid$_', '$abstract{$_}')");
        print "abstract : $abstract{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_abstract VALUES ('pmid$_', NULL)");
        print "abstract : missing\n"; 
      }
  
      if ($journal{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_journal VALUES ('pmid$_', '$journal{$_}')");
        print "journal : $journal{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_journal VALUES ('pmid$_', NULL)");
        print "journal : missing\n"; 
      }
  
      if ($pages{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_pages VALUES ('pmid$_', '$pages{$_}')");
        print "pages : $pages{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_pages VALUES ('pmid$_', NULL)");
        print "pages : missing\n"; 
      }
  
      if ($year{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_year VALUES ('pmid$_', '$year{$_}')");
        print "year : $year{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_year VALUES ('pmid$_', NULL)");
        print "year : missing\n"; 
      }
  
      if ($volume{$_}) { 
        my $result = $conn->exec( "INSERT INTO ref_volume VALUES ('pmid$_', '$volume{$_}')");
        print "volume : $volume{$_}\n"; 
      } else { 
        my $result = $conn->exec( "INSERT INTO ref_volume VALUES ('pmid$_', NULL)");
        print "volume : missing\n"; 
      }
      print "\n";
    } # else # if ($pgPmid{$pmid{$_}})
  } # else # unless ($pmid{$_})
} # foreach $_ (sort {$a <=> $b} keys %pmid)

close (IN) or die "Cannot close $infile : $!";
close (ERR) or die "Cannot close $errorfile : $!";

system("/home/acedb/andrei/wrapper.pl");


sub populatePgPmid {
  my $result = $conn->exec( "SELECT ref_pmid FROM ref_pmid");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pgPmid{$row[0]}++; }
  } # while (my @row = $result->fetchrow)
} # sub populatePgPmid

if ($daniel_body) {
  my $body = '';
  my @lines = split/\n/, $daniel_body;
  foreach my $line (@lines) { 
    my ($author, $key) = split/\t/, $line;
    $body .= "Possible bad Author in PMID $key, Author $author\n";
  }
  my $user = 'andrei_pmids_automatic';
  my $email = 'qwang@its.caltech.edu';
  my $subject = 'Possibly bad Authors';
  &mailer($user, $email, $subject, $body);
}

