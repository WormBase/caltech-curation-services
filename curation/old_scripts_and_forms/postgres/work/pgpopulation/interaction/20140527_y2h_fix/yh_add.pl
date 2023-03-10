#!/usr/bin/perl -w

# add YH data.  for Chris.  2014 05 27
# live run 2014 05 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $highestPgid;
$result = $dbh->prepare( "SELECT * FROM int_curator ORDER BY joinkey::int DESC LIMIT 1" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $highestPgid = $row[0]; }

my %gin_dead;
$result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gin_dead{$row[0]}++; }

my %gin;
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($gin_dead{$row[0]});
    $gin{$row[1]} = "WBGene$row[0]"; }
} # while (@row = $result->fetchrow)

#   DELETE FROM int_curator         WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_paper           WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_type            WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_detectionmethod WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_laboratory      WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_throughput      WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_remark          WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_genebait        WHERE int_timestamp > '2014-05-27 15:25';
#   DELETE FROM int_genetarget      WHERE int_timestamp > '2014-05-27 15:25';

my $remark = 'This interaction was not present in the original WormBase dataset for this publication; this interaction has since been added to the dataset. See WBPaper00032484 (Simonis et al 2009) for details of reprocessing of the data from the original 2004 paper.';
my $curator = 'WBPerson2987';
my $paper   = 'WBPaper00006332';
my $type    = "Physical";
my $detectionmethod    = '"Yeast_two_hybrid"';
my $laboratory    = "MV";
my $throughput    = 'High_throughput';

my @pgcommands;
my $infile = 'Gene_pairs_to_ADD_to_OA_5-23-2014.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my $genebait = ''; my $genetarget = '';
  my ($one, $two) = split/\t/, $line; 
  if ($gin{$one}) { $genebait = $gin{$one}; }
    else { print "NO MATCH FOR $one\n"; }
  if ($gin{$two}) { $genetarget = '"' . $gin{$two} . '"'; }
    else { print "NO MATCH FOR $two\n"; }
  next unless ($genebait && $genetarget);
  $highestPgid++;
  push @pgcommands, qq(INSERT INTO int_curator         VALUES ('$highestPgid', '$curator'););
  push @pgcommands, qq(INSERT INTO int_paper           VALUES ('$highestPgid', '$paper'););
  push @pgcommands, qq(INSERT INTO int_type            VALUES ('$highestPgid', '$type'););
  push @pgcommands, qq(INSERT INTO int_detectionmethod VALUES ('$highestPgid', '$detectionmethod'););
  push @pgcommands, qq(INSERT INTO int_laboratory      VALUES ('$highestPgid', '$laboratory'););
  push @pgcommands, qq(INSERT INTO int_throughput      VALUES ('$highestPgid', '$throughput'););
  push @pgcommands, qq(INSERT INTO int_remark          VALUES ('$highestPgid', '$remark'););
  push @pgcommands, qq(INSERT INTO int_genebait        VALUES ('$highestPgid', '$genebait'););
  push @pgcommands, qq(INSERT INTO int_genetarget      VALUES ('$highestPgid', '$genetarget'););

  push @pgcommands, qq(INSERT INTO int_curator_hst         VALUES ('$highestPgid', '$curator'););
  push @pgcommands, qq(INSERT INTO int_paper_hst           VALUES ('$highestPgid', '$paper'););
  push @pgcommands, qq(INSERT INTO int_type_hst            VALUES ('$highestPgid', '$type'););
  push @pgcommands, qq(INSERT INTO int_detectionmethod_hst VALUES ('$highestPgid', '$detectionmethod'););
  push @pgcommands, qq(INSERT INTO int_laboratory_hst      VALUES ('$highestPgid', '$laboratory'););
  push @pgcommands, qq(INSERT INTO int_throughput_hst      VALUES ('$highestPgid', '$throughput'););
  push @pgcommands, qq(INSERT INTO int_remark_hst          VALUES ('$highestPgid', '$remark'););
  push @pgcommands, qq(INSERT INTO int_genebait_hst        VALUES ('$highestPgid', '$genebait'););
  push @pgcommands, qq(INSERT INTO int_genetarget_hst      VALUES ('$highestPgid', '$genetarget'););
}

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__
