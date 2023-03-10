#!/usr/bin/perl -w

# populate int_nondirectional based on 11 possible int_types.  2010 10 08

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %nonD;

# have checked that type and curator are equal sets
# SELECT * FROM int_curator WHERE joinkey NOT IN (SELECT joinkey FROM int_type);
# SELECT * FROM int_type WHERE joinkey NOT IN (SELECT joinkey FROM int_curator);

my @noeff = qw( Genetic No_interaction Predicted_interaction Physical_interaction Synthetic Mutual_enhancement Mutual_suppression );
my @yeseff = qw( Regulatory Suppression Enhancement Epistasis );
my %intTypes;
foreach my $type (@noeff) { $intTypes{$type} = 'Non_directional'; }
foreach my $type (@yeseff) { $intTypes{$type} = 'blank'; }

my @pgcommands;

my $result = $dbh->prepare( "SELECT * FROM int_type" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($intTypes{$row[1]}) { 
        my $val = $intTypes{$row[1]}; if ($val eq 'blank') { $val = ''; }
        push @pgcommands, "INSERT INTO int_nondirectional VALUES ('$row[0]', '$val', '$row[2]');";
        push @pgcommands, "INSERT INTO int_nondirectional_hst VALUES ('$row[0]', '$val', '$row[2]');"; }
      else { print "ERR bad type @row\n"; } } }


foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT for live run.  2010 10 08
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
