#!/usr/bin/perl -w
#

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $infile = "missing_sequences_modified.ace";
$/ = "";

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ($_ =~ m/Sequence : "(.*)"/) {
    my $seq = $1;
    my $result = $conn->exec( "SELECT * FROM got_sequence WHERE got_sequence ~ '$seq';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        $row[0] =~ s///g;
        $row[1] =~ s///g;
        $row[2] =~ s///g;
        print OUT "Sequence : \"$seq\"\t$row[0]\t$row[2]\n";
      } # if ($row[0])
    } # while (@row = $result->fetchrow)
  } # if ($_ =~ m/Sequence : "(.*)"/)
} # while (<IN>)

close (OUT) or die "Cannot close $outfile : $!";
