#!/usr/bin/perl -w
#
# ace file generator for author_to_person connection (under paper)  2002 02 07

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "author_to_person";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %pmid; my %comment;

my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_verified ~ '^YES';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    my $paper = $row[0];
    my $author = $row[1];
    my $person = $row[2];
    $person =~ s/two/WBPerson/g;
    print OUT "Paper\t\"\[$paper\]\"\n";
    print OUT "Author_to_person\t\"$person\" \"$author\"\n\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

close (OUT) or die "Cannot close $outfile : $!";

