#!/usr/bin/perl -w

# query pap_journal and pap_year, output by journal->year->count

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %journalCount;
my %journal;
my %year;

$result = $dbh->prepare( "SELECT * FROM pap_year" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
#     $year{papToYear}{$row[0]} = $row[1];
#     $year{yearToPap}{$row[1]} = $row[0];
    $year{$row[0]} = $row[1];
  }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM pap_journal" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
#     $journal{papToJournal}{$row[0]} = $row[1];
#     $journal{journalToPap}{$row[1]} = $row[0];
    $journalCount{$row[1]}++;
    my $year = '0';
    if ($year{$row[0]}) { $year = $year{$row[0]}; }
    $journal{$row[1]}{$year}++;
  }
} # while (@row = $result->fetchrow)

foreach my $journal (sort { $journalCount{$b} <=> $journalCount{$a} } keys %journalCount) {
  print qq($journal\ttotal\t$journalCount{$journal}\n);
  foreach my $year (reverse sort keys %{ $journal{$journal} }) {
    print qq($journal\t$year\t$journal{$journal}{$year}\n);
  }
#   my %thisYear;
#   foreach my $paper (sort keys %{ $journal{journalToPap} }) {
#     my $year = $year{papToYear}{$paper};
#     $thisYear{$year}++;
#   } # foreach my $paper (sort keys %{ $journal{journalToPap} })
#   foreach my $year (reverse sort keys %thisYear) {
#     print qq($journal\t$year\t$thisYear{$year}\n);
#   }
} # foreach my $journal (sort { $journalCount{$b} <=> $journalCount{$a} } keys %journalCount)

