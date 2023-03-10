#!/usr/bin/perl -w

# Go through go_curation form tables (except for got_{ontology}_lastupdate which
# hasn't been created yet) and remove redundant tables as well as blank entries
# if all entries are blank.  2006 11 01
#
# TEST THIS BEFORE REUSING IT, KEEPS SOME PROTEIN DATA BUT ACTUALLY DELETES IT
# 2006 11 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @PGparameters = qw(locus sequence synonym protein wbgene);
my @ontology = qw( bio cell mol );
my @column_types = qw( goterm goid paper_evidence person_evidence curator_evidence goinference dbtype with qualifier goinference_two dbtype_two with_two qualifier_two comment );

my %hash;

foreach my $ontology (@ontology) {                    # loop through each of three ontology types
  foreach my $column_type (@column_types) {
    my $table = 'got_' . $ontology . '_' . $column_type;
    my $result = $conn->exec( "SELECT * FROM $table ORDER BY joinkey, got_timestamp;" );
    my $cur_joinkey = '';
    while (my @row = $result->fetchrow) { 
      unless ($cur_joinkey eq $row[0]) { 
        print "Clear Hash, new joinkey $row[0]\n"; %hash = (); $cur_joinkey = $row[0]; }
      unless ($row[2]) { $row[2] = ''; }
      my $cur_value = '';
      if ($hash{$table}{$row[1]}{value}) { $cur_value = $hash{$table}{$row[1]}{value}; }
      if ($row[2] ne $cur_value) {			# this is good and want to keep
        $hash{$table}{$row[1]}{value} = $row[2];
        $hash{$table}{$row[1]}{time} = $row[3];
        print "KEEP @row\n";
      } else {					# the value has not changed, delete it
        my $command = "DELETE FROM $table WHERE joinkey = '$row[0]' AND got_order = '$row[1]' AND got_timestamp = '$row[3]';";
        print "$command\n";
        my $result2 = $conn->exec( $command );
      } 
    } # while (my @row = $result->fetchrow) 
} }

foreach my $table (@PGparameters) {
  my $table = 'got_' . $table;
  my $result = $conn->exec( "SELECT * FROM $table ORDER BY joinkey, got_timestamp;" );
  my $cur_joinkey = '';
  while (my @row = $result->fetchrow) { 
    unless ($cur_joinkey eq $row[0]) { 
      print "Clear Hash, new joinkey $row[0]\n"; %hash = (); $cur_joinkey = $row[0]; }
    unless ($row[1]) { $row[1] = ''; }
    my $cur_value = '';
    if ($hash{$table}{value}) { $cur_value = $hash{$table}{value}; }
    if ($row[1] ne $cur_value) {			# this is good and want to keep
      $hash{$table}{value} = $row[1];
      $hash{$table}{time} = $row[2];
      print "KEEP @row\n";
    } else {					# the value has not changed, delete it
      my $command = "DELETE FROM $table WHERE joinkey = '$row[0]' AND got_timestamp = '$row[2]';";
      print "$command\n";
      my $result2 = $conn->exec( $command );
    } 
  } # while (my @row = $result->fetchrow) 
} # foreach my $table (@PGparameters)

__END__


my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

