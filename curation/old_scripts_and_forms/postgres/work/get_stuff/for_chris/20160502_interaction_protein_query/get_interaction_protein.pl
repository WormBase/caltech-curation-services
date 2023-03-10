#!/usr/bin/perl -w

# get interactions where interaction type is physical and detection method does not have a value from a list.  2016 05 02

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %joinkeys;
$result = $dbh->prepare( "SELECT * FROM int_type WHERE int_type = 'Physical' AND joinkey NOT IN (SELECT joinkey FROM int_nodump)" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $joinkeys{$row[0]}++; } }

my %badDetection;
$result = $dbh->prepare( "SELECT * FROM int_detectionmethod WHERE int_detectionmethod ~ 'Electrophoretic_mobility_shift_assay' OR int_detectionmethod ~ 'Yeast_one_hybrid' OR int_detectionmethod ~ 'Chromatin_immunoprecipitation' OR int_detectionmethod ~ 'DNase_I_footprinting' OR int_detectionmethod ~ 'Directed_yeast_one_hybrid'");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $badDetection{$row[0]}++; delete $joinkeys{$row[0]}; } }

my @tables = qw( int_name int_paper int_type int_summary int_remark int_detectionmethod int_genebait int_genetarget int_genenondir );
my %data;

my $joinkeys = join"','", sort keys %joinkeys;
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey IN ('$joinkeys');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $data{$table}{$row[0]} = $row[1]; } }

foreach my $joinkey (sort {$a<=>$b} keys %joinkeys) {
  my $intid      = $data{int_name}{$joinkey}            || '';
  my $paper      = $data{int_paper}{$joinkey}           || '';
  my $type       = $data{int_type}{$joinkey}            || '';
  my $summary    = $data{int_summary}{$joinkey}         || '';
  my $remark     = $data{int_remark}{$joinkey}          || '';
  my $detection  = $data{int_detectionmethod}{$joinkey} || '';
  my $genebait   = $data{int_genebait}{$joinkey}        || '';
  my $genetarget = $data{int_genetarget}{$joinkey}      || '';
  my $genenondir = $data{int_genenondir}{$joinkey}      || '';
  print qq($intid\t$paper\t$type\t$summary\t$remark\t$detection\t$genebait\t$genetarget\t$genenondir\n);
} # foreach my $joinkey (sort {$a<=>$b} keys %joinkeys)

