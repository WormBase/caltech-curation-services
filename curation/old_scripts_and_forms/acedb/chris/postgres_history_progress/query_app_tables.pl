#!/usr/bin/perl -w

# query app_curator to track pgid history

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %done;
$result = $dbh->prepare( "SELECT * FROM app_curator_hst WHERE joinkey IN (SELECT joinkey FROM app_curator WHERE app_curator ~ 'WBPerson') AND joinkey NOT IN (SELECT joinkey FROM app_nodump WHERE app_nodump = 'NO DUMP') ORDER BY app_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  unless ($done{$row[0]}) {
    print qq($row[0]\t$row[2]\n); 
  }
  $done{$row[0]}++;
} # while (@row = $result->fetchrow)

