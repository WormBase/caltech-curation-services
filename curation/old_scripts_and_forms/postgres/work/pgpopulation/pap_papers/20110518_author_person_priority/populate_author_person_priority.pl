#!/usr/bin/perl -w

# populate pap_curation_flags with 'author_person' for all valid papers that are not 'functional_annotation'  2011 05 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @pgcommands;

my %highest_order;
my $result = $dbh->prepare( "SELECT * FROM pap_curation_flags ORDER BY pap_order::INTEGER;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $highest_order{$row[0]} = $row[2]; }

$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid' AND joinkey NOT IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'functional_annotation') AND joinkey != '00000001'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pap_order = 1;
  if ($highest_order{$row[0]}) { $pap_order = $highest_order{$row[0]} + 1; }
  push @pgcommands, "INSERT INTO pap_curation_flags VALUES ('$row[0]', 'author_person', $pap_order, '$row[3]', '$row[4]')";
  push @pgcommands, "INSERT INTO h_pap_curation_flags VALUES ('$row[0]', 'author_person', $pap_order, '$row[3]', '$row[4]')";
} # while (@row = $result->fetchrow)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)
