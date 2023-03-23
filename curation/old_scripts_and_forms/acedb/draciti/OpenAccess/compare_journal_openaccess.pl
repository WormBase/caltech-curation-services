#!/usr/bin/perl -w

# compare list of postgres journals to open access journals
# 2014 12 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %open;
my $infile = 'open_access_archives.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/^\"//; $line =~ s/\"$//;
  my (@row) = split/","/, $line;
  $open{$row[0]}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my %journal;
$result = $dbh->prepare( "SELECT DISTINCT(pap_journal) FROM pap_journal ORDER BY pap_journal;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($open{$row[0]}) { print "$row[0]\n"; } } }

