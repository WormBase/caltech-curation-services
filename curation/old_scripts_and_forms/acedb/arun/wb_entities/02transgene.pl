#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $outfile = "./known_entities/Transgene";
open (OUT, ">$outfile") or die($!);

print "Processing trp_name...\n";
my $result = $dbh->prepare( "SELECT DISTINCT trp_name FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  next if ($row[0] =~ /(WBPaper|pmid|cgc)/);

  if ($row[0]) { 
    print OUT "$row[0]\n";
  } 
}
close(OUT);

print "Output stored in $outfile\n";
