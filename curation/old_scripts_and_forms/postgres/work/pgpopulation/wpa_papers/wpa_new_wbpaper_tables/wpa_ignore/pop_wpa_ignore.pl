#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %functional;
my $result = $conn->exec( "SELECT * FROM cur_comment WHERE cur_comment ~ 'unctional';");
while (my @row = $result->fetchrow) {
  $functional{$row[0]}++;
} # while (@row = $result->fetchrow)

foreach my $paper (sort keys %functional) {
  $result = $conn->exec( "INSERT INTO wpa_ignore VALUES ('$paper', 'functional annotation only', NULL, 'valid', 'two567');" );
} # foreach my $paper (sort keys %functional) 

__END__

