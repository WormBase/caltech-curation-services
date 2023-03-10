#!/usr/bin/perl -w

# Look at ref_pdf, then look at Wen's Reference directory to compare
# to Postgres.  Output what's in one and not the other.  2004 06 23

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_daniel/resync_PDF/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";


  # postgres pmids and pdfs
my %pg_xref;
my %pg_blank;
my %pg_full;
my $result = $conn->exec( "SELECT * FROM ref_xref;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $pg_xref{$row[0]} = $row[1];
    $pg_xref{$row[1]} = $row[0]; } }
$result = $conn->exec( "SELECT * FROM ref_pdf WHERE ref_pdf IS NOT NULL;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    if ($row[0] =~ m/pmid/) { if ($pg_xref{$row[0]}) { next; } }	# skip those as cgc
    $pg_full{$row[0]}++; } }
$result = $conn->exec( "SELECT * FROM ref_pdf WHERE ref_pdf IS NULL;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $pg_blank{$row[0]}++; } }


  # minerva pmids
my %ref_pmid;
my %ref_cgc;
my @pmid = </home2/wen/Reference/pubmed/pdf/*.pdf>;
foreach (@pmid) {
  my ($entry) = $_ =~ m/.*\/(.*)/;
  my ($pmid) = $entry =~ m/^(\d+)/;
  if ($pmid) {
    $pmid = 'pmid' . $pmid;
    if ($pg_xref{$pmid}) { next; } 	# skip those as cgc
    $ref_pmid{$pmid}++; }
  else { print "NO ENTRY $_\n"; } }

  # minerva cgc's
my @directory;
my @file;
my @Reference = </home2/wen/Reference/cgc/pdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; } }
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }
foreach (@file) {
  my ($file) = $_ =~ m/.*\/(.*)/;
  my ($cgc) = $_ =~ m/.*\/(\d+).*/;
  $cgc = 'cgc' . $cgc;
  $ref_cgc{$cgc}++; }


foreach my $ref (sort keys %ref_cgc) {
  if ($pg_blank{$ref}) { print "$ref IN MINERVA, not in Postgres\n"; } }
foreach my $ref (sort keys %ref_pmid) {
  if ($pg_blank{$ref}) { print "$ref IN MINERVA, not in Postgres\n"; } }
foreach my $ref (sort keys %pg_full) {
  if ($ref =~ m/cgc/) { unless ($ref_cgc{$ref}) { print "$ref IN POSTGRES, not in Minerva\n"; } }
  elsif ($ref =~ m/pmid/) { unless ($ref_pmid{$ref}) { print "$ref IN POSTGRES, not in Minerva\n"; } }
  else { print "ERROR $ref NOT A CGC or PMID\n"; } }




close (OUT) or die "Cannot close $outfile : $!";
