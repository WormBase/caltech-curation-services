#!/usr/bin/perl -w

# compare genes that have an entry in pap_gene after the date in con_lastupdate, get each paper's person to get the PI, sort by PIs.


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %locus; 
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $locus{$row[0]} = $row[1]; }

my %name; 
$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $name{$row[0]} = $row[2]; }

my %pis; 
$result = $dbh->prepare( "SELECT * FROM two_pis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pis{$row[0]}++; }

my %curDate;
$result = $dbh->prepare( "SELECT con_wbgene.con_wbgene, con_lastupdate.con_lastupdate FROM con_wbgene, con_lastupdate WHERE con_wbgene.joinkey = con_lastupdate.joinkey ORDER BY con_lastupdate;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my $gene = $row[0]; $gene =~ s/WBGene//; $curDate{$gene} = $row[1]; }

my $geneCurDateCount = scalar keys %curDate;
print STDERR "CURDATE count $geneCurDateCount\n";

my $geneCount = 0;
my %publishedAfter;
foreach my $gene (sort keys %curDate) {
  $geneCount++; if ($geneCount % 5000 == 0) { my $date = &getPgDate(); print STDERR qq(at $geneCount -- $date\n); }
# this takes a really long time.  use below to try a smaller set
#   last if ($geneCount > 1000);
  my $curDate = $curDate{$gene};
  $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_gene = '$gene' AND pap_timestamp > '$curDate';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    $publishedAfter{$row[1]}{$row[0]}++;
  }
} # foreach my $gene (sort keys %gene)

print STDERR "PUBAFTER \n";

my $paps = join"','", sort keys %publishedAfter;
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

my %pisPapers;
$result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id IN ('$aids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $aid = $row[0]; my $two = $row[1]; my $join = $row[2];
    if ($ver{$aid}{$join}) { 
      my $pap = $aidToPap{$aid};
      if ($pis{$two}) {
        $pisPapers{$two}{$pap}++; } } } }

my %sort;
foreach my $two (keys %pisPapers) {
  my $paps  = join", ", sort keys %{ $pisPapers{$two} };
  my $count = scalar keys %{ $pisPapers{$two} };
  my $line  = qq($two\t$count\t$name{$two}\t$paps\n);
  $sort{$count}{$line}++; 
} # foreach my $two (sort { $pisPapers{$b} <=> $pisPapers{$a} } keys %pisPapers)

# print PIs and their published papers that have a gene that needs updating, sorted by count
foreach my $count (sort {$b<=>$a} keys %sort) {
  foreach my $line (sort keys %{ $sort{$count} }) {
    print qq($line); } }


# to show mapping of genes to count of papers
# foreach my $gene (sort keys %publishedAfter) {
#   my $locus = $locus{$gene} || '';
#   my $paps  = join", ", sort keys %{ $publishedAfter{$gene} };
#   my $count = scalar keys %{ $publishedAfter{$gene} };
#   print qq($gene\t$locus\t\t$count\t$paps\n);
# } # foreach my $gene (sort keys %publishedAfter)

__END__

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


