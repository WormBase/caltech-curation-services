#!/usr/bin/perl -w

# check which one entries merge ace entries (and will need to make sure i don't
# break stuff dealing with it)

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %filter;
my $result = $conn->exec( "SELECT * FROM two_email;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $filter{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

print "There are " . scalar(keys %filter) . " people with emails\n"; 
