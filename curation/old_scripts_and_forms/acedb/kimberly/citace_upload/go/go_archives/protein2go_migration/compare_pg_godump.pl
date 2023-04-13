#!/usr/bin/perl -w

# compare pg pgids with latest go dump pgids.  2013 02 08

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %go;
my $infile = 'phenote_go_withcurator.go.latest';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/^WB/) {
    my @line = split/\t/, $line;
    my $pgid = pop @line;
    $go{$pgid}++; } }
close (IN) or die "Cannot close $infile : $!";

my $result = $dbh->prepare( "SELECT * FROM gop_curator ORDER BY joinkey::INTEGER" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($go{$row[0]}) { delete $go{$row[0]}; }
      else { print "$row[0] in gop_curator, not in go dump\n"; } } 
} # while (@row = $result->fetchrow)

foreach my $pgid (sort {$a<=>$b} keys %go) {
  print "$pgid in go dump, not in gop_curator\n";
} # foreach my $pgid (sort {$a<=>$b} keys %go)

