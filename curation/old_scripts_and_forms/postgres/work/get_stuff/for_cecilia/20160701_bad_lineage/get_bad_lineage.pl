#!/usr/bin/perl -w

# get bad lineage with same connection in both directions.  2016 07 01

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;
my @roles = qw( Assistant_professor     Highschool              Sabbatical              Phd                     Lab_visitor             Research_staff          Masters                 Unknown                 Undergrad               Collaborated            Postdoc                 );
foreach my $role (@roles) {
  $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_role = '$role' AND two_number ~ 'two' AND joinkey ~ 'two'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $data{$role}{$row[0]}{$row[3]}{forward}++; }
  $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_role = 'with$role' AND two_number ~ 'two' AND joinkey ~ 'two'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $data{$role}{$row[0]}{$row[3]}{back}++; }
}

foreach my $role (sort keys %data) {
  foreach my $one (sort keys %{ $data{$role} }) {
    foreach my $two (sort keys %{ $data{$role}{$one} }) {
      if ( ($data{$role}{$one}{$two}{'forward'}) && ($data{$role}{$one}{$two}{'back'} ) ) { print qq($role\t$one\t$two\n); }
    } # foreach my $two (sort keys %{ $data{$role}{$one} })
  } # foreach my $one (sort keys %{ $data{$role} })
} # foreach my $role (sort keys %data)

