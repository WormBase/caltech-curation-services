#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $outfile = "protein_celegans.txt";
open (OUT, ">$outfile");

print "Processing genesequencelab...\n";
my $result = $dbh->prepare( "SELECT * FROM gin_genesequencelab" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
		my $protein_name = uc($row[0]);
		print OUT "$protein_name\n" if ( is_valid_name($protein_name) );
	}
}

print "Processing locus...\n";
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
		my $protein_name = uc($row[1]);
		print OUT "$protein_name\n" if ( is_valid_name($protein_name) );
  } 
}

print "Processing seqname...\n";
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
		my $protein_name = uc($row[1]);
		print OUT "$protein_name\n" if ( is_valid_name($protein_name) );
  } 
}

print "Processing sequence...\n";
$result = $dbh->prepare( "SELECT * FROM gin_sequence" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
		my $protein_name = uc($row[1]);
		print OUT "$protein_name\n" if ( is_valid_name($protein_name) );
  } 
}

print "Processing gin_protein...\n";
$result = $dbh->prepare( "SELECT * FROM gin_protein" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
		my $protein_name = $row[1];

		if ($protein_name =~ /^WP:CE/) {
			$protein_name =~ s/^WP://;

			print OUT "$protein_name\n";
		}
  } 
}



print "Output stored in $outfile\n";

sub is_valid_name {
	my $name = shift;
	return 0 if (! is_celegans_gene($name) );

	if ($name =~ /\./) { # this excludes coding sequences - CDS (kyook)
		return 0;
	} elsif ($name =~ /^21ur/i) {
		return 0;
	} elsif ($name =~ /^mir-/i) {
		return 0;
	}

	return 1;
}

sub is_celegans_gene {
	my $s = shift;
	if ($s =~ /^(Cbr|Cbg|Cre|Cbn|Cjp|Hpa|Oti|Ppa|Cja)/i) {
		return 0;
	}
	return 1;
}
