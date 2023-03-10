#!/usr/bin/perl -w

# query grg_summary for special characters

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %badChar;
my %badSummary;
$result = $dbh->prepare( "SELECT * FROM grg_summary" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    if ($row[1] =~ m/([^\x00-\x7F])/g) { 
      $badSummary{$row[1]}{$row[0]}++;
      my (@nonascii) = $row[1] =~ m/([^\x00-\x7F])/g;
      foreach my $nonascii (@nonascii) {
        $badChar{$nonascii}{$row[0]}++;
      }
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $badChar (sort keys %badChar) {
  my $pgids = join",", sort keys %{ $badChar{$badChar} };
  print qq($badChar\t$pgids\n);
} # foreach my $badChar (sort keys %badChar)

foreach my $badSummary (sort keys %badSummary) {
  my $pgids = join",", sort keys %{ $badSummary{$badSummary} };
  print qq($badSummary\t$pgids\n);
} # foreach my $badSummary (sort keys %badSummary)

