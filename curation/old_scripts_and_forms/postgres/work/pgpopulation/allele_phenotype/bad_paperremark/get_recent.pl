#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM alp_remark;" );
while (my @row = $result->fetchrow) {
  if ($row[2]) { 
    my (@chars) = split//, $row[2];
    my $length = scalar(@chars);
#     print "L $length D $row[2] J $row[0] B $row[1] T $row[3] E\n"; 
    if ($length > 9999) { print "BAD L $length J $row[0] B $row[1] T $row[3] D $row[2]E\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

