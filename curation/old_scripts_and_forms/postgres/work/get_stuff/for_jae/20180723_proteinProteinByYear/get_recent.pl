#!/usr/bin/perl -w

# for protein-protein interactions in int_type, count interactions by year.  2018 07 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %papYear;
$result = $dbh->prepare( "SELECT * FROM pap_year" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $papYear{"WBPaper$row[0]"} = $row[1]; }

my %data;
$result = $dbh->prepare( "SELECT int_name.int_name, int_paper.int_paper FROM int_name, int_paper WHERE int_name.joinkey = int_paper.joinkey AND int_name.joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'ProteinProtein');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $year = 'unknown';
    if ($papYear{$row[1]}) { $year = $papYear{$row[1]}; } else { $year = $row[1]; }
    $data{$year}{interactions}{$row[0]}++;
    $data{$year}{papers}{$row[1]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $year (sort keys %data) {
  my $countInteractions = scalar keys %{ $data{$year}{interactions} };
  my $countPapers       = scalar keys %{ $data{$year}{papers} };
  print qq($year\t$countInteractions\t$countPapers\n);
} # foreach my year (sort keys %year)
