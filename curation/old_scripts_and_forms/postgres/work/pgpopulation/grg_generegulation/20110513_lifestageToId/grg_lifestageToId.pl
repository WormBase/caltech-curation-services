#!/usr/bin/perl -w

# update grg_lifestage data from names to IDs.  2011 05 13

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %anatToId;
my %anatIds;

my $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $anatIds{$row[0]}++; $anatToId{$row[1]} = $row[0]; }

my @pgcommands;

$result = $dbh->prepare( "SELECT * FROM grg_lifestage WHERE grg_lifestage IS NOT NULL AND grg_lifestage != ''" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $joinkey; my $data; my $timestamp;
  my %good_data;
  my $old_data = $row[1];
  $old_data =~ s/^\"//; $old_data =~ s/\"$//;
  my @data = split/\",\"/, $old_data;
  foreach my $data (@data) {
    if ($anatIds{$data}) { $good_data{$data}++; }
    elsif ($anatToId{$data}) { $good_data{$anatToId{$data}}++; }
#     else { print "Data $data is not valid in $row[0]\n"; }
  } # foreach my $data (@data)
  $data = join'","', sort keys %good_data; 
  next unless $data;
  $data = '"' . $data . '"';
  if ($data eq $row[1]) { 
#     print "Same $row[0] $row[1]\n"; 
  } else {
    push @pgcommands, "UPDATE grg_lifestage SET grg_lifestage = '$data' WHERE joinkey = '$row[0]'";
    push @pgcommands, "INSERT INTO grg_lifestage_hst VALUES ('$row[0]', '$data')";
#     print "update $row[0] from $row[1] to $data\n";
  }
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

