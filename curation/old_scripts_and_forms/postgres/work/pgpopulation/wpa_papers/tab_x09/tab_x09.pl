#!/usr/bin/perl -w

# THIS DOESN'T WORK
# the things it prints out work if copy-pasted, but not if executed through
# Pg.pm  this turned out to not be the problem, so I left it be in the DB.
# 2007 08 31

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE wpa_evidence ~ '\x09';" );
while (my @row = $result->fetchrow) {
    my $old_val = $row[2];
    my $new_val = $old_val;
    $new_val =~ s/\\x09/	/g;
    $old_val =~ s/	/\\x09/g;
    my $command = "UPDATE wpa_gene SET wpa_evidence = '$new_val' WHERE wpa_evidence = '$old_val'";
    print "$command\n";
    my $result2 = $conn->exec( $command );
} # while (@row = $result->fetchrow)

__END__

  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
