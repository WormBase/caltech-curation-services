#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $outfile = "gold_std_postgres.txt";
open (OUT, ">$outfile") or die "could not open $outfile for writing: $!\n";

my $result = $dbh->prepare( "SELECT * FROM cfp_humdis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
	if ($row[0]) {
		for my $entry (@row) {
			$entry =~ s/\n/ /g;
			print OUT "$entry\t";
		}
		print OUT "\n";
	}
}
close(OUT);

print "Output stored in $outfile\n";
