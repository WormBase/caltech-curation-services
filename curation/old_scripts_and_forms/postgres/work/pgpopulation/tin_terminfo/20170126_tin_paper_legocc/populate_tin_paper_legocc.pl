#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
push @pgcommands, qq(DELETE FROM tin_paper_legocc);

my %locus;
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $locus{"WBGene$row[0]"} = $row[1]; }
my %terms;
$result = $dbh->prepare( "SELECT * FROM obo_name_goid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $terms{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $terms{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $terms{$row[0]} = $row[1]; }

$/ = "";
# my $infile = 'lego_cc_annotations/gp_annotation.ace';
my $infile = 'gp_annotation.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  next unless ($para =~ m/Reference\t\"(WBPaper\d+)\"/);
  my ($paper) = $para =~ m/Reference\t\"WBPaper(\d+)\"/;
  my ($gene) = $para =~ m/Gene\t\"(WBGene\d+)\"/;
  my $locus = $gene; if ($locus{$gene}) { $locus = $locus{$gene}; }
  my ($annotrel) = $para =~ m/Annotation_relation\t\"(.*)\"/;
  next unless ( ($annotrel eq 'part_of') || ($annotrel eq 'colocalizes_with'));
  my ($goid) = $para =~ m/GO_term\t\"(GO.*)\"/;
  if ($terms{$goid}) { $goid = $terms{$goid}; }
  my ($gocode) = $para =~ m/GO_code\t\"(.*)\"/;
  my (@lines) = split/\n/, $para;
  my %gtr; my %lsr;
  foreach my $line (@lines) {
    if ($line =~ m/Life_stage_relation\t\"(.*)\"\t\"(.*)\"/) {
      my $term = $2;
      if ($terms{$term}) { $term = $terms{$term}; }
      $lsr{$1}{$term}++; }
    if ($line =~ m/GO_term_relation\t\"(.*)\"\t\"(.*)\"/) {
      my $term = $2;
      if ($terms{$term}) { $term = $terms{$term}; }
      $gtr{$1}{$term}++; } } 
  my ($contributed_by) = $para =~ m/Contributed_by\t\"(.*)\"/;
  if ($contributed_by eq 'WormBase') { $contributed_by = ''; }
  my $gtr = '';
  foreach my $k1 (sort keys %gtr) {
    foreach my $k2 (sort keys %{ $gtr{$k1} }) {
      $gtr .= $k1 . '(' . $k2 . ') '; } }
  my $lsr = '';
  foreach my $k1 (sort keys %lsr) {
    foreach my $k2 (sort keys %{ $lsr{$k1} }) {
      $lsr .= $k1 . '(' . $k2 . ') '; } }
  my @data = ();
  if ($locus) { push @data, $locus; }
  if (($annotrel) && ($goid) ) { push @data, qq($annotrel $goid); }
    elsif ($goid) { push @data, $goid; }
    elsif ($annotrel) { push @data, $annotrel; }
  if ($gocode) { push @data, $gocode; }
  if ($gtr) { push @data, $gtr; }
  if ($lsr) { push @data, $lsr; }
  if ($contributed_by) { push @data, $contributed_by; }
  my $data = join", ", @data;
#   print qq($paper\t$locus, $annotrel $goid, $gocode, $gtr, $lsr, $contributed_by\n);
#   push @pgcommands, qq(INSERT INTO tin_paper_legocc VALUES ('$paper', '$locus, $annotrel $goid, $gocode, $gtr, $lsr, $contributed_by'));
  push @pgcommands, qq(INSERT INTO tin_paper_legocc VALUES ('$paper', '$data'));
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
#   print qq( $pgcommand\n);
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
}



__END__

