#!/usr/bin/perl -w
#
# Find the aces from the two_groups, get their ace_author name, and create lines
# to link Authors to Person (Possible_person)  2002 12 19

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/person_ace/possible_person_for_author/outfile";

open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %aces;		# key two, value array of aces
my %twos;

my $result = $conn->exec( "SELECT * FROM two_groups WHERE two_groups ~ 'ace';");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    push @{ $aces{$row[0]} }, $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $two (sort keys %aces) {
  foreach my $ace (@{ $aces{$two} }) {
    $result = $conn->exec( "SELECT * FROM ace_author WHERE joinkey = '$ace';");
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        $row[1] =~ s///g;
        print OUT "Author : \"$row[1]\"\n";
        $two =~ s/two/WBPerson/g;
        print OUT "Possible_person\t$two\n\n";
      } # if ($row[0])
    } # while (@row = $result->fetchrow)
  } # foreach my $ace (@{ $aces{$two} })
} # foreach my $ace (sort keys %aces)


close (OUT) or die "Cannot close $outfile : $!";
