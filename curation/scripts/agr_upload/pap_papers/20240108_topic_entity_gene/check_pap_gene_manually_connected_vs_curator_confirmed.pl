#!/usr/bin/env perl

# compared pap_gene -> pap_evidence   Curator_confirmed vs Manually_connected based on pairs of paperID + wbgeneID  2024 01 08


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %mc;
my %cc;
my %ccni;

  $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Curator_confirmed'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $cc{$row[0]}{$row[1]} += 1; }

  $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Curator_confirmed' AND pap_curator != 'two22'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $ccni{$row[0]}{$row[1]} += 1; }

  $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Manually_connected'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $mc{$row[0]}{$row[1]} += 1; }

foreach my $pap (sort keys %ccni) {
  foreach my $gene (sort keys %{ $ccni{$pap} }) {
    next unless ($gene);
    unless ($mc{$pap}{$gene}) { print qq($pap\t$gene\tCurator_confirmed not Igor, not Manually_connected\n); }
  } # foreach my $gene (sort keys %{ $mc{$pap} })
} # foreach my $pap (sort keys %mc)

foreach my $pap (sort keys %mc) {
  foreach my $gene (sort keys %{ $mc{$pap} }) {
    next unless ($gene);
    unless ($cc{$pap}{$gene}) { print qq($pap\t$gene\tManually_connected, not Curator_confirmed\n); }
  } # foreach my $gene (sort keys %{ $mc{$pap} })
} # foreach my $pap (sort keys %mc)
