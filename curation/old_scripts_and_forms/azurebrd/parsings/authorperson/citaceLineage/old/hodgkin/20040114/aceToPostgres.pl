#!/usr/bin/perl

# Take the .ace file created by person_name.pl and create a postgres dump to
# read in with COPY two_lineage FROM '/path_to/file';
# Used to enter Hodgkin data.  2004 01 14

use strict;
use Pg;
use diagnostics;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %name;

my $result = $conn->exec( "SELECT * FROM two_standardname;" );
while (my @row = $result->fetchrow) { 
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    $row[0] =~ s/two//g;
    $name{$row[0]} = $row[2];
} }

$/ = "";
my $infile = "lablin.ace";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  (my $supervisor) = $_ =~ m/Person\tWBPerson(\d+)/;
  (my @supervised) = $_ =~ m/Supervised\tWBPerson(\d+)/g;
  foreach my $supee (@supervised) {
    print "two$supervisor\t$name{$supervisor}\t$name{$supee}\ttwo$supee\tUnknown\t\\N\t\\N\tJonathan Hodgkin\t2004-01-14 16:34:00\n";
    print "two$supee\t$name{$supee}\t$name{$supervisor}\ttwo$supervisor\twithUnknown\t\\N\t\\N\tJonathan Hodgkin\t2004-01-14 16:34:00\n";
  } # foreach my $supee (@supervised)

# 533  Ann Rose        Terrance Snutch two604  Unknown \N      \N      Jonathan Hodgkin        2003-10-27 15:09:15.122412-08

}
close (IN) or die "Cannot close $infile : $!";

# my $result = $conn->exec( "SELECT joinkey FROM ref_year WHERE ref_year > '2000';" );
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $all_papers{$row[0]}++;			# add entry to all papers
# } }
