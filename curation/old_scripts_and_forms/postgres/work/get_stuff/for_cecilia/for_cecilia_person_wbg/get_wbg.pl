#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_cecilia_person_wbg/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";


foreach my $wbg (@wbg) {
  my $result = $conn->exec( "SELECT joinkey, wbg_lastname FROM wbg_lastname WHERE joinkey = '$wbg';");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      print OUT "$row[0]\t$row[1]\t";
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT joinkey, wbg_email FROM wbg_email WHERE joinkey = '$wbg';");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      print OUT "$row[1]\n";
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
} # foreach my $wbg (@wbg)

close (OUT) or die "Cannot close $outfile : $!";
