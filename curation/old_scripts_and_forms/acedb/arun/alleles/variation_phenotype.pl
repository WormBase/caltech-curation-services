#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $outfile = "WBpapers_variation_phenotype.txt";
open (OUT, ">$outfile") or die($!);

my $result = $dbh->prepare( "SELECT DISTINCT(app_paper) FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_type WHERE app_type = 'Allele')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[0]\n";
  } 
}

print "Output stored in $outfile\n";
