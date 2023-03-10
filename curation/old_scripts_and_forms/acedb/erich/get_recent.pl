#!/usr/bin/perl -w

# sample PG query

use strict;
use warnings;
use Pg;

if (! $ARGV[0]) { 
    die "Format: ./get_recent_v03.pl ",
        "[query term, e.g., ",
        "'cur_genefunction' or 'cur_overexpression']\n",
        ;
}

my $query_term = $ARGV[0];
my $conn = Pg::connectdb("dbname=testdb");

if (! PGRES_CONNECTION_OK eq $conn->status) { 
    die $conn->errorMessage;
}

my $query_string = "SELECT * "  
                   . "FROM $query_term "
                   . "WHERE $query_term "
                   . "IS NOT NULL "
                   . "AND cur_timestamp > '2003-05-31' "
                   . "AND cur_timestamp < '2007-06-02' ;"
                   ;

my $result = $conn->exec( $query_string );

while (my @row = $result->fetchrow) {
    if ($row[0]) { 
        $row[0] =~ s///g;
        $row[1] =~ s///g;
        $row[1] =~ s/\n/ /g;
        $row[2] =~ s///g;
        print "$row[0]\t$row[1]\t$row[2]\n";
    }
} 


