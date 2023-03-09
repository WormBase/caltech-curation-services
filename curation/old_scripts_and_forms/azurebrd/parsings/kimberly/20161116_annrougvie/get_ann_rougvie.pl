#!/usr/bin/perl -w

# get some paper stats for Ann Rougvie

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my %paps;
my @primary = qw( primary not_primary );
foreach my $year (2011 .. 2016) {
  foreach my $primaryness (@primary) {
    $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid' AND joinkey IN (SELECT joinkey FROM pap_year WHERE pap_year = '$year') AND joinkey IN (SELECT joinkey FROM pap_primary_data WHERE pap_primary_data = '$primaryness') AND joinkey NOT IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $paps{$year}{$primaryness}{$row[0]}++; }
  }
}

foreach my $year (sort keys %paps) {
  foreach my $primaryness (sort keys %{ $paps{$year} }) {
    my $paps = join", ", sort keys %{ $paps{$year}{$primaryness} };
    my $count = scalar keys %{ $paps{$year}{$primaryness} };
    print qq($year has $count $primaryness papers : $paps\n);
  }
} # foreach my $year (sort kyes %paps)
