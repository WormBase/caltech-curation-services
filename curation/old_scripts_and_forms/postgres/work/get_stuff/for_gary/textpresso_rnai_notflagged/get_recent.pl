#!/usr/bin/perl -w

# take not_flagged papers from textpresso_query_three and see which are not curated, and which are no_curatable
# 2009 02 26

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %notFlagged;

my $infile = 'not_flagged';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { chomp $line; $notFlagged{$line}++; }
close (IN) or die "Cannot close $infile : $!";

my %curated;
my %noCuratable;
my $result = $conn->exec( "SELECT * FROM cur_curator;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $curated{$row[0]}++; } }
$result = $conn->exec( "SELECT * FROM cur_comment WHERE cur_comment ~ 'no curatable';" );
while (my @row = $result->fetchrow) { if ($row[0]) { $noCuratable{$row[0]}++; } }

foreach my $joinkey (sort keys %notFlagged) {
  unless ($curated{$joinkey}) { print "NOT CURATED $joinkey\n"; } }
foreach my $joinkey (sort keys %notFlagged) {
  if ($noCuratable{$joinkey}) { print "NO CURATABLE $joinkey\n"; } }

__END__

