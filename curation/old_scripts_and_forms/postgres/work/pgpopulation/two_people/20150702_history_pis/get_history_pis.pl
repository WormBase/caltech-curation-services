#!/usr/bin/perl -w

# query for two_pis and h_two_pis to see who is no longer a pi that used to be.  For Cecilia + Mary Ann  2015 07 02

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %cur; my %hist;
$result = $dbh->prepare( "SELECT * FROM two_pis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cur{$row[0]}{$row[1]} = $row[2]; } }

$result = $dbh->prepare( "SELECT * FROM h_two_pis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    unless ($cur{$row[0]}{$row[1]}) {
      unless ($cur{$row[0]}{$row[1]} eq $row[2]) {
        my $row = join"\t", @row;
        print qq($row\n); } } } }

