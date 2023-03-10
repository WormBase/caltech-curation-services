#!/usr/bin/perl

# Look at citace paper dump, look at wpa_xref, see which exists in one
# and not the other.
#
# The output update_wpa_xref_fromcitace_missingfrompaper2wbpaper.outfile :
#
# Lists 3055 entries that are in postgres (from paper2wbpaper.txt) but
# not in citace.  Eimear says that this are for historical reasons, but
# aren't proper mappings, so they shouldn't be placed in citace.
# 
# Lists 1235 entries that are in citace but not in postgres (from
# paper2wbpaper.txt).  Eimear thinks they're probably wrong, but unless
# someone checks they shouldn't be deleted.
#
# 2005 06 17


use strict;
use diagnostics;
use Pg;

# my %cit_primary;
# my %pg_primary;
# my %not_primary;
# my %xref;

my %cit_xref;
my %pg_xref;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "update_wpa_xref_fromcitace_missingfrompaper2wbpaper.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

$/ = '';
my $infile = 'citace_papers_20050617.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my $paper = '';
  if ($entry =~ m/Paper : "(WBPaper\d+)"/) { $paper = $1; }
  if ($entry =~ m/CGC_name\s+\"(.*)\"/) { 
    my (@cgcs) = $entry =~ m/CGC_name\s+\"(.*)\"/g;
    foreach my $cgc (@cgcs) { $cit_xref{$paper}{$cgc}++; } }
  if ($entry =~ m/PMID\s+\"(.*)\"/) { 
    my (@pmids) = $entry =~ m/PMID\s+\"(.*)\"/g;
    foreach my $pmid (@pmids) { my $id = 'pmid' . $pmid; $cit_xref{$paper}{$id}++; } }
  if ($entry =~ m/Medline_name\s+\"(.*)\"/) { 
    my (@meds) = $entry =~ m/Medline_name\s+\"(.*)\"/g;
    foreach my $med (@meds) { my $id = 'med' . $med; $cit_xref{$paper}{$id}++; } }
  if ($entry =~ m/Old_WBPaper\s+\"(.*)\"/) { 
    my (@wbps) = $entry =~ m/Old_WBPaper\s+\"(.*)\"/g;
    foreach my $wbp (@wbps) { $cit_xref{$paper}{$wbp}++; } }
  if ($entry =~ m/Other_name\s+\"(.*)\"/) { 
    my (@oths) = $entry =~ m/Other_name\s+\"(.*)\"/g;
    foreach my $oth (@oths) { $cit_xref{$paper}{$oth}++; } }
  if ($entry =~ m/Meeting_abstract\s+\"(.*)\"/) { 
    my (@meets) = $entry =~ m/Meeting_abstract\s+\"(.*)\"/g;
    foreach my $meet (@meets) { $cit_xref{$paper}{$meet}++; } }
# if ($paper eq 'WBPaper00001493') {
#   foreach my $blah (sort keys %{ $cit_xref{WBPaper00001493} }) { print "BLAH $blah\n"; } }
# CGC_name         "cgc4301"
# PMID     "10704412"
# Medline_name     "20172040"
# Old_WBPaper      "WBPaper00004301"
# Other_name       "CSHSQB04p159"
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

my $result = $conn->exec( "SELECT * FROM wpa_xref ORDER BY joinkey;" );
while (my @row = $result->fetchrow) { 
# This outputs POSTGRES not in CITACE
  unless ($cit_xref{$row[0]}{$row[1]}) { print OUT "POS XREF not CIT $row[0] $row[1]\n"; }
  $pg_xref{$row[0]}{$row[1]}++; 
} # while (my @row = $result->fetchrow)

# This outputs CITACE not in POSTGRES
foreach my $wbpaper (sort keys %cit_xref) {
  foreach my $other (sort keys %{ $cit_xref{$wbpaper} }) {
    unless ($pg_xref{$wbpaper}{$other}) { print OUT "CIT XREF not POS $wbpaper $other\n"; }
  } # foreach my $other (sort keys %{ $cit_xref{$wbpaper} })
} # foreach my $wbpaper (sort keys %cit_xref)

