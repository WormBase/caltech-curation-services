#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT * FROM got_cell_curator_evidence WHERE
got_timestamp > '2007-01-01' ORDER BY got_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    my $key = "$row[0]\t$row[1]";
    $hash{$key} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $count;
foreach my $key (keys %hash) { 
#   next unless $key;
  next unless $hash{$key};
  if ($hash{$key} eq 'Kimberly Van Auken') { $count++; } }
print "There are $count cell component entries for GO curation by Kimberly from 2007-01-01 to now\n"; 

__END__

