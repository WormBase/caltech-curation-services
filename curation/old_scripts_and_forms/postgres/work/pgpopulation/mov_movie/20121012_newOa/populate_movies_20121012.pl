#!/usr/bin/perl -w

# populate rnai movies into mov_ OA tables for Daniela.  2012 10 15
#
# live run on tazendra.  2012 10 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $pgid = '0';
$result = $dbh->prepare( "SELECT * FROM mov_curator ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow(); if ($row[0]) { $pgid = $row[0]; }


my %rnai;
$result = $dbh->prepare( "SELECT * FROM rna_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $rnai{$row[1]}++; }

# my %genes;
# $result = $dbh->prepare( "SELECT * FROM gin_seqname" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }
# $result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }
# $result = $dbh->prepare( "SELECT * FROM gin_locus " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }

# my $paper = '"WBPaper00040986"';
my $curator = 'WBPerson12028';

# my %addQuotes;
# $addQuotes{'driven_by_gene'}++;
# $addQuotes{'gene'}++;
# $addQuotes{'reporter_product'}++;
# $addQuotes{'paper'}++;

my $infile = 'Movies_20121012.ace';
$/ = "";
open(IN, "<$infile") or die "Cannot open $infile : $!";
my $headers = <IN>;
while (my $para = <IN>) {
  my @lines = split/\n/, $para;
  my $header = shift @lines;
  my $source = '';
  if ($header =~ m/\"(.*?)\"/) { $source = $1; }
  my $rnai = ''; my $remark = '';
  foreach my $line (@lines) {
    my ($tag, $data) = $line =~ m/^(\S+)\s+\"(.*?)\"$/;
    if ($tag eq 'Remark') { $remark = $data; }
      elsif ($tag eq 'RNAi') { $rnai = $data; }		# these are not rnai oa objects, just text for citaceMinus objects, Daniela 2012 10 15
#       elsif ($tag eq 'RNAi') { 
#         if ($rnai{$data}) { $rnai = $data; }
#           else { print "ERR $data not a valid RNAi object in rna_name for $source\n"; } }
      else { print "$tag not accounted for in $line\n"; }
  } # foreach my $line (@lines)
  $pgid++;
  my $movId = &pad10Zeros($pgid);
  my $objId = 'WBMovie'. $movId;
  &insertToPostgresTableAndHistory('mov_name',    $pgid, $objId);
#   &insertToPostgresTableAndHistory('mov_paper',   $pgid, $paper);
  &insertToPostgresTableAndHistory('mov_curator', $pgid, $curator);
  if ($source) { &insertToPostgresTableAndHistory('mov_source', $pgid, $source); }
  if ($rnai)   { &insertToPostgresTableAndHistory('mov_rnai'  , $pgid, $rnai  ); }
  if ($remark) { &insertToPostgresTableAndHistory('mov_remark', $pgid, $remark); }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";
$/ = "\n";

sub insertToPostgresTableAndHistory {
  my ($table, $joinkey, $newValue) = @_;
  if ($newValue =~ m/\'/) { $newValue =~ s/\'/''/g; }
  unless (is_utf8($newValue)) { from_to($newValue, "iso-8859-1", "utf8"); }
  my $returnValue = '';
#   print "INSERT INTO $table VALUES ('$joinkey', E'$newValue')\n";
  my $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', E'$newValue')" );
# UNCOMMENT TO POPULATE
  $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
  $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', E'$newValue')" );
# UNCOMMENT TO POPULATE
  $result->execute() or $returnValue .= "ERROR, failed to insert to ${table}_hst &insertToPostgresTableAndHistory\n";
  unless ($returnValue) { $returnValue = 'OK'; }
  return $returnValue;
} # sub insertToPostgresTableAndHistory


sub pad10Zeros {                # take a number and pad to 10 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '000000000' . $number; }
  elsif ($number < 100) { $number = '00000000' . $number; }
  elsif ($number < 1000) { $number = '0000000' . $number; }
  elsif ($number < 10000) { $number = '000000' . $number; }
  elsif ($number < 100000) { $number = '00000' . $number; }
  elsif ($number < 1000000) { $number = '0000' . $number; }
  elsif ($number < 10000000) { $number = '000' . $number; }
  elsif ($number < 100000000) { $number = '00' . $number; }
  elsif ($number < 1000000000) { $number = '0' . $number; }
  return $number;
} # sub pad10Zeros


sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros

__END__


DELETE FROM mov_name                WHERE mov_timestamp > '2012-10-04 18:00';
DELETE FROM mov_source              WHERE mov_timestamp > '2012-10-04 18:00';
DELETE FROM mov_rnai                WHERE mov_timestamp > '2012-10-04 18:00';
DELETE FROM mov_remark              WHERE mov_timestamp > '2012-10-04 18:00';
DELETE FROM mov_curator             WHERE mov_timestamp > '2012-10-04 18:00';
