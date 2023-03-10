#!/usr/bin/perl -w

# query for genetic interaction stuff for Chris for David.  2017 03 31

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( name geneone genetwo genenondir gimoduleone gimoduletwo gimodulethree );

my %data;
$result = $dbh->prepare( "SELECT * FROM int_type WHERE int_type = 'Genetic_interaction'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{$row[0]}{pgids}++; } }

my $pgids = join"','", sort {$a<=>$b} keys %data;

foreach my $table (@tables) {
  print qq($table\t);
  $result = $dbh->prepare( "SELECT * FROM int_$table WHERE joinkey IN ('$pgids')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $data{$row[0]}{$table} = $row[1]; } } }
print qq(\n);

foreach my $pgid (sort {$a<=>$b} keys %data) {
  foreach my $table (@tables) {
    my $entry = $data{$pgid}{$table} || '';
    print qq($entry\t);
  }
  print qq(\n);
} # foreach my $pgid (sort {$a<=>$b} keys %data)
