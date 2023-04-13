#!/usr/bin/perl -w

# populate gop_ tables in postgres based on newGpaEntries file that Kimberly generates.  2015 02 19
#
# ran on tazendra  2015 02 26
#
# source data from WS247 was bad.  Removed all of it and reran with WS248 data.  2015 04 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $infile = 'newGpaEntries';

my $pgid = &getHighestPgid();
# print "$pgid \n";

my $count = 0;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
#   $count++; last if ($count > 10);
  chomp $line;
  my (@line) = split/\t/, $line;
  my $wbgene        = $line[1];
#   my $qualifier     = $line[3];		# will never be in the file
  my $qualifier     = 'involved_in';
  my $goid          = $line[4];
  my $papField      = $line[5];
#   my $goinference   = $line[6];		# will always be IEA regardless of what file says
  my $goinference   = 'IEA';
  my $withField     = $line[7];
  my $goontology    = $line[8];
  my $dbtype        = $line[11];
  my $dateField     = $line[13];
  my ($paper)       = $papField =~ m/(WBPaper\d+)/;
  my ($wbvar)       = $withField =~ m/(WBVar\d+)/;        if ($wbvar)       { $wbvar       = '"' . $wbvar . '"';        }
  my ($wbphenotype) = $withField =~ m/(WBPhenotype:\d+)/; if ($wbphenotype) { $wbphenotype = '"' . $wbphenotype . '"';  }
  my ($wbrnai)      = $withField =~ m/(WBRNAi\d+)/;       if ($wbrnai)      { $wbrnai      = '"' . $wbrnai . '"';       }
  my $curator       = 'WBPerson3111';
  my $project       = '';
  my $lastupdate = ''; if ($dateField =~ m/^(\d{4})(\d{2})(\d{2})$/) { $lastupdate = "${1}-${2}-${3}"; } else { $lastupdate = '2014-10-29'; }
  if ($wbrnai) {      $project = 'RNAi Phenotype2GO';      }
    elsif ($wbvar)  { $project = 'Variation phenotype2GO'; }
  if ($wbgene) {
    $pgid++;
    if ($wbgene)        { &insertToPostgresTableAndHistory('gop_wbgene', $pgid, $wbgene); }
    if ($curator)       { &insertToPostgresTableAndHistory('gop_curator', $pgid, $curator); }
    if ($qualifier)     { &insertToPostgresTableAndHistory('gop_qualifier', $pgid, $qualifier); }
    if ($goid)          { &insertToPostgresTableAndHistory('gop_goid', $pgid, $goid); }
    if ($paper)         { &insertToPostgresTableAndHistory('gop_paper', $pgid, $paper); }
    if ($goinference)   { &insertToPostgresTableAndHistory('gop_goinference', $pgid, $goinference); }
    if ($goontology)    { &insertToPostgresTableAndHistory('gop_goontology', $pgid, $goontology); }
    if ($dbtype)        { &insertToPostgresTableAndHistory('gop_dbtype', $pgid, $dbtype); }
    if ($lastupdate)    { &insertToPostgresTableAndHistory('gop_lastupdate', $pgid, $lastupdate); }
    if ($project)       { &insertToPostgresTableAndHistory('gop_project', $pgid, $project); }
    if ($wbvar)         { &insertToPostgresTableAndHistory('gop_with_wbvariation', $pgid, $wbvar); }
    if ($wbphenotype)   { &insertToPostgresTableAndHistory('gop_with_phenotype', $pgid, $wbphenotype); }
    if ($wbrnai)        { &insertToPostgresTableAndHistory('gop_with_rnai', $pgid, $wbrnai); }
  } # if ($wbgene)
  
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


sub insertToPostgresTableAndHistory {           
  my ($table, $joinkey, $newValue) = @_;
  my $returnValue = '';
  print qq( "INSERT INTO $table VALUES ('$joinkey', '$newValue')"\n );
# UNCOMMENT TO POPULATE
#  my $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
#  $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
#  $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
#  $result->execute() or $returnValue .= "ERROR, failed to insert to ${table}_hst &insertToPostgresTableAndHistory\n";
} # sub insertToPostgresTableAndHistory

sub getHighestPgid {                                    # get the highest joinkey from the primary tables
#   ($var, my $datatype) = &getHtmlVar($query, 'datatype');
  my $datatype = 'gop';
  my %datatypes;
  @{ $datatypes{gop}{highestPgidTables} }            = qw( wbgene curator );
  if ($datatypes{$datatype}{highestPgidTables}) {
      my $pgUnionQuery = "SELECT MAX(joinkey::integer) FROM ${datatype}_" . join" UNION SELECT MAX(joinkey::integer) FROM ${datatype}_", @{ $datatypes{$datatype}{highestPgidTables} };
      my $result = $dbh->prepare( "SELECT max(max) FROM ( $pgUnionQuery ) AS max; " );
      $result->execute(); my @row = $result->fetchrow(); my $highest = $row[0];
      return $highest; }
    else { return "ERROR, no valid datatype for highestPgidTables"; }
} # sub getHighestPgid


__END__

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

DELETE FROM gop_wbgene                WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_qualifier             WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_goid                  WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_paper                 WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_goinference           WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_goontology            WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_dbtype                WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_lastupdate            WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_project               WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_curator               WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_with_wbvariation      WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_with_phenotype        WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_with_rnai             WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';

DELETE FROM gop_wbgene_hst            WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_qualifier_hst         WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_goid_hst              WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_paper_hst             WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_goinference_hst       WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_goontology_hst        WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_dbtype_hst            WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_lastupdate_hst        WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_project_hst           WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_curator_hst           WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_with_wbvariation_hst  WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_with_phenotype_hst    WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
DELETE FROM gop_with_rnai_hst         WHERE gop_timestamp > '2015-04-21 15:20' AND gop_timestamp < '2015-04-21 16:20';
