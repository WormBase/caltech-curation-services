#!/usr/bin/perl -w
#
# Fix two table by adding values from two_lastname  2002 02 07

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my %two; my %lastname;

my $result = $conn->exec( "SELECT joinkey FROM two;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $two{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT joinkey FROM two_lastname;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $lastname{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach $_ ( sort keys %lastname ) {
  unless ($two{$_}) { 
    my $val = $_;
    $val =~ s/two//g;
    my $result = $conn->exec( "INSERT INTO two VALUES ('$_', '$val'); ");
    print "\$result = \$conn->exec( \"INSERT INTO two VALUES ('$_', '$val'); \");\n";
  } # unless ($two{$_})
} # foreach $_ ( sort keys %pmid )


