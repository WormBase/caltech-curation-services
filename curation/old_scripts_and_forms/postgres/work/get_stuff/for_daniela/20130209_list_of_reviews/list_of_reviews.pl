#!/usr/bin/perl -w

# for Daniela and Oliver Hobert for WormBook, get list of papers that are reviews, sort by year.  2013 02 11

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %valid;
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

my %reviews;
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '2';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $reviews{$row[0]}++; }

my %pmids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pmids{$row[0]} = $row[1]; }

my %title;
$result = $dbh->prepare( "SELECT * FROM pap_title;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $title{$row[0]} = $row[1]; }

my %journal;
$result = $dbh->prepare( "SELECT * FROM pap_journal;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $journal{$row[0]} = $row[1]; }

my %pages;
$result = $dbh->prepare( "SELECT * FROM pap_pages;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pages{$row[0]} = $row[1]; }

my %year;
$result = $dbh->prepare( "SELECT * FROM pap_year;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $year{$row[0]} = $row[1]; }

my %aids; my %authors;
$result = $dbh->prepare( "SELECT * FROM pap_author;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $aids{$row[0]}{$row[2]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM pap_author_index;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $authors{$row[0]} = $row[1]; }

my %by_year;
foreach my $joinkey (sort keys %reviews) {
  next unless $valid{$joinkey};
  my @authors;
  foreach my $order (sort {$a<=>$b} keys %{ $aids{$joinkey} }) { push @authors, $authors{$aids{$joinkey}{$order}}; }
  my $authors = join", ", @authors;
  push @{ $by_year{$year{$joinkey}} }, "WBPaper$joinkey\t$pmids{$joinkey}\t$authors\t$title{$joinkey}\t$journal{$joinkey}\t$year{$joinkey}\t$pages{$joinkey}\n";
} # foreach my $joinkey (sort keys %reviews)

foreach my $year (sort {$a<=>$b} keys %by_year) {
  foreach my $line (@{ $by_year{$year} }) { print $line; }
} # foreach my $year (sort {$a<=>$b} keys %by_year)
