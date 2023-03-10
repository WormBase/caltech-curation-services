#!/usr/bin/perl -w

# query for papers in svm that don't have nnc

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %svm;
my %nnc;
$result = $dbh->prepare( "SELECT * FROM cur_nncdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $nnc{$row[0]}++; } }
$result = $dbh->prepare( "SELECT * FROM cur_svmdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $svm{$row[0]}++; } }

foreach my $paper (sort keys %svm) {
  unless ($nnc{$paper}) { print qq($paper\n); }
} # foreach my $paper (sort keys %svm)

__END__

