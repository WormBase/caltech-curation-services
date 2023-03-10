#!/usr/bin/perl -w

# intersection paper list by looking for papers in both disease and antibody OA
# (dis_paperexpmod | dis_paperdisrel) && (abp_original_publication | abp_paper)
# For Xiaodong and Ranjana  2015 10 07


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %dis; my %abp;
my @dis = qw( paperexpmod paperdisrel );
my @abp = qw( paper original_publication );

foreach my $abp (@abp) {
  $result = $dbh->prepare( "SELECT * FROM abp_$abp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my (@paps) = $row[1] =~ m/(WBPaper\d+)/g;
    foreach (@paps) { $abp{$_}++; } } }

foreach my $dis (@dis) {
  $result = $dbh->prepare( "SELECT * FROM dis_$dis" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my (@paps) = $row[1] =~ m/(WBPaper\d+)/g;
    foreach (@paps) { $dis{$_}++; } } }

foreach my $pap (sort keys %dis) {
  if ($abp{$pap}) { print "$pap\n"; }
} # foreach my $pap (sort keys %dis)

