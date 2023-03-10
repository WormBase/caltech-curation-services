#!/usr/bin/perl -w

# get pictures that have expr pattern with northern | western | rtpcr  2018 06 14

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %exprs;
$result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE joinkey IN (SELECT joinkey FROM exp_northern) OR joinkey IN (SELECT joinkey FROM exp_western) OR joinkey IN (SELECT joinkey FROM exp_rtpcr)" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $exprs{$row[0]}++; } }

foreach my $expr (sort keys %exprs) {
  $result = $dbh->prepare( "SELECT pic_name FROM pic_name WHERE joinkey IN (SELECT joinkey FROM pic_exprpattern WHERE pic_exprpattern ~ '\"$expr\"')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      print qq($row[0]\t$expr\n); 
} } }
