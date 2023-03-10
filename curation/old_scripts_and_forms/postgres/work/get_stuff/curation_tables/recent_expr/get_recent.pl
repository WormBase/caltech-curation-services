#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/recent_expr/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";

my $result = $conn->exec( "SELECT cur_expression.joinkey, cur_expression.cur_expression, cur_expression.cur_timestamp FROM cur_expression WHERE cur_expression.cur_expression IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print OUT "EXPRESSION PATTERN\t$row[0]\t$row[1]\t$row[2]\n\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

close (OUT) or die "Cannot close $outfile : $!";
