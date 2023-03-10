#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

for (my $two = 0; $two < 1810; $two++) { 
  my $last = '';
  my $first = '';
  my @groups = ();
  my $joinkey = 'two' . $two;
  my $result = $conn->exec( "SELECT two_lastname FROM two_lastname WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow;
  if ($row[0]) { $last = $row[0]; }

  $result = $conn->exec( "SELECT two_firstname FROM two_firstname WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow;
  if ($row[0]) { $first = $row[0]; }

  $result = $conn->exec( "SELECT two_groups FROM two_groups WHERE joinkey = '$joinkey';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { push @groups, $row[0]; }
  }

  my $groups = join"\t", @groups;
  print OUT "$joinkey\t$first\t$last\t$groups\n";
 
} # for my $two ($two = 0; $two < 1810; $two++) 


print OUT "\n\nDIVIDER\n\n";

close (OUT) or die "Cannot close $outfile : $!";
