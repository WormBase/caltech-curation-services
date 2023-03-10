#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $outfile = "gene_celegans.txt";
open (OUT, ">$outfile");

print "Processing genesequencelab...\n";
my $result = $dbh->prepare( "SELECT * FROM gin_genesequencelab" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[0]\n" if ( is_celegans_gene($row[0]) );
  } 
}

print "Processing locus...\n";
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[1]\n" if ( is_celegans_gene($row[1]) );
  } 
}

print "Processing seqname...\n";
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print OUT "$row[1]\n" if ( is_celegans_gene($row[1]) );
  } 
}

print "Processing sequence...\n";
$result = $dbh->prepare( "SELECT * FROM gin_sequence" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
     print OUT "$row[1]\n" if ( is_celegans_gene($row[1]) );
  } 
}

print "Output stored in $outfile\n";

sub is_celegans_gene {
	my $s = shift;
	if ($s =~ /^(Cbr|Cbg|Cre|Cbn|Cjp|Hpa|Oti|Ppa|Cja)/i) {
		return 0;
	}
	return 1;
}
