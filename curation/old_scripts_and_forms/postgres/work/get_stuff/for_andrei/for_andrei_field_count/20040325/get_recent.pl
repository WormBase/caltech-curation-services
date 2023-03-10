#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %pmid;
my %cgc;
my %both;

my $result = $conn->exec( "SELECT joinkey FROM ref_cgc;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $cgc{$row[0]}++;
} }

$result = $conn->exec( "SELECT joinkey FROM ref_pmid;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $pmid{$row[0]}++;
} }

$result = $conn->exec( "SELECT * FROM ref_xref;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $both{$row[0]}++;
    $both{$row[1]}++;
} }

foreach my $both (sort keys %both) {
  if ($cgc{$both}) { delete $cgc{$both}; }
  if ($pmid{$both}) { delete $pmid{$both}; }
} # foreach $_ (sort keys %both)

my @tables = qw( cur_ablationdata cur_antibody cur_associationequiv cur_associationnew cur_cellfunction cur_cellname cur_comment cur_covalent cur_curator cur_expression cur_extractedallelename cur_extractedallelenew cur_fullauthorname cur_genefunction cur_geneproduct cur_genesymbol cur_genesymbols cur_goodphoto cur_mappingdata cur_mosaic cur_newmutant cur_newsnp cur_newsymbol cur_overexpression cur_rnai cur_sequencechange cur_sequencefeatures cur_site cur_stlouissnp cur_structurecorrection cur_structurecorrectionsanger cur_structurecorrectionstlouis cur_synonym cur_transgene cur_microarray cur_structureinformation cur_functionalcomplementation cur_invitro );

foreach my $table (@tables) {
  my $count = 0;
  foreach my $key (sort keys %both) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey = '$key';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $count++; }
  } # foreach my $key (sort keys %both)
  print OUT "There are $count entries for BOTH for $table\n";
} # foreach my $table (@tables)

foreach my $table (@tables) {
  my $count = 0;
  foreach my $key (sort keys %cgc) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey = '$key';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $count++; }
  } # foreach my $key (sort keys %cgc)
  print OUT "There are $count entries for CGC ONLY for $table\n";
} # foreach my $table (@tables)

foreach my $table (@tables) {
  my $count = 0;
  foreach my $key (sort keys %pmid) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey = '$key';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $count++; }
  } # foreach my $key (sort keys %pmid)
  print OUT "There are $count entries for PMID ONLY for $table\n";
} # foreach my $table (@tables)

