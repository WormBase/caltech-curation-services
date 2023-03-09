#!/usr/bin/perl

# append cgc data before pmid to pmid's with corresponding cgcs.
# usage ./fix_cgc_in_go.pl bad_file > new_file    2003 11 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pmHash;		# hash of pmids, values cgcs

&populateXref();

my $infile = $ARGV[0];

open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { 
  my ($paper) = $line =~ m/^.*?\t.*?\t.*?\t.*?\t.*?\t(.*?)\t/;	# get the 6th column which has reference info
  if ($paper =~ m/PMID:(\d+)/) { 				# if it has a PMID
    my $num = 'pmid' . $1;					# get the number in pmHash key form
    my $newpaper = $paper;					# intialize new entry
    if ($pmHash{$num}) { $newpaper = "WB:[$pmHash{$num}]|$paper"; }	# append cgc and create new entry
    $line =~ s/$paper/$newpaper/g;				# sub old entry for new one
  }
  print $line; 							# output the (new or old) line
}
close (IN) or die "Cannot close $infile : $!";



sub populateXref {              # if not found, get ref_xref data to try to find alternate
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $pmHash{$row[1]} = $row[0];         # hash of pmids, values cgcs
  } # while (my @row = $result->fetchrow)
} # sub populateXref
