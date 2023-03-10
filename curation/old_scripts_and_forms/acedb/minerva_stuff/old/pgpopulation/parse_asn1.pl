#!/usr/bin/perl -w

# read data from postgresql, store already in into a hash.  read new data from asn1 
# file; parse and print to errorfile if errors or already in pg database.  2002 05 22
#
# added ref_comment for endnoter.cgi 2002 06 25

use strict;
use diagnostics;
use Fcntl;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pgPmid;			# hash of pmids already in pg

my (%pmid, %title, %authors, %abstract, %journal, %pages, %year, %volume);
				# hashes for data by pmid
my ($pmid, $title, $authors, $abstract, $journal, $pages, $year, $volume);
				# counters
my $errorfile = "/home/acedb/pgpopulation/errorfile_asn1";
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";


&populatePgPmid();

my $infile = "/home/acedb/pgpopulation/pmid12181365.asn1";
				# initialize file name
my $file = $ARGV[0];		# get from command line
if ($file) { $infile = "/home/acedb/pgpopulation/$file"; }

open (IN, "<$infile") or die "Cannot open $infile : $!";
$/ = "";			# read paragraphs
while (<IN>) { 
  chomp;
  my $key;
  unless ($_ =~ m/pmid (\d+) /) { 
    print ERR "No pmid : $_\n";
  } else {
    $key = $1; $pmid++; 
    $pmid{$key} = $key;

    unless ($_ =~ m/title {[\s\n]*name "(.*?)"[ \n]}/s) { 
      print ERR "No title pmid : $key\n";
      $title{$key} = 'NULL';
    } else {
      $title++;
#     print "$key : $1\n"; 
      if ($1) { $title{$key} = $1; } else { $title{$key} = 'NULL'; }
    } # unless ($_ =~ m/title {[\s\n]* name "(.*?)"[ \n]}/s) 
  
    unless ($_ =~ m/authors {[\s\n]*names[\s\n]*ml {[\s\n]*(".*?") }/s) { # }
      print ERR "No author pmid : $key\n";
      $authors{$key} = 'NULL';
    } else {
      $authors++;
      my @authors = $1 =~ m/"(.*?)"/gs;
      foreach (@authors) { $_ =~ s/ /, /g; }
      my $author = join "\/\/", @authors;
#       print "$key : $author\n";
      $authors{$key} = $author;
    } # if ($_ =~ m/authors {[\s\n]*names[\s\n]*ml {[\s\n]*"(.*?)" }/s) # }

    unless ($_ =~ m/ {4}abstract "(.*?)" ,/s) {
      print ERR "No abstract pmid : $key\n";
      $abstract{$key} = 'NULL';
    } else {
      $abstract++;
      $abstract{$key} = $1;
    } # unless ($_ =~ m/ {4}abstract "(.*?)" ,/s)

    unless ($_ =~ m/ml-jta "(.*?)" ,/s) {
      print ERR "No journal pmid : $key\n";
      $journal{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $journal++;
      $journal{$key} = $jour;
    } # unless ($_ =~ m/ml-jta "(.*?)" ,/s)
  
    unless ($_ =~ m/volume "(.*?)" ,/s) {
      print ERR "No volume pmid : $key\n";
      $volume{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $volume++;
      $volume{$key} = $jour;
    } # unless ($_ =~ m/volume "(.*?)" ,/s)
  
    unless ($_ =~ m/pages "(.*?)" ,/s) {
      print ERR "No pages pmid : $key\n";
      $pages{$key} = 'NULL';
    } else {
      my $jour = $1;
      $jour =~ s/\n/ /s;
      $pages++;
      $pages{$key} = $jour;
    } # unless ($_ =~ m/pages "(.*?)" ,/s)
  
    unless ($_ =~ m/year (\d+) ,/s) {
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

sub populatePgPmid {
  my $result = $conn->exec( "SELECT ref_pmid FROM ref_pmid");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pgPmid{$row[0]}++; }
  } # while (my @row = $result->fetchrow)
} # sub populatePgPmid
