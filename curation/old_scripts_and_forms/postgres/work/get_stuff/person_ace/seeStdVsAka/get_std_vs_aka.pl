#!/usr/bin/perl -w

# get list of standard names with same Aka  2003 06 09

use strict;
use diagnostics;
# use Pg;
use Jex;

# my $infile = '/home/postgres/work/get_stuff/person_ace/compare_citace_vs_pg_dump/20030528/Juancarlos_20030528.ace';
my $infile = 'Juancarlos_20030613';

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$/ = '';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ($_ =~ m/(Person : \"WBPerson.*?\")/) {
    my $person = $1;
    my ($standard_name) = $_ =~ m/Standard_name\t \"(.*?)\"/;
    unless ($standard_name) { $standard_name = ''; }
    my (@akas) = $_ =~ m/Also_known_as\t \"(.*?)\"/;
    foreach my $aka (@akas) {
      if ($standard_name eq $aka) { print "$person\t$aka\n"; }
    } # foreach my $aka (@akas)
  } else { print STDERR "Error $_ has no person\n"; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

# Person : "WBPerson2"
# First_name       "Eric"
# Middle_name      "James"
# Last_name        "Aamodt"
# Standard_name    "Eric Aamodt"
# Full_name        "Eric James Aamodt"
# Also_known_as    "Eric Aamodt"
# Also_known_as    "EJ Aamodt"
# Also_known_as    "E Aamodt"

