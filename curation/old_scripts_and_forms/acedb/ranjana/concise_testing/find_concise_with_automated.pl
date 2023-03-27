#!/usr/bin/perl -w

# find concise OA data with a gene that has concise + automated in different pgids.  2015 01 05
# /home/acedb/ranjana/concise_testing/find_concise_with_automated.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
$result = $dbh->prepare( "SELECT * FROM con_wbgene WHERE joinkey IN (SELECT joinkey FROM con_desctype WHERE con_desctype ~ 'Automated')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{$row[1]}{'automated'}++; } }

$result = $dbh->prepare( "SELECT * FROM con_wbgene WHERE joinkey IN (SELECT joinkey FROM con_desctype WHERE con_desctype ~ 'Concise')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{$row[1]}{'concise'}++; } }

foreach my $gene (sort keys %hash) {
  my $amount = scalar keys %{ $hash{$gene} };
  if ($amount > 1) {
    print qq($gene\t$amount\n); 
  }
} # foreach my $gene (sort keys %hash)

