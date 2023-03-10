#!/usr/bin/perl -w

# populate pro_paperprimarystatus based on paper and pap_primary_data
# Chris will run this manually after populating topic papers.
# cronjob will run every day to update values in case someone changed the pap_primary_data value.
# This data is metadata about papers, not real data, so okay to populate with cronjob to OA datatype field,
# and history is not important.  Curators wanted this to be able to sort by primary / not_primary.  2014 08 07
#
# set cronjob in acedb account on tazendra for Chris
# 0 4 * * * /home/postgres/work/pgpopulation/pro_process/cronjobs/populate_pro_paperprimarystatus.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pap_primary_data;
$result = $dbh->prepare( "SELECT * FROM pap_primary_data" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap_primary_data{"WBPaper$row[0]"} = $row[1]; } }

my @insert;
$result = $dbh->prepare( "SELECT * FROM pro_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $pgid = $row[0]; my $paper = $row[1]; my $status = 'no_value_found';
    if ($pap_primary_data{$paper}) { $status = $pap_primary_data{$paper}; }
    push @insert, qq(('$pgid', '$status'));
} }

my $insert = join", ", @insert;
my $command = "DELETE FROM pro_paperprimarystatus";
$dbh->do( $command );
$command = "INSERT INTO pro_paperprimarystatus VALUES $insert";
# print "$command\n";
$dbh->do( $command );

