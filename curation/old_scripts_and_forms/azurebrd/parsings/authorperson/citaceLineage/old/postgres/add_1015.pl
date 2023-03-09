#!/usr/bin/perl -w
#
# Add to two_lineage data uploaded on 2003_10_15 both trained and trained_with.
# This file generates Connections, but have to manually replace the sender from
# the form-generated .ace file person_lineage_20031015.ace   Then have to 
# copy-paste the 82 entries.  2003 10 24

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT * FROM two_standardname;" );
while (my @row = $result->fetchrow) {
  $row[0] =~ s/two//;
  $hash{$row[0]} = $row[2];
} # while (my @row = $result->fetchrow)

$/ = "";
my $infile = 'New_Person_Lineage_20031015.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my ($main) = $entry =~ m/Person\tWBPerson(\d+)/;
  my (@others) = $entry =~ m/Supervised_by\tWBPerson(\d+)\t(\w+)/g;
  my %others = @others;
  foreach my $key (sort keys %others) {
    print "INSERT INTO two_lineage VALUES ('two$main', '$hash{$key}', 'two$key', 'with$others{$key}', NULL, NULL, 'replaceme', '2003-10-15'); \n";
    print "INSERT INTO two_lineage VALUES ('two$key', '$hash{$main}', 'two$main', '$others{$key}', NULL, NULL, 'replaceme', '2003-10-15'); \n";
#     $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two$main', '$hash{$key}', 'two$key', 'with$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21');" );
#     $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two$key', '$hash{$key}', 'two$main', '$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21')" );
#     print "MAIN $main BY $key ROLE by_$others{$key}\n";
#     print "BACK $key TRAINED $main ROLE $others{$key}\n";
  } # foreach my $key (sort keys %others)
  my (@collab) = $entry =~ m/Worked_with\tWBPerson(\d+)\t(\w+)/g;
  my %collab = @collab;
  foreach my $key (sort keys %collab) {
    print "INSERT INTO two_lineage VALUES ('two$main', '$hash{$key}', 'two$key', '$collab{$key}', NULL, NULL, 'replaceme', '2003-10-15'); \n";
    print "INSERT INTO two_lineage VALUES ('two$key', '$hash{$main}', 'two$main', '$collab{$key}', NULL, NULL, 'replaceme', '2003-10-15'); \n";
  } # foreach my $key (sort keys %collab)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

