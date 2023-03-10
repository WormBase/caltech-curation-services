#!/usr/bin/perl -w
#
# Quick PG query to get some data for twos with unable to contact that have email
# 2003 09 02

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM two_unable_to_contact WHERE two_unable_to_contact != 'NULL';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $result2 = $conn->exec( "SELECT * FROM two_email WHERE joinkey = '$row[0]';" );
    my @row2 = $result2->fetchrow;
    if ($row2[0]) { print OUT "$row[0]\t$row2[2]\t$row[2]\n"; }
  }
}

close (OUT) or die "Cannot close $outfile : $!";
