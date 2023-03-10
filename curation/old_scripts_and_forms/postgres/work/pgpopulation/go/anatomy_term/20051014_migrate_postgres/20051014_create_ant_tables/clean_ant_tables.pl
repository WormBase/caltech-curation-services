#!/usr/bin/perl -w

# Clean up ant tables from non-anatomy term data.  2005 10 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %anat;
my $result = $conn->exec( "SELECT * FROM ant_anatomy_term WHERE ant_anatomy_term IS NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $anat{$row[0]}++; } }

my @PGparameters = qw(curator anatomy_term);
my @PGsubparameters = qw( goterm goid paper_evidence person_evidence goinference
                          goinference_two aoinference comment qualifier
			  qualifier_two similarity with with_two );

$anat{'abcd'}++;
$anat{'1'}++;
$anat{'asdf'}++;

foreach my $joinkey (sort keys %anat) {
  foreach my $type (@PGparameters) {
    my $table = "ant_" . $type;
    my $pgcommand = "DELETE FROM $table WHERE joinkey = '$joinkey'; ";
    my $result = $conn->exec( " $pgcommand ");
    print "$pgcommand\n";
  } # foreach my $type (@PGparameters)

  my @subtypes = qw( bio_ cell_ mol_ );
  foreach my $subt ( @subtypes ) {
    foreach my $type (@PGsubparameters) {
      my $type = $subt . $type;
      my $table = "ant_" . $type;
      my $pgcommand = "DELETE FROM $table WHERE joinkey = '$joinkey'; ";
      my $result = $conn->exec( " $pgcommand ");
      print "$pgcommand\n";
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)
} # foreach my $joinkey (sort keys %anat)

