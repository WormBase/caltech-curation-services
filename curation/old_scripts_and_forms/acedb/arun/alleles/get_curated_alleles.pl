#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $outfile = "curated_alleles.txt";

print "Getting allele data from postgres DB...\n";
my $result = $dbh->prepare( "SELECT * FROM obo_data_app_tempname " .
                            "WHERE obo_data_app_tempname ~ 'allele' AND " . 
                                  "obo_data_app_tempname ~ 'WBGene'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";

my %alleles;
while (my @row = $result->fetchrow) {
	if ( $row[1] =~ /name\:\s*\"(.+?)\"/ ) {
		$alleles{$1} = 1;
	} else {
		print "Possibly bogus entry in postgres?\n";
		print "$row[1]\n";
	}
}

open (OUT, ">$outfile") or die $!;
for my $allele (sort keys %alleles) {
	print OUT "$allele\n";
} 

print "Output stored in $outfile\n";
