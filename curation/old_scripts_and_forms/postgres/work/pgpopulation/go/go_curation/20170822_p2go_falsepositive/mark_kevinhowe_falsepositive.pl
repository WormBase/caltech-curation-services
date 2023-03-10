#!/usr/bin/perl -w

# set all entries with curator Kevin Howe to false positive.  for Kimberly.  2017 08 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pgids;
$result = $dbh->prepare( "SELECT * FROM gop_curator WHERE gop_curator = 'WBPerson3111' AND joinkey NOT IN (SELECT joinkey FROM gop_falsepositive WHERE gop_falsepositive = 'False Positive')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgids{$row[0]}++; } }

  # check none of them contain other data
my $pgids = join"','", sort keys %pgids;
$result = $dbh->prepare( "SELECT * FROM gop_falsepositive WHERE joinkey IN ('$pgids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { print qq(@row\n); }

my @pgcommands;
foreach my $pgid (sort keys %pgids) {
  push @pgcommands, qq(INSERT INTO gop_falsepositive VALUES ('$pgid', 'False Positive'));
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

