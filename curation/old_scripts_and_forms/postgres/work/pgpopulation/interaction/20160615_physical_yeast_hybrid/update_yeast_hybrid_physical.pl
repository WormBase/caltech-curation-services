#!/usr/bin/perl -w

# update y1h and y2h physical to explicit new types.  for Chris  2016 06 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pgids;
$result = $dbh->prepare( "SELECT * FROM int_detectionmethod WHERE int_detectionmethod = '\"Yeast_one_hybrid\"' AND joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgids{'ProteinDNA'}{$row[0]}++; }
$result = $dbh->prepare( "SELECT * FROM int_detectionmethod WHERE int_detectionmethod = '\"Yeast_two_hybrid\"' AND joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgids{'ProteinProtein'}{$row[0]}++; }

my @pgcommands;
foreach my $type (sort keys %pgids) {
  foreach my $pgid (sort keys %{ $pgids{$type} }) {
    push @pgcommands, qq(DELETE FROM int_type WHERE joinkey = '$pgid';);
    push @pgcommands, qq(INSERT INTO int_type VALUES ('$pgid', '$type'););
    push @pgcommands, qq(INSERT INTO int_type_hst VALUES ('$pgid', '$type'););
  } # foreach my $pgid (sort keys %{ $pgids{$type} })
} # foreach my $type (sort keys %pgids)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
