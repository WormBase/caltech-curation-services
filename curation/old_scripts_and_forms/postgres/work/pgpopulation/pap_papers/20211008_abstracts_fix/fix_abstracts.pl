#!/usr/bin/perl -w

# Some abstracts don't have data and need to be removed, while others need data added to them based on the identifier.  2021 10 08

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %type;
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '3'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $type{$row[0]}++; }
} # while (@row = $result->fetchrow)

my %abst; my %title; my %identifier; my %author;

# $result = $dbh->prepare( "SELECT * FROM pap_abstract WHERE pap_abstract IS NOT NULL;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { if ($row[0]) { $abst{$row[0]}++; } } 

# $result = $dbh->prepare( "SELECT * FROM pap_title WHERE pap_title IS NOT NULL;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { if ($row[0]) { $title{$row[0]}++; } } 

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier IS NOT NULL;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $identifier{$row[0]} = $row[1]; } } 

# $result = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_author IS NOT NULL;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { if ($row[0]) { $author{$row[0]}++; } } 


my %types;
my %years;
foreach my $joinkey (sort keys %type) {
  if ($identifier{$joinkey}) {
    my $ident = $identifier{$joinkey};
    next if ($ident =~ m/^cgc/);
    next if ($ident =~ m/^wbg/);
    next if ($ident =~ m/^pmid/);
    next if ($ident =~ m/^doi/);
    next if ($ident =~ m/^000/);
    next if ($ident eq 'euwm96');	# manual fix afterward
    next if ($ident eq 'genomed2');	# manual fix afterward
    next if ($ident eq 'evowm2010_ab');	# already have journal and year, but no pages
    next if ($ident eq 'devgenewm2010_ab');	# already have journal and year, but no pages
    my ($type, $year, $string, $page) = $ident =~ m/^([a-zA-Z]+)(\d+)(ab[s]?|p|_ab|aging|neuro)(.+)$/;
    if ($year < 50) { $year = '20' . $year; }
      elsif ($year < 100) { $year = '19' . $year; }
    print qq($joinkey\t$identifier{$joinkey}\t$type\t$year\t$page\n);
    $types{$type}++;
    $years{$year}++;
    unless ($type) { print qq(ERROR $ident does not match type\n); }
    unless ($year) { print qq(ERROR $ident does not match year\n); }
    unless ($page) { print qq(ERROR $ident does not match page\n); }
  }
}

print qq(TYPES\n);
foreach my $type (sort keys %types) {
  print qq($type\n); }

print qq(YEARS\n);
foreach my $year (sort keys %years) {
  print qq($year\n); }

# my %noabs;
# my $noabs_out = '';
# foreach my $joinkey (sort keys %type) {
#   unless ($abst{$joinkey} || $title{$joinkey} || $identifier{$joinkey} || $author{$joinkey}) {
#     $noabs_out .= qq($joinkey does not have an abstract, identifier\n);
#     $noabs{$joinkey}++;
#   }
# } # foreach my $joinkey (sort keys %type)
# 
# my $meet_count = scalar(keys %type);
# my $noabs_count = scalar(keys %noabs);
# print qq($noabs_count without abstract\n);
# print qq($meet_count meetings\n);
# print qq($noabs_out\n);


