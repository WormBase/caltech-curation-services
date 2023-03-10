#!/usr/bin/perl -w

# analyze go data for Kimberly  2018 06 05

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hasAnnot;
$/ = "";
my $gofile = '/home/acedb/kimberly/citace_upload/go/gpad2ace/2018_June/gp_annotation.ace';
open (IN, "<$gofile") or die "Cannot open $gofile : $!";
while (my $entry = <IN>) {
  if ($entry =~ m/Annotation_relation\s+"involved_in"/) { 
    my ($gene) = $entry =~ m/Gene\s+"(.*?)"/;
    $hasAnnot{$gene}++; } }
close (IN) or die "Cannot close $gofile : $!";

$result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Abstract read'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my ($pap, $gene, $order, $curator, $timestamp, $evi) = @row;
  $pap = 'WBPaper' . $pap;
  $gene = 'WBGene' . $gene;
  my ($locus) = $evi =~ m/"Abstract read (.*?)"/;
  unless ($hasAnnot{$gene}) { print qq($pap\t$gene\t$locus\n); }
} # while (@row = $result->fetchrow)

