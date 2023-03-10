#!/usr/bin/perl -w

# take a list of papers from daniela and sort by year so she can find the ones from 2001 and before.  2013 01 17

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %year;
my $result = $dbh->prepare( "SELECT * FROM pap_year" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $year{$row[0]} = $row[1]; } }

my %sort;
my $infile = 'pos_not_cur';
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
while (my $line = <IN>) { 
  chomp $line;
  my $year = '999999';
  if ($year{$line}) { $year = $year{$line}; }
  $sort{$year}{$line}++;
}
close (IN) or die "Cannot close $infile : $!"; 

foreach my $year (sort keys %sort) {
  foreach my $paper (sort keys %{ $sort{$year} }) {
    if ($year < 2002) { print "$paper\n"; }
#     print "$year\t$paper\n";
  } # foreach my $paper (sort keys %{ $sort{$year} })
} # foreach my $year (sort keys %sort)

