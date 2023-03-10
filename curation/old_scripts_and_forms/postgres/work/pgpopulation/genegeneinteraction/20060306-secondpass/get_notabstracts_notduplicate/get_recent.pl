#!/usr/bin/perl -w

# filter out invalid papers and filter out abstracts and the like from a list of
# WBPapers already looked at for gene-gene interaction   2007 01 08

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %wpa;		# valid papers
my $result = $conn->exec( "SELECT * FROM wpa;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{$row[0]}++; }
    else { delete $wpa{$row[0]}; } }

my %bad; 		# not actual papers
$result = $conn->exec( "SELECT * FROM wpa_type WHERE wpa_type = '3' OR wpa_type = '4' OR wpa_type = '7'; ");
while (my @row = $result->fetchrow) { $bad{$row[0]}++; }    # put meeting abstracts in bad hash to exclude

my $infile = '../full_20060307.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/^FILE.*?WBPaper(\d+)/) { 
    my $id = $1; 
    if ($wpa{$id}) { unless ($bad{$id}) { print "WBPaper$id\n"; } 
