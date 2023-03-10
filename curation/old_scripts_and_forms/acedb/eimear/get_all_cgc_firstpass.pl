#!/usr/bin/perl -w
#

use strict;
use diagnostics;
use Pg;

###MAIN


print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";

&getRef();


sub getRef {

    my $outfile = "all_firstpass.out";
    open(OUT, ">$outfile") || die "Can't open $outfile: $!";
    my $type = 'cur_curator';
    my $result = $conn->exec( "SELECT * FROM $type WHERE $type IS NOT NULL;");
    my $out = '';
    while (my @row = $result->fetchrow) {
#	next unless $row[0] =~ /cgc/;
	print OUT "$row[0]\n";
    } # foreach my $field (@fields)
    close(OUT);
} # sub getRef


