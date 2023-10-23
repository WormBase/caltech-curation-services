#!/usr/bin/env perl

# get unique phenotypes for tim schedl and karen.  2023 10 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my %hash;

$result = $dbh->prepare( "SELECT * FROM rna_phenotype;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@phens) = $row[1] =~ m/(WBPhenotype:\d+)/;
    foreach my $phen (@phens) { $hash{rnai}{$phen}++; $hash{any}{$phen}++; } } }

$result = $dbh->prepare( "SELECT * FROM app_term;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@phens) = $row[1] =~ m/(WBPhenotype:\d+)/;
    foreach my $phen (@phens) { $hash{phenotype}{$phen}++; $hash{any}{$phen}++; } } }

foreach my $type (sort keys %hash) {
  my $count = scalar keys %{ $hash{$type} };
  print qq($type\t$count\n);
}
