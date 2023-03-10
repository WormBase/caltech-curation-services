#!/usr/bin/perl -w

# populate gin_genesequencelab with data from gin_locus, gin_synonym, and gin_sequence.
# should still associate with proper labs from seq_loc aceserver script based on 
# Sequence -> From_laboratory.   2009 03 19
#
# HX is Hinxton, RW is Wash U.  
# Got a seq_loc file from WS on spica.  hopefully will have an aceserver on spica or 
# somewhere local to setup a cronjob, otherwise will FTP it out off cron and populate
# with this script.  Many entries don't have sequences or labs.  2009 03 21
#
# repopulated with ws200 data.  2009 03 23

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = '';
my $result2 = '';

my %seq_loc;
# my $seq_loc_file = 'seq_loc.ws_20090320';
my $seq_loc_file = 'seq_loc.ws200';
open (IN, "<$seq_loc_file") or die "Cannot open $seq_loc_file : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($seq, $loc) = split/\t/, $line;
  ($seq) = lc($seq);
  $seq_loc{$seq} = $loc;
} 
close (IN) or die "Cannot close $seq_loc_file : $!";

my %gene_seq;

$result = $conn->exec( "DELETE FROM gin_genesequencelab;" );

$result = $conn->exec( "SELECT * FROM gin_sequence;" );
while (my @row = $result->fetchrow) {
  my $wbgene = $row[0];
  my $sequence = $row[1];
  if ($sequence =~ m/^(.*)\./) { $sequence = $1; }
  $sequence = lc($sequence);
  $gene_seq{$wbgene} = $sequence;  my $lab = '';
  if ($seq_loc{$sequence}) { $lab = $seq_loc{$sequence}; }
  unless ($lab) { print "NO LAB from gin_sequence $row[0] $row[1] converted to $sequence\n"; }
  $row[1] = lc($row[1]);
  $result2 = $conn->exec( "INSERT INTO gin_genesequencelab VALUES ('$row[1]', '$row[0]', '$lab');" );
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM gin_locus ;" );
while (my @row = $result->fetchrow) {
  my $lab = ''; my $sequence = '';
  if ($gene_seq{$row[0]}) { 
      $sequence = $gene_seq{$row[0]}; 
      if ($seq_loc{$sequence}) { $lab = $seq_loc{$sequence}; } 
      unless ($lab) { print "NO LAB from gin_locus $row[0] $row[1] converted to $sequence\n"; } }
    else { print "NO SEQUENCE from gin_locus @row\n"; }
  $row[1] = lc($row[1]);
  $result2 = $conn->exec( "INSERT INTO gin_genesequencelab VALUES ('$row[1]', '$row[0]', '$lab');" );
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM gin_synonyms WHERE gin_syntype = 'locus' ;" );
while (my @row = $result->fetchrow) {
  unless ($gene_seq{$row[0]}) { print "NO SEQUENCE from gin_synonyms @row\n"; next; }
  my $lab = ''; my $sequence = '';
  if ($gene_seq{$row[0]}) { 
      $sequence = $gene_seq{$row[0]}; 
      if ($seq_loc{$sequence}) { $lab = $seq_loc{$sequence}; } 
      unless ($lab) { print "NO LAB from gin_synonyms $row[0] $row[1] converted to $sequence\n"; } }
    else { print "NO SEQUENCE from gin_synonyms @row\n"; }
  $row[1] = lc($row[1]);
  $result2 = $conn->exec( "INSERT INTO gin_genesequencelab VALUES ('$row[1]', '$row[0]', '$lab');" );
} # while (@row = $result->fetchrow)

__END__

