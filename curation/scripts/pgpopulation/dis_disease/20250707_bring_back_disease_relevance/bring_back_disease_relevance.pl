#!/usr/bin/env perl

# for Ranjana, query entries that at some point had a null in dis_diseaserelevance_hst.  check that currently they have
# no data in dis_diseaserelevance, have a curator in dis_curator, can retrieve something useful from the latest
# dis_diseaserelevance_hst entry, and have either a dis_wbgene or dis_assertedgene.  2025 07 07
#
# Skip entries with multiple dis_assertedgene, Ranjana doesn't want those.  2025 07 09
# This doesn't properly escape singlequotes when creating data, so it's failing on those entries.  Luckily the only entry
# with singlequotes is the last one.  Don't use this script as a model of how to populate data in the future.  2025 07 09


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my %curator;
$result = $dbh->prepare( "SELECT * FROM dis_curator" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $curator{$row[0]} = $row[1]; } }

my %current;
$result = $dbh->prepare( "SELECT * FROM dis_diseaserelevance" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $current{$row[0]} = $row[1]; } }

my %hasNull;
$result = $dbh->prepare( "SELECT DISTINCT(joinkey) FROM dis_diseaserelevance_hst WHERE dis_diseaserelevance_hst IS NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    next unless ($curator{$row[0]});
    next if ($current{$row[0]});
    $hasNull{$row[0]}++;
} }

my %recentData;
my $joinkeys = join"','", sort {$a<=>$b} keys %hasNull;
$result = $dbh->prepare( "SELECT * FROM dis_diseaserelevance_hst WHERE joinkey IN ('$joinkeys') ORDER BY dis_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    if ($row[1]) { 
      next if ($row[1] eq '.');
      $recentData{$row[0]} = $row[1]; }
} }

my %subject;
# my @list = qw( dis_wbgene dis_variation dis_strain dis_transgene dis_genotype );
my @list = qw( dis_wbgene dis_assertedgene );
foreach my $table (@list) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey IN ('$joinkeys')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $subject{$table}{$row[0]} = $row[1]; } }
}

my @pgcommands;
foreach my $joinkey (sort {$a<=>$b} keys %hasNull) {
  next unless ($recentData{$joinkey});
  my $wbgene = $subject{'dis_wbgene'}{$joinkey};
  unless ($wbgene) { $wbgene = $subject{'dis_assertedgene'}{$joinkey}; }
  unless ($wbgene) { $wbgene = 'SKIP'; }
  if ($wbgene =~ m/","/) { $wbgene = 'SKIP'; }
  print qq($joinkey\t$wbgene\t$recentData{$joinkey}\n);
  if ($wbgene ne 'SKIP') {
    push @pgcommands, qq(INSERT INTO dis_diseaserelevance_hst VALUES ('$joinkey', '$recentData{$joinkey}'););
    push @pgcommands, qq(DELETE FROM dis_diseaserelevance WHERE joinkey = '$joinkey';);
    push @pgcommands, qq(INSERT INTO dis_diseaserelevance VALUES ('$joinkey', '$recentData{$joinkey}'););
  }
}


# check pgid 110  has linebreaks
foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
}



__END__

