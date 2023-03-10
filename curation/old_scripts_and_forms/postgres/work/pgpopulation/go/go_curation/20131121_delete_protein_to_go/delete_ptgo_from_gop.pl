#!/usr/bin/perl -w

# delete from gop_ tables any entries of genes that exist in gp_association.ace
# for Kimberly and Ranjana.  live run  2013 11 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %wbgenes; my %joinkeys;
my $infile = "gp_association.ace";
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my ($wbgene) = $entry =~ m/Gene : \"(WBGene\d+)\"/;
  $wbgenes{$wbgene}++;
} # while (my $entry = <IN>)
close (IN) or die "Cannot open $infile : $!";
$/ = "\n";

my $wbgenes = join"','", sort keys %wbgenes;

my @gop_tables = qw( gop_accession gop_comment gop_curator gop_dbtype gop_goid gop_goinference gop_goontology gop_lastupdate gop_paper gop_project gop_protein gop_qualifier gop_wbgene gop_with gop_with_wbgene gop_with_wbvariation gop_xrefto );

$result = $dbh->prepare( "SELECT * FROM gop_wbgene WHERE gop_wbgene IN ('$wbgenes')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $joinkeys{$row[0]}++; }

my $joinkeys = join"','", sort {$a<=>$b} keys %joinkeys;
# print "J $joinkeys J\n";

my @pgcommands;
foreach my $table (@gop_tables) {
  foreach my $joinkey (sort {$a<=>$b} keys %joinkeys) {
    my $command = qq(INSERT INTO ${table}_hst VALUES ('$joinkey', NULL););
    push @pgcommands, $command;
  }
  my $command = qq(DELETE FROM $table WHERE joinkey IN ('$joinkeys'););
  push @pgcommands, $command;
} # foreach my $table (@gop_tables)

foreach my $command (@pgcommands) {
  print qq($command\n);
# UNCOMMENT TO REMOVE FROM POSTGRES
#   $dbh->do( $command );
} # foreach my $command (@pgcommands)
