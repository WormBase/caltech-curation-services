#!/usr/bin/perl -w

# populate paper based on gene list from Kimberly originally from Michael Paulini WBPerson4055  2014 07 01
#
# new list and paper id.  live run on tazendra.  2014 07 21

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# CHANGE THIS TO 00038491 on tazendra
# my $paper = '00038491';
# my $paper = '00000003';
my $paper = '00045439';

my $curator = 'two1843';
my $timestamp = 'CURRENT_TIMESTAMP';
my $evi = 'Curator_confirmed "WBPerson4055"';
my $order = 0;	# check starting order on tazendra # not anymore, getting from postgres query

$result = $dbh->prepare( "SELECT pap_order FROM pap_gene WHERE joinkey = '$paper' AND pap_order IS NOT NULL ORDER BY pap_order::INTEGER DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my @row = $result->fetchrow(); if ($row[0]) { $order = $row[0]; }


# my $infile = 'gene_list';
my $infile = 'kimberley_revised_list_45439.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $gene = <IN>) {
  chomp $gene;
  my ($genenumber) = $gene =~ m/(\d+)/;
  $order++;
  my $pgcommand = qq(INSERT INTO pap_gene VALUES ('$paper', '$genenumber', '$order', '$curator', $timestamp, '$evi'););
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
  $pgcommand = qq(INSERT INTO h_pap_gene VALUES ('$paper', '$genenumber', '$order', '$curator', $timestamp, '$evi'););
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # while (my $gene = <IN>)
close (IN) or die "Cannot close $infile : $!";

