#!/usr/bin/perl

# Look at flatfile and see if there are any invalid papers.  2005 11 10



use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


undef $/;
my $infile = 'concise_dump_new.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $wholefile = <IN>;
close (IN) or die "Cannot close $infile : $!";

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %valid_hash;
my $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp; ");
while (my @row = $result->fetchrow) {
  if ($row[0]) { $valid_hash{$row[0]} = $row[3]; } }

foreach my $valid (sort keys %valid_hash) {
  if ($valid_hash{$valid} eq 'valid') { 
    my $paper = 'WBPaper' . $valid;
    if ($infile =~ m/$paper/) { print OUT "PAPER $paper IN FLATFILE\n"; } }
} # foreach my $valid_hash (sort keys %valid_hash)


close (OUT) or die "Cannot close $outfile : $!";
