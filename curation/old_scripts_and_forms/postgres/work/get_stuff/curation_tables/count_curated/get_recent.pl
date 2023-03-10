#!/usr/bin/perl -w
#
# check how many papers have been curated

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/count_curated/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";

my %pmHash;
my %cgcHash;
my %otherHash;
my %checkedoutHash;
my %curatedbyHash;
my %exist;

# my $result = $conn->exec( "SELECT joinkey FROM cur_curator;" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

&populateHashes();

print "count exist : " . scalar(keys %exist) . "\n";
foreach my $key (sort keys %exist) {
  if ($key =~ m/^pmid/) { if ($pmHash{$key}) { delete $exist{$key}; } }
} # foreach my $key (sort keys %exist)
print "count exist without doubles : " . scalar(keys %exist) . "\n";

print "count curated : " . scalar(keys %curatedbyHash) . "\n";
foreach my $key (sort keys %curatedbyHash) {
  if ($key =~ m/^pmid/) { if ($pmHash{$key}) { delete $curatedbyHash{$key}; } }
} # foreach my $key (sort keys %curatedbyHash)
print "count curated without doubles : " . scalar(keys %curatedbyHash) . "\n";

close (OUT) or die "Cannot close $outfile : $!";

sub populateHashes { 
    # check xreferences 
  my $result = $conn->exec( "SELECT * FROM ref_xref;" ); 
  my @row;
  while (@row = $result->fetchrow) {    # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];
    $pmHash{$row[1]} = $row[0];
    $row[0] =~ s/cgc//;
    $row[1] =~ s/pmid//;
    $otherHash{$row[0]} = $row[1];
    $otherHash{$row[1]} = $row[0];
  } # while (my @row = $result->fetchrow) 
  $result = $conn->exec ( "SELECT * FROM ref_checked_out;" );
  while (@row = $result->fetchrow) {
    $checkedoutHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
    # check if curated
  $result = $conn->exec ( "SELECT * FROM cur_curator;" ); 
  while (@row = $result->fetchrow) {
    $curatedbyHash{$row[0]} = $row[1]; 
  } # while (@row = $result->fetchrow)
  $result = $conn->exec ( "SELECT * FROM ref_cgc;" ); 
  while (@row = $result->fetchrow) {
    $exist{$row[0]} = $row[1]; 
  } # while (@row = $result->fetchrow)
  $result = $conn->exec ( "SELECT * FROM ref_pmid;" ); 
  while (@row = $result->fetchrow) {
    $exist{$row[0]} = $row[1]; 
  } # while (@row = $result->fetchrow)
} # sub populateHashes

