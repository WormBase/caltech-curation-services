#!/usr/bin/perl -w

# find dead variations from nameserver dump and in postgres app_ grg_ int_ only. 2011 07 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %ns;
my $infile = 'nameserver.txt'; $/ = undef;
open (IN, "<$infile") or die "Cannot open infile : $!";
my $ns_data = <IN>;
close (IN) or die "Cannot close infile : $!";
my @objs = split/\],\n   \[/, $ns_data;
foreach my $obj (@objs) { 
  my $var = ''; if ($obj =~ m/\"(WBVar\d+)\"/) { $var = $1; }
  if ($obj =~ m/"0"/) { $ns{$var}++; }
} # foreach my $obj (@objs)

my %pg;
my @tables = qw( app_variation int_variationone int_variationtwo grg_allele );
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      my (@data) = $row[1] =~ m/(WBVar\d+)/g;
      foreach my $var (@data) {
        $pg{$table}{$var}++; } } } }

foreach my $table (sort keys %pg) {
  foreach my $pg_var (sort keys %{ $pg{$table} }) {
    if ($ns{$pg_var}) { print "DEAD $pg_var and in $table in postgres\n"; } }
} # foreach my $pg (sort keys %pg)

__END__

[
   [
      "WBVar00278402",
      "Public_name",
      "",
      "0"
   ],
   [
      "WBVar00296783",
      "Public_name",
      "",
      "0"
   ],
   [
      "WBVar00278581",
      "Public_name",
      "       Strain: AA1      Species: Caenorhabditis elegans     Genotype: daf-12(rh2",
      "0"
   ],
   [
      "WBVar00278583",
      "Public_name",
      "       Strain: AA10      Species: Caenorhabditis elegans     Genotype: daf-12(rh",
      "0"
   ],
   [
      "WBVar00278596",
      "Public_name",
      "       Strain: AA107      Species: Caenorhabditis elegans     Genotype: nhr-48(o",
      "0"
   ],
   [
      "WBVar00278584",
      "Public_name",
      "       Strain: AA18      Species: Caenorhabditis elegans     Genotype: daf-12(rh",
      "0"
   ],
   [
      "WBVar00278585",
      "Public_name",
