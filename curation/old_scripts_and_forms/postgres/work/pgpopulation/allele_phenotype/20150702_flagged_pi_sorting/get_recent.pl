#!/usr/bin/perl -w

# given paper set of flagged for new mutant and not curated
# http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_curator=two1823&listDatatype=newmutant&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on
# get persons associated of them, see which are PIs.  sort on PI by count of papers flagged and not curated.

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %name; 
$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $name{$row[0]} = $row[2]; }

my %pis; 
$result = $dbh->prepare( "SELECT * FROM two_pis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pis{$row[0]}++; }


my %paps;
my $papListFile = 'flaggedPapers';
open (IN, "<$papListFile") or die "Cannot open $papListFile : $!";
while (my $line = <IN>) { chomp $line; $paps{$line}++; }
close (IN) or die "Cannot close $papListFile : $!";

my $paps = join"','", sort keys %paps;
my %aids; my %aidToPap;
$result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey IN ('$paps')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $aids{$row[1]}++; $aidToPap{$row[1]} = $row[0]; } }

my $aids = join"','", sort keys %aids;
my %ver;
$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE author_id IN ('$aids') AND pap_author_verified ~ 'YES'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $ver{$row[0]}{$row[2]}++; } }

my %per;
$result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id IN ('$aids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($ver{$row[0]}{$row[2]}) { $per{$row[1]}{$row[0]}++; } } }

my %pisPapers;
foreach my $two (keys %per) {
  if ($pis{$two}) {
    foreach my $aid (keys %{ $per{$two} }) { 
      my $pap = $aidToPap{$aid};
      $pisPapers{$two}{$pap}++; } } }

my %sort;
foreach my $two (keys %pisPapers) {
  my $paps  = join", ", sort keys %{ $pisPapers{$two} };
  my $count = scalar keys %{ $pisPapers{$two} };
  my $line  = qq($two\t$count\t$name{$two}\t$paps\n);
  $sort{$count}{$line}++; 
} # foreach my $two (sort { $pisPapers{$b} <=> $pisPapers{$a} } keys %pisPapers)

foreach my $count (sort {$b<=>$a} keys %sort) {
  foreach my $line (sort keys %{ $sort{$count} }) {
    print qq($line); } }


