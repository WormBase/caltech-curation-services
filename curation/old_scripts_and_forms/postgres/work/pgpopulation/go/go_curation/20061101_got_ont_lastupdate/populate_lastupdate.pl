#!/usr/bin/perl -w

# find the latest date used in a column for each ontology, then populate the
# got_{ontology}_lastupdate box.  2006 11 01


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @PGparameters = qw(locus sequence synonym protein wbgene);
my @ontology = qw( bio cell mol );
# my @column_types = qw( goterm goid paper_evidence person_evidence curator_evidence goinference dbtype with qualifier goinference_two dbtype_two with_two qualifier_two comment );
my @column_types = qw( goterm goid paper_evidence person_evidence goinference dbtype with qualifier goinference_two dbtype_two with_two qualifier_two comment );		# ignore curator evidence because it was added later  2006 11 14

my %hash;

foreach my $ontology (@ontology) {                    # loop through each of three ontology types
  foreach my $column_type (@column_types) {
    my $table = 'got_' . $ontology . '_' . $column_type;
    my $result = $conn->exec( "SELECT * FROM $table ORDER BY joinkey, got_timestamp;" );
    while (my @row = $result->fetchrow) { 
      if ($hash{$ontology}{$row[0]}{$row[1]}) { 
          my $old_time = $hash{$ontology}{$row[0]}{$row[1]};
          $old_time =~ s/\D//g; ($old_time) = $old_time =~ m/^(\d{14})/;
          my $cur_time = $row[3];
          $cur_time =~ s/\D//g; ($cur_time) = $cur_time =~ m/^(\d{14})/;
          if ($cur_time > $old_time) { $hash{$ontology}{$row[0]}{$row[1]} = $row[3]; } }
        else { $hash{$ontology}{$row[0]}{$row[1]} = $row[3]; }
    } # while (my @row = $result->fetchrow) 
} }

foreach my $ontology (@ontology) {                    # loop through each of three ontology types
  foreach my $joinkey (sort keys %{ $hash{$ontology} } ) {
    foreach my $order (sort keys %{ $hash{$ontology}{$joinkey} } ) {
      my $table = 'got_' . $ontology . '_lastupdate';
      my ($time) = $hash{$ontology}{$joinkey}{$order} =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
      my $command = "INSERT INTO $table VALUES ('$joinkey', $order, '$time', '$hash{$ontology}{$joinkey}{$order}');";
      print "$command\n";
      my $result2 = $conn->exec( $command );
#       print "O $ontology J $joinkey O $order V $hash{$ontology}{$joinkey}{$order} END\n";
} } }

