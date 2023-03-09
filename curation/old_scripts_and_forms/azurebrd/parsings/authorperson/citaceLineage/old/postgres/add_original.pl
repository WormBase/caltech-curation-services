#!/usr/bin/perl -w
#
# Add to two_lineage original data from Andrew Hallman both trained and
# trained_with.  Deleted 3 sternberg entries he said were not his.
# 2003 10 24

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
my $infile = 'Lineage.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my ($main) = $entry =~ m/Person\tWBPerson(\d+)/;
  my (@others) = $entry =~ m/Supervised_by\tWBPerson(\d+)\t(\w+)/g;
  my %others = @others;
  foreach my $key (sort keys %others) {
    print "INSERT INTO two_lineage VALUES ('two$main', '$hash{$key}', 'two$key', 'with$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21'); \n";
    print "INSERT INTO two_lineage VALUES ('two$key', '$hash{$main}', 'two$main', '$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21'); \n";
    $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two$main', '$hash{$key}', 'two$key', 'with$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21');" );
    $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two$key', '$hash{$main}', 'two$main', '$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21')" );
#     print "MAIN $main BY $key ROLE by_$others{$key}\n";
#     print "BACK $key TRAINED $main ROLE $others{$key}\n";
  } # foreach my $key (sort keys %others)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

