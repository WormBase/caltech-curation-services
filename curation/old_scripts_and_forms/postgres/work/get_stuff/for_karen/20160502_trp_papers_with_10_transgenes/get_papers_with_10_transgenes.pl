#!/usr/bin/perl -w

# query for papers that have 10 or more transgenes  2016 05 02

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;
$result = $dbh->prepare( "SELECT trp_paper.trp_paper, trp_publicname.trp_publicname FROM trp_publicname, trp_paper WHERE trp_paper.joinkey = trp_publicname.joinkey AND trp_paper.joinkey NOT IN (SELECT joinkey FROM trp_mergedinto) AND trp_paper.joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my (@papers) = $row[0] =~ m/WBPaper(\d+)/g;
    foreach (@papers) { 
      if ($row[1] =~ m/Ex/) { $data{$_}{Ex}{$row[1]}++; }
      $data{$_}{all}{$row[1]}++; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %aid; my %author; my %year;
$result = $dbh->prepare( "SELECT * FROM pap_year" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $year{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM pap_author_index" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $aid{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_order = 1;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { if ($aid{$row[1]}) { $author{$row[0]} = $aid{$row[1]}; } } }

foreach my $paper (sort keys %data) {
  my $tcount = scalar keys %{ $data{$paper}{all} };
  my $excount = scalar keys %{ $data{$paper}{Ex} };
  if ($tcount > 9) {
    my $author = $author{$paper} || '';
    my $year   = $year{$paper}   || '';
    print qq(WBPaper$paper\t$tcount\t$excount\t$year\t$author\n);
  } # if ($tcount > 9)
} # foreach my $paper (sort keys %data)
