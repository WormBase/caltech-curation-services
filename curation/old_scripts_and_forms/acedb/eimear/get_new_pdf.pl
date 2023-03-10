#!/usr/bin/perl -w
#
# Find the pmids and get their reference info

use strict;
use diagnostics;
use Pg;

###GLOBALS
my $dateShort = "";                             # current date
my $i = 0;
my $j = 0;
my $o;
my $print;
my %Papers;
#my @fields = qw(title author journal volume pages year abstract genes);

###MAIN

print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";


my $outfile = "all_pdfs";
my @tmp = $conn->exec( "SELECT * FROM ref_pdf;");
for (@tmp){
    my @row = ();
    while (@row = $_->fetchrow) {
	if ($row[0]) {
	    $i++;
	    $row[0] =~ s///g;
	    $row[0] =~ s/\s+//g;
	    $o = $row[0];
	    $print .= "$o\n";
	} # if ($row[0])
    } # while (@row = $result->fetchrow)
}

open(OUT, ">$outfile") || die "Can't open $outfile: $!";
print OUT "$print";
close(OUT);
print "\n\nThere are $i papers;";

