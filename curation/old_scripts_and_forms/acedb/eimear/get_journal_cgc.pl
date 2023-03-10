#!/usr/bin/perl -w
#
# get list of journals that are cgcs.  2003 03 25

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&getXref();

sub getXref {
      my $result2 = $conn->exec( "SELECT * FROM ref_journal WHERE joinkey ~ 'cgc';");
      while (my @row2 = $result2->fetchrow) {
        if ($row2[1]) { print "$row2[0]\t$row2[1]\n"; }
      }
} # sub getXref

