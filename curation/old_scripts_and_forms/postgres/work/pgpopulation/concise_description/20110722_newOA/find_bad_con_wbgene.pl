#!/usr/bin/perl -w

# find wbgenes in con_wbgene that are not in gin_wbgene and are not in con_nodump.  These don't show in the OA, but are there and get dumped to .ace
# 2011 07 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %gin;
my %nodump;
my %con;

my $result = $dbh->prepare( "SELECT gin_wbgene FROM gin_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $gin{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM con_wbgene WHERE joinkey NOT IN (SELECT joinkey FROM con_nodump) ORDER BY con_wbgene;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  unless ($gin{$row[1]}) { print "$row[0]\t$row[1]\n"; }
}
