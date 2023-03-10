#!/usr/bin/perl -w

# find PG tables that aren't 3-letter  2014 06 05

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_schema,table_name;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ( ($row[1] !~ m/^[a-z]{3}_/) ) { print "@row\n"; }
#     if ( ($row[1] !~ m/^h_/) && ($row[1] !~ m/_hst$/) && ($row[1] !~ m/^[a-z]{3}_/) ) { print "@row\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

