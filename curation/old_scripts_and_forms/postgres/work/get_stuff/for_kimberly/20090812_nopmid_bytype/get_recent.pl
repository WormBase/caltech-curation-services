#!/usr/bin/perl -w

# get counts of papers without pmid by paper type.  2009 08 12
#
# get titles of articles for pubmed search.  2009 08 18
#
# do esearch query for titles to look for pmid  2009 09 19

use strict;
use diagnostics;
use DBI;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %wpa;
my $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{valid}{$row[0]}++; }
    else { delete $wpa{valid}{$row[0]}; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM wpa_title ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{title}{$row[0]}{$row[1]}++; }
    else { delete $wpa{title}{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{type}{$row[0]}{$row[1]}++; }
    else { delete $wpa{type}{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{identifier}{$row[0]}{$row[1]}++; }
    else { delete $wpa{identifier}{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)

my %index;
$result = $dbh->prepare( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $index{$row[0]} = $row[1];
} # while (@row = $result->fetchrow)


my %types;
foreach my $joinkey (sort keys %{ $wpa{valid} }) {
  next if ($wpa{identifier}{$joinkey}) ;
  foreach my $type (keys %{ $wpa{type}{$joinkey} }) {
    $types{$type}{count}++;
    $types{$type}{$joinkey}++;
  }
} # foreach my $joinkey (sort keys %{ $wpa{valid} })

my $count = 0;
foreach my $type (sort keys %types) {
  print "$index{$type}\t$types{$type}{count}\n";
#   if ($index{$type} eq 'ARTICLE') 				# show titles of articles for pubmed search
  if ($index{$type} eq 'REVIEW') {				# show titles of reviews for pubmed search
    foreach my $joinkey (keys %{ $types{$type} }) {
      next if ($joinkey eq 'count');
      my ($title, @junk) = keys %{ $wpa{title}{$joinkey} };
      unless ($title) { print "ERR no title $joinkey\n"; next; }
      my ($pmids) = &getPmids($title);
      unless ($pmids) { $pmids = "no match"; }
      $count++;
      print "$joinkey\t$title\t$pmids\n";
#       last if ($count > 3);
    } # foreach my $joinkey (keys %{ $types{$type} })
  }
} # foreach my $type (sort keys %types)

sub getPmids {
  my $title = shift;
  $title =~ s/ /+/g;
  my $page = get "http:\/\/eutils.ncbi.nlm.nih.gov\/entrez\/eutils\/esearch.fcgi?db=pubmed&field=titl&term=$title";
  sleep(5);
  my ($idList) = $page =~ m/<IdList>(.*?)<\/IdList>/s;
  if ($idList) { my (@ids) = $idList=~m/<Id>(.*?)<\/Id>/g; my $ids = join", ", @ids; return $ids; }
    else { return; }
}
