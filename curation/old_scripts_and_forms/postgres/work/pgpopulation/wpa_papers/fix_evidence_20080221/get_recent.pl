#!/usr/bin/perl -w

# fix evidence that begin with ``Gene''  2008 02 21

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE wpa_evidence ~ '^Gene';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    if ($row[2] =~ m/^(Gene \"[a-z][a-z][a-z]\-\d+\" )/) { 
        my $extra = $row[2]; $extra =~ s/$1//g; 
        my $command = "UPDATE wpa_gene SET wpa_evidence = '$extra' WHERE wpa_evidence = '$row[2]';"; 
        my $result2 = $conn->exec($command);
        print "$command\n"; 
      }
      else { print "odd match @row\n"; }
#     print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

