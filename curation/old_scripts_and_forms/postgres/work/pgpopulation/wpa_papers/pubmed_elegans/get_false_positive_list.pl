#!/usr/bin/perl -w

# get the set of false positives when searching pubmed for ``elegans'' with publication > 2002-07-01
# by comparing to our set of wpa_identifiers as true positives.  2009 01 26

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pm;
my $highest = 0;

my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
while (my @row = $result->fetchrow) {
  my ($pmid) = $row[1] =~ m/pmid *(\d+)/;
  unless ($pmid) { print "BAD @row\n"; }
  if ($pmid > $highest) { $highest = $pmid; }
  $pm{$pmid}++;
} # while (@row = $result->fetchrow)

my $count = 0;
my $infile = 'pmid_elegans_20020701-20090126';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my ($pmid) = $line =~ m/PMID: (\d+)/;
  if ($pmid < 12091304) { print "too early : $pmid\n"; next; }
  if ($pmid > $highest) { print "too recent : $pmid\n"; next; }
  unless ($pm{$pmid}) { print "false positive : $pmid\n"; $count++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

print "There are $count false positive\n";

__END__

