#!/usr/bin/perl -w

# convert Xiaodong's ggi_ data to int_ format  2010 10 28
#
# fixed genes missing "WBGene" and not having a remark.  2010 11 05
#
# changed remark to say from Xiaodong Wang.  2010 11 08
# 
# run on mangolassi.  2010 11 10
#
# live run on tazendra.  2011 01 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $errfile = 'move_ggi_to_int.err';
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my %toWBGene;
&populateToWBGene();

my %pap;
&populatePap();

my @noeff = qw( Genetic No_interaction Predicted_interaction Physical_interaction Synthetic Mutual_enhancement Mutual_suppression );
my @yeseff = qw( Regulatory Suppression Enhancement Epistasis );
my %intTypes;
foreach my $type (@noeff) { $intTypes{$type} = 'Non_directional'; }
foreach my $type (@yeseff) { $intTypes{$type} = 'blank'; }

my @pgcommands;
my @delete_from = qw( curator geneone genetwo sentid type nondirectional paper remark );
foreach my $table (@delete_from) {
  push @pgcommands, "DELETE FROM int_${table} WHERE CAST (joinkey AS INTEGER) > '8532';";
  push @pgcommands, "DELETE FROM int_${table}_hst WHERE CAST (joinkey AS INTEGER) > '8532';";
}
foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT THIS TO WRITE TO POSTGRES
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

@pgcommands = ();

$result = $dbh->prepare( "SELECT * FROM int_curator ORDER BY joinkey::integer DESC; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow() ;
my $joinkey = $row[0];		# highest used joinkey



$result = $dbh->prepare( "SELECT * FROM ggi_gene_gene_interaction WHERE ggi_interaction != 'No_interaction' AND ggi_interaction != 'Other_Genetic' AND ggi_interaction != 'Interaction'  " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my ($old_joinkey, $sid, $l1, $l2, $type, $timestamp) = @row; 
    next unless ($l1 && $l1);
    my $err = 0;
    my ($w1, $w2);
    if ($l1 =~ m/\s/) { $l1 =~ s/\s//g; }
    if ($l2 =~ m/\s/) { $l2 =~ s/\s//g; }
    if ($toWBGene{$l1}) { $w1 = $toWBGene{$l1}; }
    if ($toWBGene{$l2}) { $w2 = $toWBGene{$l2}; }
    $sid = 'xiaodong001 : ' . $sid;
    my $remark = 'Interaction data was extracted by Xiaodong Wang from sentences enriched by Textpresso. The interaction was attributed to the paper(s) from which it was extracted.';
    my ($paper) = $sid =~ m/(WBPaper\d+)/;
    if ($pap{$paper}) { $paper = $pap{$paper}; }
      else { print ERR "ERR no paper match for $paper in ROW : @row\n"; $err++; }
    unless ($w1) { print ERR "ERR no wbgene match for $l1 in ROW : @row\n"; $err++; }
    unless ($w2) { print ERR "ERR no wbgene match for $l2 in ROW : @row\n"; $err++; }
    my $nond;
    if ($intTypes{$type}) { 
        $nond = $intTypes{$type}; if ($nond eq 'blank') { $nond = ''; } }
      else { print ERR "ERR no type match for $type in ROW : @row\n"; $err++; }
    unless ($err) {
      $joinkey++;
      push @pgcommands, "INSERT INTO int_curator VALUES ('$joinkey', 'WBPerson1760', '$timestamp');";
      push @pgcommands, "INSERT INTO int_curator_hst VALUES ('$joinkey', 'WBPerson1760', '$timestamp');";
      push @pgcommands, "INSERT INTO int_geneone VALUES ('$joinkey', '$w1', '$timestamp');";
      push @pgcommands, "INSERT INTO int_geneone_hst VALUES ('$joinkey', '$w1', '$timestamp');";
      push @pgcommands, "INSERT INTO int_genetwo VALUES ('$joinkey', '$w2', '$timestamp');";
      push @pgcommands, "INSERT INTO int_genetwo_hst VALUES ('$joinkey', '$w2', '$timestamp');";
      push @pgcommands, "INSERT INTO int_sentid VALUES ('$joinkey', '$sid', '$timestamp');";
      push @pgcommands, "INSERT INTO int_sentid_hst VALUES ('$joinkey', '$sid', '$timestamp');";
      push @pgcommands, "INSERT INTO int_type VALUES ('$joinkey', '$type', '$timestamp');";
      push @pgcommands, "INSERT INTO int_type_hst VALUES ('$joinkey', '$type', '$timestamp');";
      push @pgcommands, "INSERT INTO int_nondirectional VALUES ('$joinkey', '$nond', '$timestamp');";
      push @pgcommands, "INSERT INTO int_nondirectional_hst VALUES ('$joinkey', '$nond', '$timestamp');";
      push @pgcommands, "INSERT INTO int_paper VALUES ('$joinkey', '$paper', '$timestamp');";
      push @pgcommands, "INSERT INTO int_paper_hst VALUES ('$joinkey', '$paper', '$timestamp');";
      push @pgcommands, "INSERT INTO int_remark VALUES ('$joinkey', '$remark', '$timestamp');";
      push @pgcommands, "INSERT INTO int_remark_hst VALUES ('$joinkey', '$remark', '$timestamp');";
    }
} }

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT THIS TO WRITE TO POSTGRES
  $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

close (ERR) or die "Cannot close $errfile : $!";


sub populateToWBGene {
  $result = $dbh->prepare( "SELECT * FROM gin_sequence" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $toWBGene{$row[1]} = "WBGene$row[0]"; }
  $result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $toWBGene{$row[1]} = "WBGene$row[0]"; }
  $result = $dbh->prepare( "SELECT * FROM gin_locus" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $toWBGene{$row[1]} = "WBGene$row[0]"; }
  $toWBGene{"F55F8.2"} = 'WBGene00018890';	# manual for X  2010 10 08
  $toWBGene{"M01E5.5"} = 'WBGene00006595';
  $toWBGene{"T27A3.1"} = 'WBGene00020838';	# these 5 are not in postgres, but are in acedb, from X  2010 10 27
  $toWBGene{"ZC97.1"} = 'WBGene00022516';
  $toWBGene{"F11A3.2"} = 'WBGene00008670';
  $toWBGene{"Y67D2.1"} = 'WBGene00022051';
  $toWBGene{"sprgenes"} = 'WBGene00005007';
} # sub populateToWBGene

sub populatePap {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^0'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $pap{"WBPaper$row[1]"} = "WBPaper$row[0]"; }
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $pap{"WBPaper$row[0]"} = "WBPaper$row[0]"; }
} # sub populatePap
