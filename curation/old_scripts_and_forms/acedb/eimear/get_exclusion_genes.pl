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

    my $outfile = "exclusion_genes.out";
    open(OUT, ">$outfile") || die "Can't open $outfile: $!";
    my $type = 'cur_curator';
    my $result = $conn->exec( "SELECT * FROM ref_cgcgenedeletion;");
    my $out = '';
    while (my @row = $result->fetchrow) {
	print OUT "$row[0]\t$row[1]\n";
    } # foreach my $field (@fields)
    close(OUT);
} # sub getRef


