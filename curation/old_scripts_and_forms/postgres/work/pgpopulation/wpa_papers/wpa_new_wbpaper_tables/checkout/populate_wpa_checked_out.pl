#!/usr/bin/perl -w

# Quick PG query to get some data.  Template sample.  2004 04 19

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %wbPaper;
my $result = $conn->exec( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp ;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wbPaper{$row[1]} = $row[0]; }
    else { delete $wbPaper{$row[1]}; }
} # while (my @row = $result->fetchrow) 

$result = $conn->exec( "SELECT * FROM ref_checked_out ;" );
while (my @row = $result->fetchrow) {
  my $unconverted = ''; my $who = ''; my $timestamp = '';
  if ($row[0]) { $unconverted = $row[0]; }
  if ($row[1]) { 
    if ($row[1] =~ m/Andrei/) { $who = 'two480'; }
    elsif ($row[1] =~ m/Raymond/) { $who = 'two363'; }
    elsif ($row[1] =~ m/Erich/) { $who = 'two567'; }
    elsif ($row[1] =~ m/Ranjana/) { $who = 'two324'; }
    elsif ($row[1] =~ m/Sternberg/) { $who = 'two625'; }
    elsif ($row[1] =~ m/Wen/) { $who = 'two101'; }
    elsif ($row[1] =~ m/Carol/) { $who = 'two48'; }
    elsif ($row[1] =~ m/Kimberly/) { $who = 'two1843'; }
    elsif ($row[1] =~ m/Igor/) { $who = 'two22'; }
    else { 1; } }
  if ($row[2]) { $timestamp = $row[2]; }
  my $two_number = '0';
  unless ($wbPaper{$unconverted}) { 
    if ($row[1]) { print "ERROR $row[0] has no convertion\n"; }
    next; }			# skip if no wbpaper for that cgc / pmid
  unless ($who) { next; }	# skip if no curator
  my $pg_command = "INSERT INTO wpa_checked_out VALUES ('$wbPaper{$unconverted}', '$who', NULL, 'valid', '$who', '$timestamp'); ";
  my $result2 = $conn->exec( "$pg_command" );
  print OUT "$pg_command\n";
}




close (OUT) or die "Cannot close $outfile : $!";
